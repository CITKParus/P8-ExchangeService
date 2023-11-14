/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ГАР (GAR) - обработчик импорта данных
*/

//------------------------------
// Подключаем внешние библиотеки
//------------------------------

const { workerData, parentPort } = require("worker_threads"); //Параллельные обработчики
const fs = require("fs"); //Работа с файлами
const oracledb = require("oracledb"); //Работа с СУБД Oracle
const { WRK_MSG_TYPE, logInf, logErr, makeTaskOKResult, makeTaskErrResult, makeStopMessage } = require("./utils"); //Вспомогательные функции
const { PARSERS, findModelByFileName } = require("./parsers"); //Модели и парсеры
const sax = require("./node_modules/sax"); //Событийный XML-парсер

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Название модудля для протокола
const MODULE = `GAR_INPUT_PROCESSOR_${workerData.number}`;
//Флаг подключения к БД
let CONNECTED = false;
//Флаг занятости подключения к БД
let CONNECTION_IN_USE = false;
//Подключение к БД
let CONNECTION = null;
//Флаг останова
let STOP_FLAG = false;
//Протокол выполнения
let LOAD_LOG = null;

//------------
// Тело модуля
//------------

//Подключение к БД
const connectDb = async ({ user, password, connectString, schema }) => {
    CONNECTION = await oracledb.getConnection({ user, password, connectString });
    await CONNECTION.execute(`ALTER SESSION SET CURRENT_SCHEMA=${schema} RECYCLEBIN=OFF`);
    CONNECTED = true;
};

//Отключение от БД
const disconnectDb = async () => {
    while (CONNECTION_IN_USE) {
        await new Promise(resolve => setTimeout(resolve, 0));
    }
    if (CONNECTION) {
        await CONNECTION.close();
        CONNECTION = null;
    }
    CONNECTED = false;
};

//Сохранение буфера в БД
const saveBufferToDb = async (buffer, parser, insertProcedureName, ident, region) => {
    if (!STOP_FLAG) {
        CONNECTION_IN_USE = true;
        try {
            await parser.save(CONNECTION, ident, buffer, insertProcedureName, region);
        } catch (e) {
            throw e;
        } finally {
            CONNECTION_IN_USE = false;
        }
    }
};

//Чтение файла в потоке
const parseFile = ({ fileFullName, dbBuferSize, fileChunkSize, parser, insertProcedureName, ident, region }) => {
    return new Promise((resolve, reject) => {
        //Создаём поток для файла
        const fsStream = fs.createReadStream(fileFullName, { highWaterMark: fileChunkSize });
        //Создаём поток для парсера
        const saxStream = sax.createStream(false);
        //Буфер для сброса в базу
        let buffer = [];
        //Количество разобранных элементов
        let cntItems = 0;
        //Ошибка парсера
        let parserErr = null;
        //Последний обработанный элемент
        let lastItem = null;
        //События парсера - ошибка
        saxStream.on("error", e => {
            parserErr = e.message;
        });
        //События парсера - новый элемент
        saxStream.on("opentag", node => {
            if (node.name == parser.element) {
                cntItems++;
                lastItem = node;
                buffer.push(node);
            }
        });
        //События файла - считана порция
        fsStream.on("data", chunk => {
            if (!STOP_FLAG) {
                saxStream.write(chunk);
                if (buffer.length >= dbBuferSize) {
                    fsStream.pause();
                }
                if (parserErr) fsStream.destroy();
            } else fsStream.destroy();
        });
        //События файла - пауза считывания
        fsStream.on("pause", async () => {
            if (buffer.length >= dbBuferSize) {
                try {
                    await saveBufferToDb(buffer, parser, insertProcedureName, ident, region);
                } catch (e) {
                    reject(e);
                }
                buffer = [];
            }
            if (!STOP_FLAG) fsStream.resume();
            else fsStream.destroy();
        });
        //События файла - ошибка чтения
        fsStream.on("error", error => reject(error));
        //События файла - закрылся
        fsStream.on("close", async error => {
            saxStream._parser.close();
            if (!STOP_FLAG) {
                if (buffer.length > 0) {
                    try {
                        await saveBufferToDb(buffer, parser, insertProcedureName, ident, region);
                    } catch (e) {
                        reject(e);
                    }
                    buffer = [];
                }
                if (parserErr)
                    reject(
                        Error(
                            `Ошибка разбора данных: "${parserErr}". Разобрано элементов - ${cntItems}, последний разобранный: "${JSON.stringify(
                                lastItem
                            )}"`
                        )
                    );
                else if (error) reject(error);
                else resolve();
            } else {
                reject(Error("Обработчик остановлен принудительно"));
            }
        });
    });
};

//Обработка сообщения с задачей
const processTask = async ({ garVersionInfo, fileFullName, fileName }) => {
    const model = findModelByFileName(fileName);
    if (model) {
        await parseFile({
            fileFullName,
            dbBuferSize: workerData.dbBuferSize,
            fileChunkSize: workerData.fileChunkSize,
            parser: PARSERS[model.parser],
            insertProcedureName: model.insertProcedureName,
            ident: garVersionInfo.ident,
            region: garVersionInfo.region
        });
    }
    return true;
};

//Подписка на сообщения от родительского потока
parentPort.on("message", async msg => {
    //Открываю лог выполнения
    if (!LOAD_LOG && workerData.loadLog) {
        LOAD_LOG = fs.createWriteStream(JSON.parse(workerData.loadLog).path, { flags: "a" });
        LOAD_LOG.on("error", e => {});
        LOAD_LOG.on("close", () => {});
    }
    logInf(`Обработчик #${workerData.number} получил новое сообщение: ${JSON.stringify(msg)}`, MODULE, LOAD_LOG);
    if (msg.type === WRK_MSG_TYPE.TASK) {
        try {
            //Подключение к БД
            const dbConn = workerData.dbConn;
            if (!CONNECTED)
                await connectDb({
                    user: dbConn.sUser,
                    password: dbConn.sPassword,
                    connectString: dbConn.sConnectString,
                    schema: dbConn.sSchema
                });
            let resp = await processTask({ ...msg.payload });
            parentPort.postMessage(makeTaskOKResult(resp));
        } catch (e) {
            parentPort.postMessage(makeTaskErrResult(e));
        }
    } else {
        if (msg.type === WRK_MSG_TYPE.STOP) {
            //Флаг остановки
            STOP_FLAG = true;
            //Отключимся от БД
            try {
                if (CONNECTED) await disconnectDb();
            } catch (e) {
                logErr(`При остановке обработчика: ${e.message}`, MODULE, LOAD_LOG);
            }
            //Обнулим данные для протоколирования
            if (LOAD_LOG) LOAD_LOG.destroy();
            parentPort.postMessage(makeStopMessage());
        } else {
            parentPort.postMessage(makeTaskErrResult(Error(`Обработчик #${workerData.number} получил сообщение неподдерживаемого типа`)));
        }
    }
});

//Отлов неожиданных ошибок
process.on("uncaughtException", e => {
    logErr(`Неожиданная ошибка: ${e.message}`, MODULE, LOAD_LOG);
    //Обнулим данные для протоколирования
    if (LOAD_LOG) LOAD_LOG.destroy();
});

//Отлов неожиданных прерываний
process.on("unhandledRejection", e => {
    logErr(`Неожиданное прерывание: ${e.message}`, MODULE, LOAD_LOG);
    //Обнулим данные для протоколирования
    if (LOAD_LOG) LOAD_LOG.destroy();
});
