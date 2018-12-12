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
const bodyParser = require("body-parser"); //Модуль для Express (разбор тела входящего запроса)
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { SERR_OBJECT_BAD_INTERFACE, SERR_WEB_SERVER } = require("./constants"); //Общесистемные константы
const { makeErrorText, validateObject, buildURL } = require("./utils"); //Вспомогательные функции
const { NINC_EXEC_CNT_YES } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД
const objServiceSchema = require("../models/obj_service"); //Схемы валидации сервиса
const objServiceFnSchema = require("../models/obj_service_function"); //Схемы валидации функции сервиса
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const prmsInQueueSchema = require("../models/prms_in_queue"); //Схемы валидации параметров функций класса

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
            //WEB-приложение
            this.webApp = express();
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
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsInQueueSchema.processMessage,
            "Параметры функции обработки входящего сообщения"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Определимся с телом сообщения
            let blMsg = null;
            //Для POST сообщений - это тело запроса
            if (prms.function.nFnPrmsType == objServiceFnSchema.NFN_PRMS_TYPE_POST) {
                blMsg = prms.req.body && !_.isEmpty(prms.req.body) ? prms.req.body : null;
            } else {
                //Для GET - параметры запроса
                if (!_.isEmpty(prms.req.query)) blMsg = new Buffer(JSON.stringify(prms.req.query));
            }
            //Кладём сообщение в очередь
            let q = await this.dbConn.putQueue({
                nServiceFnId: prms.function.nId,
                blMsg
            });
            //Скажем что пришло новое входящее сообщение
            await this.logger.info(
                `Новое входящее сообщение от ${prms.req.connection.address().address} для фукнции ${
                    prms.function.sCode
                } (${buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL })})`,
                { nQueueId: q.nId }
            );
            prms.res
                .status(200)
                .send(
                    `<html><body><center><br><h1>Сервер приложений ПП Пурс 8</h1><h3>Функция сервиса: ${
                        prms.service.sName
                    }/${prms.function.sCode}</h3></center></body></html>`
                );
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
                        `<html><body><center><br><h1>Сервер приложений ПП Пурс 8</h1><h3>Сервис: ${
                            srvs.sName
                        }</h3></center></body></html>`
                    );
                });
                //Для всех функций сервиса...
                _.forEach(srvs.functions, fn => {
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
                });
            });
            //Запросы на адреса, не входящие в состав объявленных сервисов - 404 NOT FOUND
            this.webApp.use("*", (req, res) => {
                res.status(404).send(
                    "<html><body><center><br><h1>Сервер приложений ПП Пурс 8</h1><h3>Запрошенный адрес не найден</h3></center></body></html>"
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
