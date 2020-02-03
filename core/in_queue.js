/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: отработка очереди входящих сообщений
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const _ = require("lodash"); //Работа с массивами и коллекциями
const EventEmitter = require("events"); //Обработчик пользовательских событий
const express = require("express"); //WEB-сервер Express
const cors = require("cors"); //Управление заголовками безопасности для WEB-сервера Express
const bodyParser = require("body-parser"); //Модуль для Express (разбор тела входящего запроса)
const { ServerError } = require("./server_errors"); //Типовая ошибка
const {
    makeErrorText,
    validateObject,
    buildURL,
    getAppSrvFunction,
    buildOptionsXML,
    parseOptionsXML,
    deepMerge
} = require("./utils"); //Вспомогательные функции
const { NINC_EXEC_CNT_YES, NIS_ORIGINAL_NO } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД
const objInQueueSchema = require("../models/obj_in_queue"); //Схема валидации сообщений обмена с бработчиком очереди входящих сообщений
const objServiceSchema = require("../models/obj_service"); //Схемы валидации сервиса
const objServiceFnSchema = require("../models/obj_service_function"); //Схемы валидации функции сервиса
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const prmsInQueueSchema = require("../models/prms_in_queue"); //Схемы валидации параметров функций класса
const {
    SERR_OBJECT_BAD_INTERFACE,
    SERR_WEB_SERVER,
    SERR_APP_SERVER_BEFORE,
    SERR_APP_SERVER_AFTER,
    SERR_DB_SERVER,
    SERR_UNAUTH
} = require("./constants"); //Общесистемные константы

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Типовые события
const SEVT_IN_QUEUE_STARTED = "IN_QUEUE_STARTED"; //Обработчик очереди запущен
const SEVT_IN_QUEUE_STOPPED = "IN_QUEUE_STOPPED"; //Обработчик очереди остановлен

//------------
// Тело модуля
//------------

//Класс очереди входящих сообщений
class InQueue extends EventEmitter {
    //Конструктор класса
    constructor(prms) {
        //Создадим экземпляр родительского класса
        super();
        //Проверяем структуру переданного объекта для подключения
        let sCheckResult = validateObject(prms, prmsInQueueSchema.InQueue, "Параметры конструктора класса InQueue");
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Список обслуживаемых сервисов
            this.services = null;
            //Признак функционирования обработчика
            this.bWorking = false;
            //Параметры очереди
            this.inComing = _.cloneDeep(prms.inComing);
            //Запомним подключение к БД
            this.dbConn = prms.dbConn;
            //Запомним логгер
            this.logger = prms.logger;
            //Запомним уведомитель
            this.notifier = prms.notifier;
            //WEB-приложение
            this.webApp = express();
            this.webApp.use(cors());
            this.webApp.options("*", cors());
            //WEB-сервер
            this.srv = null;
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Уведомление о запуске обработчика очереди
    notifyStarted() {
        //Оповестим подписчиков о запуске
        this.emit(SEVT_IN_QUEUE_STARTED, this.inComing.nPort);
    }
    //Уведомление об остановке обработчика очереди
    notifyStopped() {
        //Оповестим подписчиков об останове
        this.emit(SEVT_IN_QUEUE_STOPPED);
    }
    //Обработка сообщения
    async processMessage(prms) {
        //Проверяем структуру переданного объекта для обработки
        let sCheckResult = validateObject(
            prms,
            prmsInQueueSchema.processMessage,
            "Параметры функции обработки входящего сообщения"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Буфер для сообщения очереди
            let q = null;
            try {
                //Тело сообщения и ответ на него
                let blMsg = null;
                let blResp = null;
                //Параметры сообщения и ответа на него
                let options = {};
                let optionsResp = {};
                //Определимся с телом сообщения - для POST сообщений - это тело запроса
                if (prms.function.nFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST) {
                    blMsg = prms.req.body && !_.isEmpty(prms.req.body) ? prms.req.body : null;
                } else {
                    //Для GET - параметры запроса
                    if (!_.isEmpty(prms.req.query)) blMsg = new Buffer(JSON.stringify(prms.req.query));
                }
                //Определимся с параметрами сообщения полученными от внешней системы
                options = {
                    method: prms.req.method,
                    qs: _.cloneDeep(prms.req.query),
                    headers: _.cloneDeep(prms.req.headers)
                };
                //Кладём сообщение в очередь
                q = await this.dbConn.putQueue({
                    nServiceFnId: prms.function.nId,
                    sOptions: buildOptionsXML({ options }),
                    blMsg
                });
                //Скажем что пришло новое входящее сообщение
                await this.logger.info(
                    `Новое входящее сообщение от ${prms.req.connection.address().address} для функции ${
                        prms.function.sCode
                    } (${buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL })})`,
                    { nQueueId: q.nId }
                );
                //Выполняем обработчик "До" (если он есть)
                if (prms.function.sAppSrvBefore) {
                    //Выставим статус сообщению очереди - исполняется сервером приложений
                    q = await this.dbConn.setQueueState({
                        nQueueId: q.nId,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP
                    });
                    //Выполняем
                    const fnBefore = getAppSrvFunction(prms.function.sAppSrvBefore);
                    let resBefore = null;
                    try {
                        let resBeforePrms = _.cloneDeep(prms);
                        resBeforePrms.queue = _.cloneDeep(q);
                        resBeforePrms.queue.blMsg = blMsg;
                        resBeforePrms.queue.blResp = blResp;
                        resBeforePrms.options = _.cloneDeep(options);
                        resBefore = await fnBefore(resBeforePrms);
                    } catch (e) {
                        throw new ServerError(SERR_APP_SERVER_BEFORE, e.message);
                    }
                    //Проверяем структуру ответа функции предобработки
                    if (resBefore) {
                        let sCheckResult = validateObject(
                            resBefore,
                            objInQueueSchema.InQueueProcessorFnBefore,
                            "Результат функции предобработки входящего сообщения"
                        );
                        //Если структура ответа в норме
                        if (!sCheckResult) {
                            //Выставим статус сообщению очереди - исполнено сервером приложений
                            q = await this.dbConn.setQueueState({
                                nQueueId: q.nId,
                                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_OK
                            });
                            //Фиксируем результат исполнения "До" - обработанный запрос внешней системы
                            if (!_.isUndefined(resBefore.blMsg)) {
                                blMsg = resBefore.blMsg;
                                q = await this.dbConn.setQueueMsg({
                                    nQueueId: q.nId,
                                    blMsg
                                });
                            }
                            //Фиксируем результат исполнения "До" - ответ на запрос
                            if (!_.isUndefined(resBefore.blResp)) {
                                blResp = resBefore.blResp;
                                q = await this.dbConn.setQueueResp({
                                    nQueueId: q.nId,
                                    blResp,
                                    nIsOriginal: NIS_ORIGINAL_NO
                                });
                            }
                            //Фиксируем результат исполнения "До" - параметры ответа на запрос
                            if (!_.isUndefined(resBefore.optionsResp)) {
                                optionsResp = deepMerge(optionsResp, resBefore.optionsResp);
                                let sOptionsResp = buildOptionsXML({ options: optionsResp });
                                q = await this.dbConn.setQueueOptionsResp({ nQueueId: q.nId, sOptionsResp });
                            }
                            //Если пришел флаг ошибочной аутентификации и он положительный - то это ошибка, дальше ничего не делаем
                            if (!_.isUndefined(resBefore.bUnAuth))
                                if (resBefore.bUnAuth === true)
                                    throw new ServerError(SERR_UNAUTH, "Нет аутентификации");
                        } else {
                            //Или расскажем об ошибке
                            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                        }
                    }
                }
                //Вызываем обработчик со стороны БД (если он есть)
                if (prms.function.sPrcResp) {
                    //Фиксируем начало исполнения сервером БД - в статусе сообщения
                    q = await this.dbConn.setQueueState({
                        nQueueId: q.nId,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB
                    });
                    //Вызов обработчика БД
                    let prcRes = await this.dbConn.execQueueDBPrc({ nQueueId: q.nId });
                    //Если результат - ошибка пробрасываем её
                    if (prcRes.sResult == objQueueSchema.SPRC_RESP_RESULT_ERR)
                        throw new ServerError(SERR_DB_SERVER, prcRes.sMsg);
                    //Если результат - ошибка аутентификации, то и её пробрасываем, но с правильным кодом
                    if (prcRes.sResult == objQueueSchema.SPRC_RESP_RESULT_UNAUTH)
                        throw new ServerError(SERR_UNAUTH, prcRes.sMsg || "Нет аутентификации");
                    //Выставим статус сообщению очереди - исполнено обработчиком БД
                    q = await this.dbConn.setQueueState({
                        nQueueId: q.nId,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB_OK
                    });
                    //Считаем ответ полученный от системы
                    let qData = await this.dbConn.getQueueResp({ nQueueId: q.nId });
                    blResp = qData.blResp;
                    //Запомним параметры ответа внешней системе, если обработчик их вернул
                    if (prcRes.sOptionsResp) {
                        try {
                            let optionsRespTmp = await parseOptionsXML({ sOptions: prcRes.sOptionsResp });
                            optionsResp = deepMerge(optionsResp, optionsRespTmp);
                        } catch (e) {
                            await logger.warn(
                                `Указанные для сообщения параметры ответа имеют некорректный формат - использую параметры по умолчанию. Ошибка парсера: ${makeErrorText(
                                    e
                                )}`,
                                { nQueueId: prms.queue.nId }
                            );
                        }
                    }
                }
                //Выполняем обработчик "После" (если он есть)
                if (prms.function.sAppSrvAfter) {
                    //Выставим статус сообщению очереди - исполняется сервером приложений
                    q = await this.dbConn.setQueueState({
                        nQueueId: q.nId,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP
                    });
                    //Выполняем
                    const fnAfter = getAppSrvFunction(prms.function.sAppSrvAfter);
                    let resAfter = null;
                    try {
                        let resAfterPrms = _.cloneDeep(prms);
                        resAfterPrms.queue = _.cloneDeep(q);
                        resAfterPrms.queue.blMsg = blMsg;
                        resAfterPrms.queue.blResp = blResp;
                        resAfterPrms.options = _.cloneDeep(options);
                        resAfterPrms.optionsResp = _.cloneDeep(optionsResp);
                        resAfter = await fnAfter(resAfterPrms);
                    } catch (e) {
                        throw new ServerError(SERR_APP_SERVER_AFTER, e.message);
                    }
                    //Проверяем структуру ответа функции предобработки
                    if (resAfter) {
                        let sCheckResult = validateObject(
                            resAfter,
                            objInQueueSchema.InQueueProcessorFnAfter,
                            "Результат функции постобработки входящего сообщения"
                        );
                        //Если структура ответа в норме
                        if (!sCheckResult) {
                            //Выставим статус сообщению очереди - исполнено сервером приложений
                            q = await this.dbConn.setQueueState({
                                nQueueId: q.nId,
                                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_OK
                            });
                            //Фиксируем результат исполнения "После" - ответ системы
                            if (!_.isUndefined(resAfter.blResp)) {
                                blResp = resAfter.blResp;
                                q = await this.dbConn.setQueueResp({
                                    nQueueId: q.nId,
                                    blResp,
                                    nIsOriginal: NIS_ORIGINAL_NO
                                });
                            }
                            //Фиксируем результат исполнения "После" - параметры ответа на запрос
                            if (!_.isUndefined(resAfter.optionsResp)) {
                                optionsResp = deepMerge(optionsResp, resAfter.optionsResp);
                                let sOptionsResp = buildOptionsXML({ options: optionsResp });
                                q = await this.dbConn.setQueueOptionsResp({ nQueueId: q.nId, sOptionsResp });
                            }
                            //Если пришел флаг ошибочной аутентификации и он положительный - то это ошибка, дальше ничего не делаем
                            if (!_.isUndefined(resAfter.bUnAuth))
                                if (resAfter.bUnAuth === true) throw new ServerError(SERR_UNAUTH, "Нет аутентификации");
                        } else {
                            //Или расскажем об ошибке
                            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                        }
                    }
                }
                //Всё успешно - отдаём результат клиенту
                if (optionsResp.headers) prms.res.set(optionsResp.headers);
                prms.res.status(200).send(blResp);
                //Фиксируем успех обработки - в статусе сообщения
                q = await this.dbConn.setQueueState({
                    nQueueId: q.nId,
                    nIncExecCnt: NINC_EXEC_CNT_YES,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_OK
                });
                //Фиксируем успех обработки - в протоколе работы сервиса
                await this.logger.info(`Входящее сообщение ${q.nId} успешно отработано`, { nQueueId: q.nId });
            } catch (e) {
                //Тема и текст уведомления об ошибке
                let sSubject = `Ошибка обработки входящего сообщения сервером приложений для функции "${prms.function.sCode}" сервиса "${prms.service.sCode}"`;
                let sMessage = makeErrorText(e);
                //Если сообщение очереди успели создать
                if (q) {
                    //Фиксируем ошибку обработки сервером приложений - в статусе сообщения
                    q = await this.dbConn.setQueueState({
                        nQueueId: q.nId,
                        sExecMsg: sMessage,
                        nIncExecCnt: NINC_EXEC_CNT_YES,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                    });
                    //Фиксируем ошибку обработки сервером приложений - в протоколе работы сервиса
                    await this.logger.error(
                        `Ошибка обработки входящего сообщения ${q.nId} сервером приложений: ${sMessage}`,
                        { nQueueId: q.nId }
                    );
                    //Добавим чуть больше информации в тему сообщения
                    sSubject = `Ошибка обработки входящего сообщения ${q.nId} сервером приложений для функции "${prms.function.sCode}" сервиса "${prms.service.sCode}"`;
                } else {
                    //Ограничимся общей ошибкой
                    await this.logger.error(sMessage, {
                        nServiceId: prms.service.nId,
                        nServiceFnId: prms.function.nId
                    });
                }
                //Если для функции-обработчика указан признак необходимости оповещения об ошибках
                if (prms.function.nErrNtfSign == objServiceFnSchema.NERR_NTF_SIGN_YES) {
                    //Отправим уведомление об ошибке отработки в почту
                    await this.notifier.addMessage({
                        sTo: prms.function.sErrNtfMail,
                        sSubject,
                        sMessage
                    });
                }
                //Отправим ошибку клиенту
                prms.res.status(500).send(makeErrorText(e));
            }
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Запуск обработки очереди входящих сообщений
    startProcessing(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsInQueueSchema.startProcessing,
            "Параметры функции запуска обработки очереди входящих сообщений"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Выставляем флаг работы
            this.bWorking = true;
            //запоминаем список обслуживаемых сервисов
            this.services = prms.services;
            //Конфигурируем сервер - обработка тела сообщения
            this.webApp.use(bodyParser.raw({ limit: `${this.inComing.nMsgMaxSize}mb`, type: "*/*" }));
            //Конфигурируем сервер - обходим все сервисы, работающие на приём сообщений
            _.forEach(_.filter(this.services, { nSrvType: objServiceSchema.NSRV_TYPE_RECIVE }), srvs => {
                //Для любых запросов к корневому адресу сервиса - ответ о том, что это за сервис, и что он работает
                this.webApp.all(srvs.sSrvRoot, (req, res) => {
                    res.status(200).send(
                        `<html><body><center><br><h1>Сервер приложений ПП Парус 8</h1><h3>Сервис: ${srvs.sName}</h3></center></body></html>`
                    );
                });
                //Для всех статических функций сервиса...
                _.forEach(
                    _.filter(srvs.functions, fn => fn.sFnURL.startsWith("@")),
                    fn => {
                        this.webApp.use(
                            buildURL({ sSrvRoot: srvs.sSrvRoot, sFnURL: fn.sFnURL.substr(1) }),
                            express.static(`${this.inComing.sStaticDir}/${fn.sFnURL.substr(1)}`)
                        );
                    }
                );
                //Для всех функций сервиса (кроме статических)...
                _.forEach(
                    _.filter(srvs.functions, fn => !fn.sFnURL.startsWith("@")),
                    fn => {
                        //...собственный обработчик, в зависимости от указанного способа передачи параметров
                        this.webApp[fn.nFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST ? "post" : "get"](
                            buildURL({ sSrvRoot: srvs.sSrvRoot, sFnURL: fn.sFnURL }),
                            async (req, res) => {
                                try {
                                    //Вызываем обработчик
                                    await this.processMessage({ req, res, service: srvs, function: fn });
                                } catch (e) {
                                    //Протоколируем в журнал работы сервера
                                    await this.logger.error(makeErrorText(e), {
                                        nServiceId: srvs.nId,
                                        nServiceFnId: fn.nId
                                    });
                                    //Отправим ошибку клиенту
                                    res.status(500).send(makeErrorText(e));
                                }
                            }
                        );
                        //...и собственный обработчик ошибок
                        this.webApp.use(
                            buildURL({ sSrvRoot: srvs.sSrvRoot, sFnURL: fn.sFnURL }),
                            async (err, req, res, next) => {
                                //Протоколируем в журнал работы сервера
                                await this.logger.error(makeErrorText(new ServerError(SERR_WEB_SERVER, err.message)), {
                                    nServiceId: srvs.nId,
                                    nServiceFnId: fn.nId
                                });
                                //Отправим ошибку клиенту
                                res.status(500).send(makeErrorText(new ServerError(SERR_WEB_SERVER, err.message)));
                            }
                        );
                    }
                );
            });
            //Запросы на адреса, не входящие в состав объявленных сервисов - 404 NOT FOUND
            this.webApp.use("*", (req, res) => {
                res.status(404).send(
                    "<html><body><center><br><h1>Сервер приложений ПП Парус 8</h1><h3>Запрошенный адрес не найден</h3></center></body></html>"
                );
            });
            //Ошибки, не отработанные индивидуальными обработчиками - 500 SERVER ERROR
            this.webApp.use(async (err, req, res, next) => {
                //Протоколируем в журнал работы сервера
                await this.logger.error(makeErrorText(new ServerError(SERR_WEB_SERVER, err.message)));
                //Отправим ошибку клиенту
                res.status(500).send(makeErrorText(new ServerError(SERR_WEB_SERVER, err.message)));
            });
            //Запускаем сервер
            this.srv = this.webApp.listen(this.inComing.nPort, () => {
                //И оповещаем всех что запустились
                this.notifyStarted();
            });
            this.srv.on("error", e => {
                throw new ServerError(e.code, `Фатальная ошибка обработчика очереди входящих сообщений: ${e.message}`);
            });
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Остановка обработки очереди исходящих сообщений
    stopProcessing() {
        //Выставляем флаг неработы
        this.bWorking = false;
        //Останавливаем WEB-сервер (если создавался)
        if (this.srv) {
            this.srv.close(() => {
                //Оповещаем всхес, что остановились
                this.notifyStopped();
            });
        } else {
            //Сервер не создавался - просто оповещаем всех, что остановились
            this.notifyStopped();
        }
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.SEVT_IN_QUEUE_STARTED = SEVT_IN_QUEUE_STARTED;
exports.SEVT_IN_QUEUE_STOPPED = SEVT_IN_QUEUE_STOPPED;
exports.InQueue = InQueue;
