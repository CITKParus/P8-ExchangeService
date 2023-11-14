/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ГАР (GAR)
*/

//------------------------------
// Подключаем внешние библиотеки
//------------------------------

const fs = require("fs"); //Работа с файлами
const { pipeline } = require("stream"); //Работа с потоками
const { promisify } = require("util"); //Вспомогательные инструменты
const xml2js = require("xml2js"); //Конвертация XML в JSON и JSON в XML
const confServ = require("../config"); //Настройки сервера приложений
const conf = require("./gar_config"); //Параметры расширения "Интеграция с ГАР"
const StreamZip = require("./gar_utils/node_modules/node-stream-zip"); //Работа с ZIP-архивами
const fetch = require("./gar_utils/node_modules/node-fetch"); //Работа с запросами
const { WorkersPool } = require("./gar_utils/workers_pool"); //Пул обработчиков
const { logInf, makeTaskMessage, logWrn, logErr, stringToDate, dateToISOString } = require("./gar_utils/utils"); //Вспомогательные функции

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Название модудля для протокола
const MODULE = `GAR`;
//Параметры пула обработчиков
const workersPoolOptions = {
    workerPath: "./modules/gar_utils/import.js",
    limit: conf.common.nThreads,
    timeout: 0,
    drainTimeout: 60000
};
//Пул обработчиков
let WP = null;
//Очередь на парсинг
let PARSE_QUEUE = [];
//Обрабатываемые элементы архива
let ENTRIES = [];
//Всего элементов в архиве
let ENTRIES_COUNT = 0;
//Всего файлов в архиве
let FILES_COUNT = 0;
//Общий объем файлов в архиве
let TOTAL_SIZE = 0;
//Объем успешно обработанных файлов
let PROCESSED_SIZE = 0;
//Количество успешно обработанных файлов
let PROCESSED_COUNT = 0;
//Объем файлов обработанных с ошибками
let ERROR_SIZE = 0;
//Количество файлов обработанных с ошибками
let ERROR_COUNT = 0;
//Начало
let START_TIME = null;
//Окончание
let END_TIME = null;
//Протокол выполнения
let LOAD_LOG = null;
//Флаг распакованности архива
let ZIP_UNPACKED = false;

//------------
// Тело модуля
//------------

//Выдача общей статистики
const printCommonStats = () => {
    logWrn(`Всего элементов: ${ENTRIES_COUNT}, файлов для обработки: ${FILES_COUNT}`, MODULE, LOAD_LOG);
    logWrn(`Объем файлов для обработки: ${TOTAL_SIZE} байт`, MODULE, LOAD_LOG);
};

//Выдача статистики импорта
const printImportStats = () => {
    logWrn(`Количество необработанных файлов: ${FILES_COUNT - ERROR_COUNT - PROCESSED_COUNT}`, MODULE, LOAD_LOG);
    logWrn(`Объем необработанных файлов: ${TOTAL_SIZE - ERROR_SIZE - PROCESSED_SIZE} байт`, MODULE, LOAD_LOG);
    logWrn(`Количество файлов обработанных с ошибками: ${ERROR_COUNT}`, MODULE, LOAD_LOG);
    logWrn(`Объем файлов обработанных с ошибками: ${ERROR_SIZE} байт`, MODULE, LOAD_LOG);
    logWrn(`Количество файлов успешно обработанных: ${PROCESSED_COUNT}`, MODULE, LOAD_LOG);
    logWrn(`Объем файлов успешно обработанных: ${PROCESSED_SIZE} байт`, MODULE, LOAD_LOG);
    logWrn(`Начало: ${START_TIME}`, MODULE, LOAD_LOG);
    logWrn(`Окончание: ${END_TIME}`, MODULE, LOAD_LOG);
    logWrn(`Длительность: ${(END_TIME.getTime() - START_TIME.getTime()) / 1000} секунд`, MODULE, LOAD_LOG);
};

//Подчистка временного файла
const removeTempFile = fileFullName => {
    logInf(`Удаляю временный "${fileFullName}"...`, MODULE, LOAD_LOG);
    fs.rm(fileFullName, { maxRetries: 5, retryDelay: 1000 }, err => {
        if (err) logErr(`Ошибка удаления временного файла "${fileFullName}": ${err.message}`, MODULE, LOAD_LOG);
        else logInf(`Удалено "${fileFullName}".`, MODULE, LOAD_LOG);
    });
};

//Проверка необходимости загрузки элемента
const needLoad = ({ processedCount, entry, processLimit, processFilter }) =>
    (processLimit === 0 || processedCount <= processLimit) &&
    !entry.isDirectory &&
    entry.name.toLowerCase().endsWith("xml") &&
    (processFilter === null || (processFilter != null && entry.name.match(processFilter)));

//Обработка очереди на распаковку
const processParseQueue = async () => {
    //Если в очереди еще есть необработанные элементы
    if (PARSE_QUEUE.length > 0) {
        //Получим данные элемента очереди
        const { entry, fileFullName, fileName, garVersionInfo } = PARSE_QUEUE.shift();
        //Если обработчик запущен
        if (WP.started) {
            //Отправим задачу на выполнение
            try {
                await WP.sendTask(makeTaskMessage({ payload: { garVersionInfo, fileFullName, fileName } }), (e, p) => {
                    //Удалим временный файл
                    removeTempFile(fileFullName);
                    //Если ошибка
                    if (e) {
                        //Размер файлов, обработанных с ошибками
                        ERROR_SIZE += entry.size;
                        //Количество ошибок
                        ERROR_COUNT++;
                        //Сообщение об ошибке
                        let msg = `При обработке "${entry.name}": ${e.message}`;
                        logErr(msg, MODULE, LOAD_LOG);
                    } else {
                        //Размер успешно обработанных файлов
                        PROCESSED_SIZE += entry.size;
                        //Количество успешно обработанных файлов
                        PROCESSED_COUNT++;
                        logWrn(`Обработано успешно "${entry.name}".`, MODULE, LOAD_LOG);
                    }
                    logWrn(
                        `Всего обработано: ${PROCESSED_SIZE + ERROR_SIZE} байт, ${Math.round(((PROCESSED_SIZE + ERROR_SIZE) / TOTAL_SIZE) * 100)}%`,
                        MODULE,
                        LOAD_LOG
                    );
                });
            } catch (e) {
                //Удалим временный файл
                logErr(`При размещении задачи для "${entry.name}": ${e.message}`, MODULE, LOAD_LOG);
                removeTempFile(fileFullName);
            }
        } else {
            //Пул фоновых обработчиков остановлен (могла прийти команда принудительного выключения)
            logErr(`При размещении задачи для "${entry.name}": пул уже остановлен. Прекращаю работу.`, MODULE, LOAD_LOG);
            removeTempFile(fileFullName);
        }
    }
    if (PARSE_QUEUE.length > 0 || !ZIP_UNPACKED) setTimeout(processParseQueue, 0);
};

//Конвертация в XML
const toXML = obj => {
    const builder = new xml2js.Builder();
    return builder.buildObject(obj);
};

//Обработчик после получения обновлений ГАР
const afterLoad = async prms => {
    if (!conf.common.sDownloadsDir) throw new Error(`Не указан путь для размещения загруженных файлов.`);
    if (!conf.common.sTmpDir) throw new Error(`Не указан путь для размещения временных файлов.`);
    if (!conf.common.sLogDir) throw new Error(`Не указан путь для размещения файлов протоколирования.`);
    //Информация о загружаемых данных
    const LOAD_INFO = {
        REGIONS: prms.options.sRegions,
        GARDATELAST: stringToDate(prms.options.dGarDateLast),
        HOUSESLOADED: Number(prms.options.nHousesLoaded),
        STEADSLOADED: Number(prms.options.nSteadsLoaded)
    };
    //Если указаны загружаемые регионы и дата последней загруженной версии ГАР
    if (LOAD_INFO.REGIONS && LOAD_INFO.GARDATELAST) {
        //Идентификаторы загружаемых процессов
        let loadIdents = [];
        //Идентификатор протоколирования
        const logIdent = Date.now();
        //Открываю лог выполнения
        LOAD_LOG = fs.createWriteStream(`${conf.common.sLogDir}/gar_load_${logIdent}.log`);
        LOAD_LOG.on("error", e => {});
        LOAD_LOG.on("close", () => {});
        logInf("Протокол выполнения загрузки ГАР открыт.", MODULE, LOAD_LOG);
        //Информация о версиях ГАР
        const requestRespJson = JSON.parse(prms.queue.blResp.toString());
        //Обработаем полученную информацию о версиях ГАР
        logInf(`Обрабатываю полученую информацию о версиях ГАР...`, MODULE, LOAD_LOG);
        //Версии ГАР для загрузки
        let garVersions = [];
        //Регионы
        const regions = LOAD_INFO.REGIONS.split(";");
        //Последняя загруженная версия ГАР
        const garDateLast = LOAD_INFO.GARDATELAST;
        //Признак загрузки домов
        const housesLoaded = LOAD_INFO.HOUSESLOADED ? LOAD_INFO.HOUSESLOADED : 0;
        //Признак загрузки участков
        const steadsLoaded = LOAD_INFO.STEADSLOADED ? LOAD_INFO.STEADSLOADED : 0;
        //Если не указана последняя загруженная версия ГАР
        if (!garDateLast) throw new Error(`Не указана последняя загруженная версия ГАР, обновление недоступно.`);
        //Обойдем элементы ответа
        for (let respElement of requestRespJson) {
            //Дата версии ГАР
            const garVersionDate = stringToDate(respElement.Date);
            //Ссылка на данные обновления
            const garXmlDeltaUrl = respElement.GarXMLDeltaURL;
            //Если указана дата и ссылка на обновление
            if (garVersionDate && garXmlDeltaUrl) {
                //Если версия вышла позже последней загруженной
                if (garDateLast < garVersionDate) {
                    //Сохраним версию ГАР
                    garVersions.push({
                        versionDate: dateToISOString(garVersionDate),
                        xmlDeltaUrl: garXmlDeltaUrl
                    });
                }
            } else {
                throw new Error(`Не удалось корректно определить информацию о версиях ГАР.`);
            }
        }
        logInf(`Полученая информация о версиях ГАР обработана.`, MODULE, LOAD_LOG);
        //Если не указаны необходимые для загрузки версии ГАР
        if (!garVersions || garVersions.length == 0)
            throw new Error(
                `Не удалось определить необходимые для загрузки версии ГАР, вышедшие после ${garDateLast.toISOString().substring(0, 10)}.`
            );
        //Обработаем версии ГАР
        logInf(`Обрабатываю версии ГАР...`, MODULE, LOAD_LOG);
        //Отсортируем версии ГАР по возрастанию
        garVersions.sort((a, b) => {
            if (a.versionDate > b.versionDate) return 1;
            if (a.versionDate === b.versionDate) return 0;
            if (a.versionDate < b.versionDate) return -1;
        });
        //Пул обработчиков
        WP = new WorkersPool(workersPoolOptions);
        //Запуск фоновых процессов
        logInf(`Стартую обработчики...`, MODULE, LOAD_LOG);
        await WP.start({
            dbBuferSize: conf.dbConnect.nBufferSize,
            fileChunkSize: conf.common.nFileChunkSize,
            loadLog: LOAD_LOG,
            dbConn: {
                sUser: confServ.dbConnect.sUser,
                sPassword: confServ.dbConnect.sPassword,
                sConnectString: confServ.dbConnect.sConnectString,
                sSchema: confServ.dbConnect.sSchema
            }
        });
        logInf(`Обработчики запущены.`, MODULE, LOAD_LOG);
        //Обрабатываемая версия ГАР
        let garVersion = garVersions[0];
        // Обработаем версию ГАР
        logInf(`Обрабатываю версию ГАР "${garVersion.versionDate}"...`, MODULE, LOAD_LOG);
        //Флаг необходимости загрузки файла
        let downloadFlag = true;
        //Полный путь к загрузке (временная переменная)
        let fileFullNameTmp = `${conf.common.sDownloadsDir}/${garVersion.versionDate}.zip`;
        //Если файл был загружен ранее
        if (fs.existsSync(fileFullNameTmp)) {
            logInf(`Файл "${fileFullNameTmp}" уже существует.`, MODULE, LOAD_LOG);
            //Если разрешено использование существующего файла
            if (conf.common.bDownloadsUseExists) downloadFlag = false;
            else fileFullNameTmp = `${conf.common.sDownloadsDir}/${garVersion.versionDate}_${logIdent}.zip`;
        }
        //Полный путь к загрузке
        const fileFullName = fileFullNameTmp;
        //Если необходимо загрузить файл
        if (downloadFlag) {
            //Загружаем файл
            try {
                logInf(`Загружаю файл по ссылке "${garVersion.xmlDeltaUrl}" в каталог "${conf.common.sDownloadsDir}"...`, MODULE, LOAD_LOG);
                const streamPipeline = promisify(pipeline);
                const fileData = await fetch(garVersion.xmlDeltaUrl, { redirect: "follow", follow: 20 });
                if (!fileData.ok) throw new Error(`Не удалось загрузить файл по ссылке "${garVersion.xmlDeltaUrl}": ${fileData.statusText}.`);
                await streamPipeline(fileData.body, fs.createWriteStream(fileFullName));
                logInf(`Файл "${fileFullName}" загружен.`, MODULE, LOAD_LOG);
            } catch (e) {
                const errorMessage = `Ошибка загрузки файла по ссылке "${garVersion.xmlDeltaUrl}": ${e.message}.`;
                logErr(errorMessage, MODULE, LOAD_LOG);
                throw new Error(errorMessage);
            }
        }
        //Обнулим переменные
        ENTRIES = [];
        TOTAL_SIZE = 0;
        FILES_COUNT = 0;
        PARSE_QUEUE = [];
        ENTRIES_COUNT = 0;
        PROCESSED_SIZE = 0;
        PROCESSED_COUNT = 0;
        ERROR_SIZE = 0;
        ERROR_COUNT = 0;
        START_TIME = null;
        END_TIME = null;
        ZIP_UNPACKED = false;
        //Анализ архива
        logInf(`Читаю архив...`, MODULE, LOAD_LOG);
        const zip = new StreamZip.async({ file: fileFullName });
        const entries = await zip.entries();
        //Обойдем файлы архива
        for (const entry of Object.values(entries)) {
            //Количество файлов архива
            ENTRIES_COUNT++;
            //Путь к фалу в архиве
            const path = entry.name.split("/");
            //Если подходящий путь к файлу
            if ([1, 2].includes(path.length)) {
                //Регион
                const region = path.length == 2 ? path[0] : "";
                //Если указан регион и он входит в состав регионов, которые необходимо загрузить и файл попадает под условия загрузки
                if (
                    (!region || !regions || (region && regions && regions.includes(region))) &&
                    needLoad({
                        processedCount: FILES_COUNT,
                        entry,
                        processLimit: conf.common.nLoadFilesLimit,
                        processFilter: conf.common.sLoadFilesMask
                    }) &&
                    (housesLoaded == 1 || ((!housesLoaded || housesLoaded != 1) && !path[path.length - 1].startsWith(`AS_HOUSES`))) &&
                    (steadsLoaded == 1 || ((!steadsLoaded || steadsLoaded != 1) && !path[path.length - 1].startsWith(`AS_STEADS`)))
                ) {
                    //Количество, подошедших под условия загрузки, файлов
                    FILES_COUNT++;
                    //Общий размер файлов, подошедших под условия загрузки
                    TOTAL_SIZE += entry.size;
                    //Запомним файл
                    ENTRIES.push(entry);
                }
            }
        }
        //Отсортируем файлы в порядке возрастания по размеру файла
        ENTRIES.sort((a, b) => (a.size > b.size ? 1 : a.size < b.size ? -1 : 0));
        printCommonStats();
        logInf(`Архив прочитан.`, MODULE, LOAD_LOG);
        //Обработка очереди на парсинг
        setTimeout(processParseQueue, 0);
        //Время начала обработки архива
        START_TIME = new Date();
        //Идентификатор процесса
        const ident = Date.now();
        //Директория для размещения временных файлов архива
        const garVersionDir = `${conf.common.sTmpDir}/${garVersion.versionDate}`;
        //Если не существует директории для размещения временных файлов
        if (!fs.existsSync(garVersionDir)) {
            //Создадим директорию
            try {
                fs.mkdirSync(garVersionDir);
            } catch (e) {
                throw new Error(`Не удалось создать директорию "${garVersionDir}": ${e.message}`);
            }
        }
        //Обойдем файлы архива
        for (const entry of ENTRIES) {
            //Путь к файлу архива
            const path = entry.name.split("/");
            //Имя файла
            const unzipFileName = path[path.length - 1];
            //Регион
            const region = path.length == 2 ? path[0] : "";
            //Полный путь к файлу
            const unzipFileFullName = `${garVersionDir}/${region ? `${region}/` : ""}${unzipFileName}`;
            //Если указан регион
            if (region)
                if (!fs.existsSync(`${garVersionDir}/${region}`))
                    //Если еще не существует диретории для региона
                    //Создадим директорию для региона
                    try {
                        fs.mkdirSync(`${garVersionDir}/${region}`);
                    } catch (e) {
                        throw new Error(`Не удалось создать директорию "${garVersionDir}/${region}": ${e.message}`);
                    }
            //Если файл еще не существует
            if (!fs.existsSync(unzipFileFullName)) {
                //Распакуем файл
                logInf(`Распаковываю "${entry.name}" (${entry.size} байт) в "${unzipFileFullName}"...`, MODULE, LOAD_LOG);
                await zip.extract(entry.name, unzipFileFullName);
                logInf(`Распаковано "${entry.name}" в "${unzipFileFullName}".`, MODULE, LOAD_LOG);
            } else {
                logInf(`Файл "${entry.name}" уже распакован в директорию "${garVersionDir}".`, MODULE, LOAD_LOG);
            }
            //Отдаём его в обработку фоновому процессу
            PARSE_QUEUE.push({
                entry,
                fileName: unzipFileName,
                fileFullName: unzipFileFullName,
                garVersionInfo: {
                    ident,
                    region,
                    versionDate: garVersion.versionDate
                }
            });
        }
        //Закрываем архив
        logInf("Закрываю архив...", MODULE, LOAD_LOG);
        await zip.close();
        logInf("Архив закрыт.", MODULE, LOAD_LOG);
        //Флаг закрытия архива
        ZIP_UNPACKED = true;
        //Ожидаем, пока всё отработает
        logInf("Жду завершения фоновой обработки...", MODULE, LOAD_LOG);
        while (PARSE_QUEUE.length > 0 || WP.available != conf.common.nThreads) await new Promise(resolve => setTimeout(resolve, 1000));
        logInf("Фоновая обработка завершена.", MODULE, LOAD_LOG);
        //Очистка директорий для размещения временных файлов
        logInf(`Очищаю директорию "${garVersionDir}" для размещения временных файлов...`, MODULE, LOAD_LOG);
        fs.rmSync(garVersionDir, { recursive: true });
        logInf(`Каталог "${garVersionDir}" для размещения временных файлов очищена.`, MODULE, LOAD_LOG);
        //Если необходимо удалить загруженные файлы
        if (conf.common.bDownloadsDelete) {
            logInf(`Удаляю загруженный файл "${fileFullName}"...`, MODULE, LOAD_LOG);
            fs.unlinkSync(fileFullName);
            logInf(`Загруженный файл "${fileFullName}" удален.`, MODULE, LOAD_LOG);
        }
        //Время завершения выполнения загрузки
        END_TIME = new Date();
        printCommonStats();
        printImportStats();
        //Если обработка прошла успешно
        if (ERROR_COUNT == 0) {
            //Запомним обработанную версию
            loadIdents.push({
                GAR_VERSION: {
                    IDENT: ident,
                    VERSION_DATE: garVersion.versionDate,
                    REGIONS: LOAD_INFO.REGIONS,
                    HOUSES_LOADED: housesLoaded,
                    STEADS_LOADED: steadsLoaded
                }
            });
            logInf(`Версия ГАР "${garVersion.versionDate}" обработана.`, MODULE, LOAD_LOG);
        } else {
            loadIdents = null;
            logErr(`Версия ГАР "${garVersion.versionDate}" обработана с ошибками.`, MODULE, LOAD_LOG);
        }
        //Выключаю пул обработчиков
        logInf("Останавливаю обработчики...", MODULE, LOAD_LOG);
        await WP.stop(LOAD_LOG);
        WP = null;
        logInf("Обработчики остановлены.", MODULE, LOAD_LOG);
        logInf(`Версии ГАР обработаны.`, MODULE, LOAD_LOG);
        //Закрываю протокол выполнения
        logInf("Закрываю протокол выполнения загрузки ГАР...", MODULE, LOAD_LOG);
        if (LOAD_LOG) LOAD_LOG.destroy();
        if (!loadIdents) throw new Error(`Не удалось загрузить данные обновления ГАР.`);
        //Вернем результат
        return { blResp: Buffer.from(toXML(loadIdents[0])) };
    } else {
        throw new Error(`Не указан регион и/или дата для загрузки обновлений ГАР.`);
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.afterLoad = afterLoad;
