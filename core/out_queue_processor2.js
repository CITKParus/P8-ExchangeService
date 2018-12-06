/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: обработчик исходящего сообщения
*/

//----------------------
// Подключение библиотек
//----------------------

require("module-alias/register"); //Поддержка псевонимов при подключении модулей
const _ = require("lodash"); //Работа с массивами и коллекциями
const lg = require("./logger"); //Протоколирование работы
const db = require("./db_connector"); //Взаимодействие с БД
const { makeModuleFullPath, validateObject } = require("./utils"); //Вспомогательные функции
const { ServerError } = require("./server_errors"); //Типовая ошибка
const objOutQueueProcessorSchema = require("../models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const prmsOutQueueProcessorSchema = require("../models/prms_out_queue_processor"); //Схема валидации параметров функций модуля
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const {
    SERR_UNEXPECTED,
    SERR_MODULES_BAD_INTERFACE,
    SERR_OBJECT_BAD_INTERFACE,
    SERR_MODULES_NO_MODULE_SPECIFIED
} = require("./constants"); //Глобальные константы
const { NINC_EXEC_CNT_YES, NINC_EXEC_CNT_NO } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД

//----------
// Константы
//----------

//--------------------------
// Глобальные идентификаторы
//--------------------------

let dbConn = null; //Подключение к БД
let logger = null; //Протоколирование работы

//------------
// Тело модуля
//------------

//Отправка родительскому процессу ошибки обработки сообщения сервером приложений
const sendErrorResult = sMessage => {
    process.send({
        sExecResult: "ERR",
        sExecMsg: sMessage
    });
};

//Отправка родительскому процессу успеха обработки сообщения сервером приложений
const sendOKResult = () => {
    process.send({
        sExecResult: "OK",
        sExecMsg: null
    });
};

//Запись в файл !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! УБРАТЬ!!!!!!!!!!!!!!!!!
const writeToFile = queue => {
    return new Promise((resolve, reject) => {
        const fs = require("fs");
        fs.writeFile("c:/repos/temp/" + queue.nId, queue.blMsg, err => {
            if (err) {
                reject(new ServerError(SERR_UNEXPECTED, `Ошибка отработки сообщения ${prms.queue.nId}`));
            } else {
                resolve();
            }
        });
    });
};

//Запуск обработки сообщения сервером приложений
const appProcess = async prms => {
    //Обработанное сообщение
    let newQueue = null;
    //Обрабатываем
    try {
        //Фиксируем начало исполнения сервером приложений - в статусе сообщения
        newQueue = await dbConn.setQueueState({
            nQueueId: prms.queue.nId,
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP
        });
        //Скажем что начали обработку
        await logger.info(
            `Обрабатываю исходящее сообщение сервером приложений: ${prms.queue.nId}, ${prms.queue.sInDate}, ${
                prms.queue.sServiceFnCode
            }, ${prms.queue.sExecState}, попытка исполнения - ${prms.queue.nExecCnt + 1}`,
            { nQueueId: prms.queue.nId }
        );
        if (prms.queue.blMsg) {
            await writeToFile(prms.queue);
            let sMsg = prms.queue.blMsg.toString() + " MODIFICATION FOR " + prms.queue.nId;
            //Фиксируем успех исполнения
            newQueue = await dbConn.setQueueAppSrvResult({
                nQueueId: prms.queue.nId,
                blMsg: new Buffer(sMsg),
                blResp: new Buffer("REPLAY ON " + prms.queue.nId)
            });
            //Фиксируем успешное исполнение сервером приложений - в статусе сообщения
            newQueue = await dbConn.setQueueState({
                nQueueId: prms.queue.nId,
                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_OK
            });
            //Фиксируем успешное исполнение сервером приложений - в протоколе работы сервиса
            await logger.info(`Исходящее сообщение ${prms.queue.nId} успешно отработано сервером приложений`, {
                nQueueId: prms.queue.nId
            });
        } else {
            throw new ServerError(
                SERR_UNEXPECTED,
                `Ошибка отработки сообщения ${prms.queue.nId}: нет данных для обработки`
            );
        }
    } catch (e) {
        //Сформируем текст ошибки
        let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
        if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
        //Фиксируем ошибку обработки сервером приложений - в статусе сообщения
        newQueue = await dbConn.setQueueState({
            nQueueId: prms.queue.nId,
            sExecMsg: sErr,
            nIncExecCnt: NINC_EXEC_CNT_YES,
            nExecState:
                prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                    ? objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                    : objQueueSchema.NQUEUE_EXEC_STATE_ERR
        });
        //Фиксируем ошибку обработки сервером приложений - в протоколе работы сервиса
        await logger.error(`Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером приложений: ${sErr}`, {
            nQueueId: prms.queue.nId
        });
    }
    //Возвращаем результат
    return newQueue;
};

//Запуск обработки сообщения сервером БД
const dbProcess = async prms => {
    //Проверяем структуру переданного объекта для старта
    //let sCheckResult = validateObject(
    //    prms,
    //    prmsOutQueueSchema.dbProcess,
    //    "Параметры функции запуска обработки ообщения сервером БД"
    //);
    //Если структура объекта в норме
    //if (!sCheckResult) {
    //Обрабатываем
    try {
        //Фиксируем начало исполнения сервером БД - в статусе сообщения
        await dbConn.setQueueState({
            nQueueId: prms.queue.nId,
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB
        });
        //Скажем что начали обработку
        await logger.info(
            `Обрабатываю исходящее сообщение сервером БД: ${prms.queue.nId}, ${prms.queue.sInDate}, ${
                prms.queue.sServiceFnCode
            }, ${prms.queue.sExecState}, попытка исполнения - ${prms.queue.nExecCnt + 1}`,
            { nQueueId: prms.queue.nId }
        );
        //Вызов обработчика БД
        await dbConn.execQueueDBPrc({ nQueueId: prms.queue.nId });
        //Фиксируем успешное исполнение сервером БД - в статусе сообщения
        await dbConn.setQueueState({
            nQueueId: prms.queue.nId,
            nIncExecCnt: prms.queue.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_OK
        });
        //Фиксируем успешное исполнение сервером БД - в протоколе работы сервиса
        await logger.info(`Исходящее сообщение ${prms.queue.nId} успешно отработано сервером БД`, {
            nQueueId: prms.queue.nId
        });
    } catch (e) {
        //Сформируем текст ошибки
        let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
        if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
        //Фиксируем ошибку обработки сервером БД - в статусе сообщения
        await dbConn.setQueueState({
            nQueueId: prms.queue.nId,
            sExecMsg: sErr,
            nIncExecCnt: NINC_EXEC_CNT_YES,
            nExecState:
                prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                    ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                    : objQueueSchema.NQUEUE_EXEC_STATE_ERR
        });
        //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
        await logger.error(`Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером БД: ${sErr}`, {
            nQueueId: prms.queue.nId
        });
    }
    //} else {
    //    throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    //}
};

//Протоколирование предупреждения о ненадлежащем статусе сообщения
const warnBadStateForProcess = async prms => {
    //Предупредим о неверном статусе сообщения (такие сюда попадать не должны)
    await logger.warn(`Cообщение ${prms.queue.nId} в статусе ${prms.queue.sExecState} попало в очередь обработчика`, {
        nQueueId: prms.queue.nId
    });
};

//Обработка задачи
const processTask = async prms => {
    //Проверяем параметры
    /*
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.processTask,
        "Параметры функции обработки задачи"
    );
    */
    //Если параметры в норме
    //if (!sCheckResult) {
    let q = null;
    try {
        //Создаём подключение к БД
        dbConn = new db.DBConnector({ connectSettings: prms.task.connectSettings });
        //Создаём логгер для протоколирования работы
        logger = new lg.Logger();
        //Подключим логгер к БД (и отключим когда надо)
        dbConn.on(db.SEVT_DB_CONNECTOR_CONNECTED, connection => {
            logger.setDBConnector(dbConn, true);
        });
        dbConn.on(db.SEVT_DB_CONNECTOR_DISCONNECTED, () => {
            logger.removeDBConnector();
        });
        //Подключаемся к БД
        await dbConn.connect();
        //Считываем запись очереди
        q = await dbConn.getQueue({ nQueueId: prms.task.nQueueId });
        //Далее работаем от статуса считанной записи
        switch (q.nExecState) {
            //Поставлено в очередь
            case objQueueSchema.NQUEUE_EXEC_STATE_INQUEUE: {
                //Запускаем обработку сервером приложений
                let res = await appProcess({ queue: q });
                //И если она успешно завершилась - обработку сервоером БД
                if (res.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_OK) await dbProcess({ queue: res });
                break;
            }
            //Обрабатывается сервером приложений
            case objQueueSchema.NQUEUE_EXEC_STATE_APP: {
                //Ничего не делаем, но предупредим что так быть не должно
                await warnBadStateForProcess({ queue: q });
                break;
            }
            //Ошибка обработки сервером приложений
            case objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR: {
                //Если ещё есть попытки отработки
                if (q.nExecCnt < q.nRetryAttempts) {
                    //Снова запускаем обработку сервером приложений
                    let res = await appProcess({ queue: q });
                    //И если она успешно завершилась - обработку сервоером БД
                    if (res.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_OK) await dbProcess({ queue: res });
                } else {
                    //Попыток нет - финализируем обработку
                    await dbConn.setQueueState({
                        nQueueId: q.nId,
                        sExecMsg: q.sExecMsg,
                        nIncExecCnt: q.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                    });
                }
                break;
            }
            //Успешно обработано сервером приложений
            case objQueueSchema.NQUEUE_EXEC_STATE_APP_OK: {
                //Запускаем обработку в БД
                await dbProcess({ queue: q });
                break;
            }
            //Обрабатывается в БД
            case objQueueSchema.NQUEUE_EXEC_STATE_DB: {
                //Ничего не делаем, но предупредим что так быть не должно
                await warnBadStateForProcess({ queue: q });
                break;
            }
            //Ошибка обработки в БД
            case objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR: {
                //Если ещё есть попытки отработки
                if (q.nExecCnt < q.nRetryAttempts) {
                    //Снова запускаем обработку сервером БД
                    await dbProcess({ queue: q });
                } else {
                    //Попыток нет - финализируем обработку
                    await dbConn.setQueueState({
                        nQueueId: q.nId,
                        sExecMsg: q.sExecMsg,
                        nIncExecCnt: q.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                    });
                }
                break;
            }
            //Успешно обработано в БД
            case objQueueSchema.NQUEUE_EXEC_STATE_DB_OK: {
                //Финализируем
                await dbConn.setQueueState({
                    nQueueId: q.nId,
                    sExecMsg: null,
                    nIncExecCnt: q.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_OK
                });
                break;
            }
            //Обработано с ошибками
            case objQueueSchema.NQUEUE_EXEC_STATE_ERR: {
                //Ничего не делаем, но предупредим что так быть не должно
                await warnBadStateForProcess({ queue: q });
                break;
            }
            //Обработано успешно
            case objQueueSchema.NQUEUE_EXEC_STATE_OK: {
                //Ничего не делаем, но предупредим что так быть не должно
                await warnBadStateForProcess({ queue: q });
                break;
            }
            default: {
                //Ничего не делаем
                break;
            }
        }
        //Отключаемся от БД
        if (dbConn) await dbConn.disconnect();
        //Отправляем успех
        sendOKResult();
    } catch (e) {
        //Отключаемся от БД
        if (dbConn) await dbConn.disconnect();
        //Отправляем ошибку
        let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
        if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
        sendErrorResult(sErr);
    }
    //Отправим родителю информацию о том, что закончили обработку

    //} else {
    //    sendErrorResult({ sMessage: sCheckResult });
    //}
};

//---------------------------------
// Управление процессом обработчика
//---------------------------------

//Перехват CTRL + C (останов процесса)
process.on("SIGINT", () => {});

//Перехват CTRL + \ (останов процесса)
process.on("SIGQUIT", () => {});

//Перехват мягкого останова процесса
process.on("SIGTERM", () => {});

//Перехват ошибок
process.on("uncaughtException", e => {
    //Отправляем ошибку родительскому процессу
    sendErrorResult(e.message);
});

//Приём сообщений
process.on("message", task => {
    //Проверяем структуру переданного сообщения
    /*
    let sCheckResult = validateObject(
        task,
        objOutQueueProcessorSchema.OutQueueProcessorTask,
        "Задача обработчика очереди исходящих сообщений"
    );
    */
    //Если структура объекта в норме
    //if (!sCheckResult) {
    //Запускаем обработку
    processTask({ task });
    //} else {
    //    throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    //}
});
