/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: обработчик исходящего сообщения
*/

//----------------------
// Подключение библиотек
//----------------------

require("module-alias/register"); //Поддержка псевонимов при подключении модулей
const _ = require("lodash"); //Работа с массивами и объектами
const rqp = require("request-promise"); //Работа с HTTP/HTTPS запросами
const lg = require("./logger"); //Протоколирование работы
const db = require("./db_connector"); //Взаимодействие с БД
const { makeErrorText, validateObject, getAppSrvFunction, buildURL } = require("./utils"); //Вспомогательные функции
const { ServerError } = require("./server_errors"); //Типовая ошибка
const objOutQueueProcessorSchema = require("../models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const prmsOutQueueProcessorSchema = require("../models/prms_out_queue_processor"); //Схема валидации параметров функций модуля
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const objServiceFnSchema = require("../models/obj_service_function"); //Схемы валидации функции сервиса
const { SERR_OBJECT_BAD_INTERFACE, SERR_APP_SERVER_BEFORE, SERR_APP_SERVER_AFTER } = require("./constants"); //Глобальные константы
const { NINC_EXEC_CNT_YES, NINC_EXEC_CNT_NO } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД

//--------------------------
// Глобальные идентификаторы
//--------------------------

let dbConn = null; //Подключение к БД
let logger = null; //Протоколирование работы

//------------
// Тело модуля
//------------

//Отправка родительскому процессу ошибки обработки сообщения сервером приложений
const sendErrorResult = prms => {
    //Проверяем структуру переданного сообщения
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.sendErrorResult,
        "Параметры функции отправки родительскому процессу ошибки обработки сообщения"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        process.send({
            sResult: objOutQueueProcessorSchema.STASK_RESULT_ERR,
            sMsg: prms.sMessage,
            context: null
        });
    } else {
        process.send({
            sResult: objOutQueueProcessorSchema.STASK_RESULT_ERR,
            sMsg: sCheckResult,
            context: null
        });
    }
};

//Отправка родительскому процессу успеха обработки сообщения сервером приложений
const sendOKResult = prms => {
    //Проверяем структуру переданного сообщения
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.sendOKResult,
        "Параметры функции отправки родительскому процессу успеха обработки сообщения"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        process.send({
            sResult: objOutQueueProcessorSchema.STASK_RESULT_OK,
            sMsg: null,
            context: prms.context
        });
    } else {
        sendErrorResult({ sMessage: sCheckResult });
    }
};

//Запуск обработки сообщения сервером приложений
const appProcess = async prms => {
    //Проверяем структуру переданного объекта для старта
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.appProcess,
        "Параметры функции запуска обработки ообщения сервером приложений"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
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
            //Считаем тело сообщения
            let qData = await dbConn.getQueueMsg({ nQueueId: prms.queue.nId });
            //Кладём данные тела в объект сообщения и инициализируем поле для ответа
            _.extend(prms.queue, { blMsg: qData.blMsg, blResp: null });
            //Собираем параметры для передачи серверу
            let options = { method: prms.service.sFnPrmsType };
            //Определимся с URL и телом сообщения в зависимости от способа передачи параметров
            if (prms.service.sFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST) {
                options.url = buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL });
                options.body = prms.queue.blMsg;
            } else {
                options.url = buildURL({
                    sSrvRoot: prms.service.sSrvRoot,
                    sFnURL: prms.function.sFnURL,
                    sQuery: prms.queue.blMsg.toString()
                });
            }
            //Выполняем обработчик "До" (если он есть)
            if (prms.function.sAppSrvBefore) {
                const fnBefore = getAppSrvFunction(prms.function.sAppSrvBefore);
                let resBefore = null;
                try {
                    let resBeforePrms = _.cloneDeep(prms);
                    resBefore = await fnBefore(resBeforePrms);
                } catch (e) {
                    throw new ServerError(SERR_APP_SERVER_BEFORE, e.message);
                }
                //Проверяем структуру ответа функции предобработки
                if (resBefore) {
                    let sCheckResult = validateObject(
                        resBefore,
                        objOutQueueProcessorSchema.OutQueueProcessorFnBefore,
                        "Результат функции предобработки исходящего сообщения"
                    );
                    //Если структура ответа в норме
                    if (!sCheckResult) {
                        //Применим её
                        if (!_.isUndefined(resBefore.options)) options = _.cloneDeep(resBefore.options);
                        if (!_.isUndefined(resBefore.blMsg)) {
                            prms.queue.blMsg = resBefore.blMsg;
                            await dbConn.setQueueMsg({
                                nQueueId: prms.queue.nId,
                                blMsg: prms.queue.blMsg
                            });
                            if (prms.service.sFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST) {
                                options.body = prms.queue.blMsg;
                            } else {
                                options.url = buildURL({
                                    sSrvRoot: prms.service.sSrvRoot,
                                    sFnURL: prms.function.sFnURL,
                                    sQuery: prms.queue.blMsg.toString()
                                });
                            }
                        }
                        if (!_.isUndefined(resBefore.context)) prms.service.context = _.cloneDeep(resBefore.context);
                    } else {
                        //Или расскажем об ошибке
                        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    }
                }
            }
            //Фиксируем отправку сообщения в протоколе работы сервиса
            await logger.info(`Отправляю исходящее сообщение ${prms.queue.nId} на URL: ${options.url}`, {
                nQueueId: prms.queue.nId
            });
            //Отправляем сообщение удалённому серверу
            let serverResp = await rqp(options);
            //Сохраняем полученный ответ
            _.extend(prms, { serverResp });
            await dbConn.setQueueResp({
                nQueueId: prms.queue.nId,
                blResp: new Buffer(prms.serverResp)
            });
            //Выполняем обработчик "После" (если он есть)
            if (prms.function.sAppSrvAfter) {
                const fnAfter = getAppSrvFunction(prms.function.sAppSrvAfter);
                let resAfter = null;
                try {
                    let resAfterPrms = _.cloneDeep(prms);
                    resAfter = await fnAfter(resAfterPrms);
                } catch (e) {
                    throw new ServerError(SERR_APP_SERVER_AFTER, e.message);
                }
                //Проверяем структуру ответа функции постобработки
                if (resAfter) {
                    let sCheckResult = validateObject(
                        resAfter,
                        objOutQueueProcessorSchema.OutQueueProcessorFnAfter,
                        "Результат функции постобработки исходящего сообщения"
                    );
                    //Если структура ответа в норме
                    if (!sCheckResult) {
                        //Применим её
                        if (!_.isUndefined(resAfter.blResp)) prms.queue.blResp = resAfter.blResp;
                        if (!_.isUndefined(resAfter.context)) prms.service.context = _.cloneDeep(resAfter.context);
                    } else {
                        //Или расскажем об ошибке
                        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    }
                } else {
                    prms.queue.blResp = new Buffer(serverResp.toString());
                }
            } else {
                prms.queue.blResp = new Buffer(serverResp.toString());
            }
            //Фиксируем успех исполнения
            newQueue = await dbConn.setQueueAppSrvResult({
                nQueueId: prms.queue.nId,
                blMsg: prms.queue.blMsg,
                blResp: prms.queue.blResp
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
        } catch (e) {
            //Фиксируем ошибку обработки сервером приложений - в статусе сообщения
            newQueue = await dbConn.setQueueState({
                nQueueId: prms.queue.nId,
                sExecMsg: makeErrorText(e),
                nIncExecCnt: NINC_EXEC_CNT_YES,
                nExecState:
                    prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                        ? objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                        : objQueueSchema.NQUEUE_EXEC_STATE_ERR
            });
            //Фиксируем ошибку обработки сервером приложений - в протоколе работы сервиса
            await logger.error(
                `Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером приложений: ${makeErrorText(e)}`,
                { nQueueId: prms.queue.nId }
            );
        }
        //Возвращаем результат
        return newQueue;
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
};

//Запуск обработки сообщения сервером БД
const dbProcess = async prms => {
    //Проверяем структуру переданного объекта для старта
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.dbProcess,
        "Параметры функции запуска обработки ообщения сервером БД"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
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
            //Фиксируем ошибку обработки сервером БД - в статусе сообщения
            await dbConn.setQueueState({
                nQueueId: prms.queue.nId,
                sExecMsg: makeErrorText(e),
                nIncExecCnt: NINC_EXEC_CNT_YES,
                nExecState:
                    prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                        ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                        : objQueueSchema.NQUEUE_EXEC_STATE_ERR
            });
            //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
            await logger.error(
                `Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером БД: ${makeErrorText(e)}`,
                { nQueueId: prms.queue.nId }
            );
        }
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
};

//Обработка задачи
const processTask = async prms => {
    //Проверяем параметры
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.processTask,
        "Параметры функции обработки задачи"
    );
    //Если параметры в норме
    if (!sCheckResult) {
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
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Проверяем аутентификацию
            //if(prms.task.function.)
            //Далее работаем от статуса считанной записи
            switch (q.nExecState) {
                //Поставлено в очередь
                case objQueueSchema.NQUEUE_EXEC_STATE_INQUEUE: {
                    //Запускаем обработку сервером приложений
                    try {
                        let res = await appProcess({
                            queue: q,
                            service: prms.task.service,
                            function: prms.task.function
                        });
                        //И если она успешно завершилась - обработку сервером БД
                        if (res.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_OK) {
                            try {
                                await dbProcess({ queue: res });
                            } catch (e) {
                                //Фиксируем ошибку обработки сервером БД - в статусе сообщения
                                await dbConn.setQueueState({
                                    nQueueId: res.nId,
                                    sExecMsg: makeErrorText(e),
                                    nIncExecCnt: NINC_EXEC_CNT_YES,
                                    nExecState:
                                        res.nExecCnt + 1 < res.nRetryAttempts
                                            ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                                            : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                                });
                                //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
                                await logger.error(
                                    `Ошибка обработки исходящего сообщения ${res.nId} сервером БД: ${makeErrorText(e)}`,
                                    { nQueueId: res.nId }
                                );
                            }
                        }
                    } catch (e) {
                        //Фиксируем ошибку обработки сервером приложений - в статусе сообщения
                        newQueue = await dbConn.setQueueState({
                            nQueueId: q.nId,
                            sExecMsg: makeErrorText(e),
                            nIncExecCnt: NINC_EXEC_CNT_YES,
                            nExecState:
                                q.nExecCnt + 1 < q.nRetryAttempts
                                    ? objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                                    : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                        });
                        //Фиксируем ошибку обработки сервером приложений - в протоколе работы сервиса
                        await logger.error(
                            `Ошибка обработки исходящего сообщения ${q.nId} сервером приложений: ${makeErrorText(e)}`,
                            { nQueueId: q.nId }
                        );
                    }
                    break;
                }
                //Обрабатывается сервером приложений
                case objQueueSchema.NQUEUE_EXEC_STATE_APP: {
                    //Предупредим о неверном статусе сообщения (такие сюда попадать не должны)
                    await logger.warn(`Cообщение ${q.nId} в статусе ${q.sExecState} попало в очередь обработчика`, {
                        nQueueId: q.nId
                    });
                    break;
                }
                //Ошибка обработки сервером приложений
                case objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR: {
                    //Если ещё есть попытки отработки
                    if (q.nExecCnt < q.nRetryAttempts) {
                        //Снова запускаем обработку сервером приложений
                        try {
                            let res = await appProcess({
                                queue: q,
                                service: prms.task.service,
                                function: prms.task.function
                            });
                            //И если она успешно завершилась - обработку сервоером БД
                            if (res.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_OK) {
                                try {
                                    await dbProcess({ queue: res });
                                } catch (e) {
                                    //Фиксируем ошибку обработки сервером БД - в статусе сообщения
                                    await dbConn.setQueueState({
                                        nQueueId: res.nId,
                                        sExecMsg: makeErrorText(e),
                                        nIncExecCnt: NINC_EXEC_CNT_YES,
                                        nExecState:
                                            res.nExecCnt + 1 < res.nRetryAttempts
                                                ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                                                : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                                    });
                                    //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
                                    await logger.error(
                                        `Ошибка обработки исходящего сообщения ${res.nId} сервером БД: ${makeErrorText(
                                            e
                                        )}`,
                                        { nQueueId: res.nId }
                                    );
                                }
                            }
                        } catch (e) {
                            //Фиксируем ошибку обработки сервером приложений - в статусе сообщения
                            newQueue = await dbConn.setQueueState({
                                nQueueId: q.nId,
                                sExecMsg: makeErrorText(e),
                                nIncExecCnt: NINC_EXEC_CNT_YES,
                                nExecState:
                                    q.nExecCnt + 1 < q.nRetryAttempts
                                        ? objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                                        : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                            });
                            //Фиксируем ошибку обработки сервером приложений - в протоколе работы сервиса
                            await logger.error(
                                `Ошибка обработки исходящего сообщения ${q.nId} сервером приложений: ${makeErrorText(
                                    e
                                )}`,
                                { nQueueId: q.nId }
                            );
                        }
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
                    try {
                        await dbProcess({ queue: q });
                    } catch (e) {
                        //Фиксируем ошибку обработки сервером БД - в статусе сообщения
                        await dbConn.setQueueState({
                            nQueueId: q.nId,
                            sExecMsg: makeErrorText(e),
                            nIncExecCnt: NINC_EXEC_CNT_YES,
                            nExecState:
                                q.nExecCnt + 1 < q.nRetryAttempts
                                    ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                                    : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                        });
                        //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
                        await logger.error(
                            `Ошибка обработки исходящего сообщения ${q.nId} сервером БД: ${makeErrorText(e)}`,
                            { nQueueId: q.nId }
                        );
                    }
                    break;
                }
                //Обрабатывается в БД
                case objQueueSchema.NQUEUE_EXEC_STATE_DB: {
                    //Предупредим о неверном статусе сообщения (такие сюда попадать не должны)
                    await logger.warn(`Cообщение ${q.nId} в статусе ${q.sExecState} попало в очередь обработчика`, {
                        nQueueId: q.nId
                    });
                    break;
                }
                //Ошибка обработки в БД
                case objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR: {
                    //Если ещё есть попытки отработки
                    if (q.nExecCnt < q.nRetryAttempts) {
                        //Снова запускаем обработку сервером БД
                        try {
                            await dbProcess({ queue: q });
                        } catch (e) {
                            //Фиксируем ошибку обработки сервером БД - в статусе сообщения
                            await dbConn.setQueueState({
                                nQueueId: q.nId,
                                sExecMsg: makeErrorText(e),
                                nIncExecCnt: NINC_EXEC_CNT_YES,
                                nExecState:
                                    q.nExecCnt + 1 < q.nRetryAttempts
                                        ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                                        : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                            });
                            //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
                            await logger.error(
                                `Ошибка обработки исходящего сообщения ${q.nId} сервером БД: ${makeErrorText(e)}`,
                                { nQueueId: q.nId }
                            );
                        }
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
                    //Предупредим о неверном статусе сообщения (такие сюда попадать не должны)
                    await logger.warn(`Cообщение ${q.nId} в статусе ${q.sExecState} попало в очередь обработчика`, {
                        nQueueId: q.nId
                    });
                    break;
                }
                //Обработано успешно
                case objQueueSchema.NQUEUE_EXEC_STATE_OK: {
                    //Предупредим о неверном статусе сообщения (такие сюда попадать не должны)
                    await logger.warn(`Cообщение ${q.nId} в статусе ${q.sExecState} попало в очередь обработчика`, {
                        nQueueId: q.nId
                    });
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
            sendOKResult({ context: prms.task.service.context });
        } catch (e) {
            //Отключаемся от БД
            if (dbConn) await dbConn.disconnect();
            //Отправляем ошибку
            sendErrorResult({ sMessage: makeErrorText(e) });
        }
    } else {
        sendErrorResult({ sMessage: sCheckResult });
    }
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
    sendErrorResult({ sMessage: makeErrorText(e) });
});

//Приём сообщений
process.on("message", task => {
    //Проверяем структуру переданного сообщения
    let sCheckResult = validateObject(
        task,
        objOutQueueProcessorSchema.OutQueueProcessorTask,
        "Задача обработчика очереди исходящих сообщений"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        //Запускаем обработку
        processTask({ task });
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
});
