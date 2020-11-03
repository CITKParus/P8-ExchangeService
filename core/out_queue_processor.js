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
const {
    makeErrorText,
    validateObject,
    getAppSrvFunction,
    buildURL,
    parseOptionsXML,
    buildOptionsXML,
    deepMerge
} = require("./utils"); //Вспомогательные функции
const { ServerError } = require("./server_errors"); //Типовая ошибка
const objOutQueueProcessorSchema = require("../models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const prmsOutQueueProcessorSchema = require("../models/prms_out_queue_processor"); //Схема валидации параметров функций модуля
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const objServiceSchema = require("../models/obj_service"); //Схемы валидации сервиса
const objServiceFnSchema = require("../models/obj_service_function"); //Схемы валидации функции сервиса
const {
    SERR_OBJECT_BAD_INTERFACE,
    SERR_APP_SERVER_BEFORE,
    SERR_APP_SERVER_AFTER,
    SERR_DB_SERVER,
    SERR_WEB_SERVER,
    SERR_UNAUTH
} = require("./constants"); //Глобальные константы
const {
    NINC_EXEC_CNT_YES,
    NINC_EXEC_CNT_NO,
    NIS_ORIGINAL_NO,
    NIS_ORIGINAL_YES
} = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД

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
            sMsg: prms.sMessage
        });
    } else {
        process.send({
            sResult: objOutQueueProcessorSchema.STASK_RESULT_ERR,
            sMsg: sCheckResult
        });
    }
};

//Отправка родительскому процессу успеха обработки сообщения сервером приложений
const sendOKResult = () => {
    process.send({
        sResult: objOutQueueProcessorSchema.STASK_RESULT_OK,
        sMsg: null
    });
};

//Отправка родительскому процессу успеха обработки сообщения сервером приложений
const sendUnAuthResult = () => {
    process.send({
        sResult: objOutQueueProcessorSchema.STASK_RESULT_UNAUTH,
        sMsg: null
    });
};

//Запуск обработки сообщения сервером приложений
const appProcess = async prms => {
    //Результат обработки - объект Queue (обработанное сообщение) или ServerError (ошибка обработки)
    let res = null;
    //Проверяем структуру переданного объекта для старта
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.appProcess,
        "Параметры функции запуска обработки ообщения сервером приложений"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        //Запоминаем текущий статус сообщения
        let nOldExecState = prms.queue.nExecState;
        //Обрабатываем
        try {
            //Считываем статус аутентификации сервиса
            let isServiceAuth = await dbConn.isServiceAuth({ nServiceId: prms.service.nId });
            //Проверяем аутентификацию
            if (
                prms.function.nAuthOnly == objServiceFnSchema.NAUTH_ONLY_NO ||
                (prms.function.nAuthOnly == objServiceFnSchema.NAUTH_ONLY_YES &&
                    isServiceAuth == objServiceSchema.NIS_AUTH_YES)
            ) {
                //Фиксируем начало исполнения сервером приложений - в статусе сообщения
                res = await dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP
                });
                //Фиксируем начало исполнения сервером приложений - в протоколе работы сервиса
                await logger.info(
                    `Обрабатываю исходящее сообщение сервером приложений: ${prms.queue.nId}, ${prms.queue.sInDate}, ${
                        prms.queue.sServiceFnCode
                    }, ${prms.queue.sExecState}, попытка исполнения - ${prms.queue.nExecCnt + 1}`,
                    { nQueueId: prms.queue.nId }
                );
                //Считаем тело сообщения
                let qData = await dbConn.getQueueMsg({ nQueueId: prms.queue.nId });
                //Считаем контекст сервиса
                let serviceCtx = await dbConn.getServiceContext({ nServiceId: prms.service.nId });
                //Флаг установленности контекста для функции начала сеанса
                let bCtxIsSet = false;
                //Кладём данные тела в объект сообщения и инициализируем поле для ответа
                _.extend(prms.queue, { blMsg: qData.blMsg, blResp: null });
                //Кладём данные контекста в сервис
                _.extend(prms.service, serviceCtx);
                //Собираем параметры для передачи серверу
                let options = { method: prms.function.sFnPrmsType, encoding: null };
                //Инициализируем параметры ответа сервера
                let optionsResp = {};
                //Определимся с URL и телом сообщения в зависимости от способа передачи параметров
                if (prms.function.nFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST) {
                    options.url = buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL });
                    options.body = prms.queue.blMsg;
                    options.headers = { "content-type": "application/octet-stream" };
                } else {
                    options.url = buildURL({
                        sSrvRoot: prms.service.sSrvRoot,
                        sFnURL: prms.function.sFnURL,
                        sQuery: prms.queue.blMsg === null ? "" : prms.queue.blMsg.toString()
                    });
                }
                //Дополним получившиеся параметры переданными в сообщении
                if (prms.queue.sOptions) {
                    try {
                        let optionsTmp = await parseOptionsXML({ sOptions: prms.queue.sOptions });
                        options = deepMerge(options, optionsTmp);
                        //При конвертации XML -> JSON пустые тэги приходят как "", а в encoding нужен или null, или правильная кодировка
                        if (options.encoding === "") options.encoding = null;
                    } catch (e) {
                        await logger.warn(
                            `Указанные для сообщения параметры имеют некорректный формат - использую параметры по умолчанию. Ошибка парсера: ${makeErrorText(
                                e
                            )}`,
                            { nQueueId: prms.queue.nId }
                        );
                    }
                }
                //Выполняем обработчик "До" (если он есть)
                if (prms.function.sAppSrvBefore) {
                    const fnBefore = getAppSrvFunction(prms.function.sAppSrvBefore);
                    let resBefore = null;
                    try {
                        let resBeforePrms = _.cloneDeep(prms);
                        resBeforePrms.options = _.cloneDeep(options);
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
                            //Применим ответ "До" - обработанное сообщение очереди
                            if (!_.isUndefined(resBefore.blMsg)) {
                                prms.queue.blMsg = resBefore.blMsg;
                                await dbConn.setQueueMsg({
                                    nQueueId: prms.queue.nId,
                                    blMsg: prms.queue.blMsg
                                });
                                if (prms.function.nFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST) {
                                    options.body = prms.queue.blMsg;
                                } else {
                                    options.url = buildURL({
                                        sSrvRoot: prms.service.sSrvRoot,
                                        sFnURL: prms.function.sFnURL,
                                        sQuery: prms.queue.blMsg === null ? "" : prms.queue.blMsg.toString()
                                    });
                                }
                            }
                            //Применим ответ "До" - параметры отправки сообщения удаленному серверу
                            if (!_.isUndefined(resBefore.options)) options = deepMerge(options, resBefore.options);
                            //Применим ответ "До" - флаг отсуствия аутентификации
                            if (!_.isUndefined(resBefore.bUnAuth))
                                if (resBefore.bUnAuth === true) {
                                    throw new ServerError(SERR_UNAUTH, "Нет аутентификации");
                                }
                            //Применим ответ "До" - контекст работы сервиса
                            if (!_.isUndefined(resBefore.sCtx))
                                if (prms.function.nFnType == objServiceFnSchema.NFN_TYPE_LOGIN) {
                                    prms.service.sCtx = resBefore.sCtx;
                                    prms.service.dCtxExp = resBefore.dCtxExp;
                                    await dbConn.setServiceContext({
                                        nServiceId: prms.service.nId,
                                        sCtx: prms.service.sCtx,
                                        dCtxExp: prms.service.dCtxExp
                                    });
                                    bCtxIsSet = true;
                                }
                        } else {
                            //Или расскажем об ошибке в структуре ответа
                            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                        }
                    }
                }
                //Фиксируем отправку сообщения в протоколе работы сервиса
                await logger.info(`Отправляю исходящее сообщение ${prms.queue.nId} на URL: ${options.url}`, {
                    nQueueId: prms.queue.nId
                });
                //Отправляем сообщение удалённому серверу
                try {
                    //Сохраняем параметры с которыми уходило сообщение
                    try {
                        let tmpOptions = _.cloneDeep(options);
                        delete tmpOptions.body;
                        let sOptions = buildOptionsXML({ options: tmpOptions });
                        await dbConn.setQueueOptions({ nQueueId: prms.queue.nId, sOptions });
                    } catch (e) {
                        await logger.warn(`Не удалось сохранить параметры отправки сообщения: ${makeErrorText(e)}`, {
                            nQueueId: prms.queue.nId
                        });
                    }
                    //Ждем ответ от удалённого сервера
                    options.resolveWithFullResponse = true;
                    let serverResp = await rqp(options);
                    //Сохраняем полученный ответ
                    prms.queue.blResp = new Buffer(serverResp.body || "");
                    await dbConn.setQueueResp({
                        nQueueId: prms.queue.nId,
                        blResp: prms.queue.blResp,
                        nIsOriginal: NIS_ORIGINAL_YES
                    });
                    //Сохраняем заголовки ответа и HTTP-статус
                    optionsResp.headers = _.cloneDeep(serverResp.headers);
                    optionsResp.statusCode = serverResp.statusCode;
                    try {
                        let sOptionsResp = buildOptionsXML({ options: optionsResp });
                        await dbConn.setQueueOptionsResp({ nQueueId: prms.queue.nId, sOptionsResp });
                    } catch (e) {
                        await logger.warn(
                            `Не удалось сохранить заголовок ответа удалённого сервера: ${makeErrorText(e)}`,
                            { nQueueId: prms.queue.nId }
                        );
                    }
                } catch (e) {
                    //Прекращаем исполнение если были ошибки
                    let sError = "Неожиданная ошибка удалённого сервиса";
                    if (e.error) {
                        let sSubError = e.error.code || e.error;
                        sError = `Ошибка передачи данных: ${sSubError}`;
                    }
                    if (e.response) sError = `${e.response.statusCode} - ${e.response.statusMessage}`;
                    throw new ServerError(SERR_WEB_SERVER, sError);
                }
                //Выполняем обработчик "После" (если он есть)
                if (prms.function.sAppSrvAfter) {
                    const fnAfter = getAppSrvFunction(prms.function.sAppSrvAfter);
                    let resAfter = null;
                    try {
                        let resAfterPrms = _.cloneDeep(prms);
                        resAfterPrms.options = _.cloneDeep(options);
                        resAfterPrms.optionsResp = _.cloneDeep(optionsResp);
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
                            //Применим ответ "После" - обработанный ответ удаленного сервиса
                            if (!_.isUndefined(resAfter.blResp)) {
                                prms.queue.blResp = resAfter.blResp;
                                await dbConn.setQueueResp({
                                    nQueueId: prms.queue.nId,
                                    blResp: prms.queue.blResp,
                                    nIsOriginal: NIS_ORIGINAL_NO
                                });
                            }
                            //Применим ответ "После" - флаг утентификации сервиса
                            if (!_.isUndefined(resAfter.bUnAuth))
                                if (resAfter.bUnAuth === true) throw new ServerError(SERR_UNAUTH, "Нет аутентификации");
                            //Применим ответ "После" - контекст работы сервиса
                            if (!_.isUndefined(resAfter.sCtx))
                                if (prms.function.nFnType == objServiceFnSchema.NFN_TYPE_LOGIN) {
                                    prms.service.sCtx = resAfter.sCtx;
                                    prms.service.dCtxExp = resAfter.dCtxExp;
                                    await dbConn.setServiceContext({
                                        nServiceId: prms.service.nId,
                                        sCtx: prms.service.sCtx,
                                        dCtxExp: prms.service.dCtxExp
                                    });
                                    bCtxIsSet = true;
                                }
                        } else {
                            //Или расскажем об ошибке в структуре ответа
                            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                        }
                    }
                }
                //Если это функция начала сеанса, и нет обработчика на стороне БД и контекст не был установлен до сих пор - то положим в него то, что нам ответил сервер
                if (
                    prms.function.nFnType == objServiceFnSchema.NFN_TYPE_LOGIN &&
                    !prms.function.sPrcResp &&
                    !bCtxIsSet
                ) {
                    await dbConn.setServiceContext({ nServiceId: prms.service.nId, sCtx: serverResp });
                }
                //Если это функция окончания сеанса, и нет обработчика на стороне БД - то сбросим контекст здесь
                if (prms.function.nFnType == objServiceFnSchema.NFN_TYPE_LOGOUT && !prms.function.sPrcResp) {
                    await dbConn.clearServiceContext({ nServiceId: prms.service.nId });
                }
                //Фиксируем успешное исполнение сервером приложений - в статусе сообщения
                res = await dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_OK
                });
                //Фиксируем успешное исполнение сервером приложений - в протоколе работы сервиса
                await logger.info(`Исходящее сообщение ${prms.queue.nId} успешно отработано сервером приложений`, {
                    nQueueId: prms.queue.nId
                });
            } else {
                //Нет атуентификации
                throw new ServerError(SERR_UNAUTH, "Нет аутентификации");
            }
        } catch (e) {
            //Если была ошибка аутентификации - возвращаем старый статус не меняя количества попыток
            if (e instanceof ServerError && e.sCode == SERR_UNAUTH) {
                await dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    sExecMsg: makeErrorText(e),
                    nExecState: nOldExecState,
                    nResetData: objQueueSchema.NQUEUE_RESET_DATA_YES
                });
                res = e;
            } else {
                //Фиксируем ошибку обработки сервером приложений - в статусе сообщения
                res = await dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    sExecMsg: makeErrorText(e),
                    nResetData:
                        prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                            ? objQueueSchema.NQUEUE_RESET_DATA_YES
                            : objQueueSchema.NQUEUE_RESET_DATA_NO,
                    nIncExecCnt: NINC_EXEC_CNT_YES,
                    nExecState:
                        prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                            ? objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                            : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                });
            }
            //Фиксируем ошибку обработки сервером приложений - в протоколе работы сервиса
            await logger.error(
                `Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером приложений: ${makeErrorText(e)}`,
                { nQueueId: prms.queue.nId }
            );
        }
    } else {
        //Фатальная ошибка обработки - некорректный объект параметров
        res = new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
    //Возвращаем результат
    return res;
};

//Запуск обработки сообщения сервером БД
const dbProcess = async prms => {
    //Результат обработки - объект Queue (обработанное сообщение) или ServerError (ошибка обработки)
    let res = null;
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
            res = await dbConn.setQueueState({
                nQueueId: prms.queue.nId,
                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB
            });
            //Фиксируем начало исполнения сервером БД - в протоколе работы сервиса
            await logger.info(
                `Обрабатываю исходящее сообщение сервером БД: ${prms.queue.nId}, ${prms.queue.sInDate}, ${
                    prms.queue.sServiceFnCode
                }, ${prms.queue.sExecState}, попытка исполнения - ${prms.queue.nExecCnt + 1}`,
                { nQueueId: prms.queue.nId }
            );
            //Если обработчик со стороны БД указан
            if (prms.function.sPrcResp) {
                //Вызываем его
                let prcRes = await dbConn.execQueueDBPrc({ nQueueId: prms.queue.nId });
                //Если результат - ошибка пробрасываем её
                if (prcRes.sResult == objQueueSchema.SPRC_RESP_RESULT_ERR)
                    throw new ServerError(SERR_DB_SERVER, prcRes.sMsg);
                //Если результат - ошибка аутентификации, то и её пробрасываем, но с правильным кодом
                if (prcRes.sResult == objQueueSchema.SPRC_RESP_RESULT_UNAUTH)
                    throw new ServerError(SERR_UNAUTH, prcRes.sMsg || "Нет аутентификации");
            }
            //Фиксируем успешное исполнение (полное - дальше обработки нет) - в статусе сообщения
            res = await dbConn.setQueueState({
                nQueueId: prms.queue.nId,
                nIncExecCnt: prms.queue.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_OK
            });
            //Фиксируем успешное исполнение сервером БД - в протоколе работы сервиса
            await logger.info(`Исходящее сообщение ${prms.queue.nId} успешно отработано сервером БД`, {
                nQueueId: prms.queue.nId
            });
        } catch (e) {
            //Если была ошибка аутентификации - возвращаем на повторную обработку сервером приложений
            if (e instanceof ServerError && e.sCode == SERR_UNAUTH) {
                await dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    sExecMsg: makeErrorText(e),
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_INQUEUE,
                    nResetData: objQueueSchema.NQUEUE_RESET_DATA_YES
                });
                res = e;
            } else {
                //Фиксируем ошибку обработки сервером БД - в статусе сообщения
                res = await dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    sExecMsg: makeErrorText(e),
                    nIncExecCnt: NINC_EXEC_CNT_YES,
                    nExecState:
                        prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                            ? objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                            : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                });
            }
            //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
            await logger.error(
                `Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером БД: ${makeErrorText(e)}`,
                { nQueueId: prms.queue.nId }
            );
        }
    } else {
        //Фатальная ошибка обработки - некорректный объект параметров
        res = new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
    //Возвращаем результат
    return res;
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
            //Далее работаем от статуса считанной записи
            switch (q.nExecState) {
                //Статусы "Поставлено в очередь" или "Ошибка обработки сервером приложений"
                case objQueueSchema.NQUEUE_EXEC_STATE_INQUEUE:
                case objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR: {
                    //Если ещё не обрабатывали или есть ещё попытки отработки
                    if (q.nExecCnt == 0 || q.nExecCnt < q.nRetryAttempts) {
                        //Запускаем обработку сервером приложений
                        let res = await appProcess({
                            queue: q,
                            service: prms.task.service,
                            function: prms.task.function
                        });
                        //Если результат обработки ошибка - пробрасываем её дальше
                        if (res instanceof ServerError) {
                            throw res;
                        } else {
                            //Нет ошибки, посмотрим что прилетело сообщение в успешном статусе и тогда запустим обработку сервером БД
                            if (res.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_OK) {
                                res = await dbProcess({ queue: res, function: prms.task.function });
                                //Если результат обработки ошибка - пробрасываем её дальше
                                if (res instanceof ServerError) throw res;
                            }
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
                //Статусы "Успешно обработано сервером приложений" и "Ошибка обработки в БД"
                case objQueueSchema.NQUEUE_EXEC_STATE_APP_OK:
                case objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR: {
                    //Если ещё есть попытки отработки
                    if (q.nExecCnt == 0 || q.nExecCnt < q.nRetryAttempts) {
                        //Снова запускаем обработку сервером БД
                        let res = await dbProcess({ queue: q, function: prms.task.function });
                        //Если результат обработки ошибка - пробрасываем её дальше
                        if (res instanceof ServerError) throw res;
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
                //Статусы "Обрабатывается сервером приложений", "Обрабатывается в БД", "Обработано с ошибками", "Обработано успешно"
                case objQueueSchema.NQUEUE_EXEC_STATE_APP:
                case objQueueSchema.NQUEUE_EXEC_STATE_DB:
                case objQueueSchema.NQUEUE_EXEC_STATE_ERR:
                case objQueueSchema.NQUEUE_EXEC_STATE_OK: {
                    //Предупредим о неверном статусе сообщения (такие сюда попадать не должны)
                    await logger.warn(`Cообщение ${q.nId} в статусе ${q.sExecState} попало в очередь обработчика`, {
                        nQueueId: q.nId
                    });
                    break;
                }
                //Неипонятный статус
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
            if (e instanceof ServerError && e.sCode == SERR_UNAUTH) sendUnAuthResult();
            else sendErrorResult({ sMessage: makeErrorText(e) });
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
process.on("SIGTERM", () => {
    process.exit(0);
});

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
