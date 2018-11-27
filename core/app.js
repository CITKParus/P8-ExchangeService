/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: сервер приложений
*/

//----------------------
// Подключение библиотек
//----------------------

const lg = require("./logger"); //Протоколирование работы
const db = require("./db_connector"); //Взаимодействие с БД
const oq = require("./out_queue"); //Прослушивание очереди исходящих сообщений
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { validateObject } = require("./utils"); //Вспомогательные функции
const { SERR_COMMON, SERR_OBJECT_BAD_INTERFACE } = require("./constants"); //Общесистемные константы
const prmsAppSchema = require("../models/prms_app"); //Схема валидации параметров функций класса
//------------
// Тело модуля
//------------

//Класс сервера приложений
class ParusAppServer {
    //конструктор класса
    constructor() {
        //Создаём логгер для протоколирования работы
        this.logger = new lg.Logger();
        //Подключение к БД
        this.dbConn = null;
        //Обработчик очереди исходящих
        this.outQ = null;
        //Привяжем методы к указателю на себя для использования в обработчиках событий
        this.onDBConnected = this.onDBConnected.bind(this);
        this.onDBDisconnected = this.onDBDisconnected.bind(this);
    }
    //При подключении к БД
    async onDBConnected(connection) {
        this.logger.setDBConnector(this.dbConn, true);
        await this.logger.info("Сервер приложений подключен к БД");
    }
    //При отключении от БД
    async onDBDisconnected() {
        this.logger.removeDBConnector();
        await this.logger.warn("Сервер приложений отключен от БД");
    }
    //Инициализация сервера
    async init(prms) {
        await this.logger.info("Инициализация сервера приложений...");
        //Проверяем структуру переданного объекта конфигурации
        let sCheckResult = validateObject(prms, prmsAppSchema.init, "Параметры инициализации");
        //Если настройки верны - будем стартовать
        if (!sCheckResult) {
            //Создаём подключение к БД
            this.dbConn = new db.DBConnector({ connectSettings: prms.config.dbConnect });
            //Создаём обработчик очереди исходящих
            this.outQ = new oq.OutQueue({ outGoing: prms.config.outGoing, dbConn: this.dbConn, logger: this.logger });
            //Скажем что инициализировали
            await this.logger.info("Сервер приложение инициализирован");
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Запуск сервера
    async run() {
        await this.logger.info("Запуск сервера приложений...");
        if (!this.logger || !this.dbConn || !this.outQ) {
            throw new ServerError(SERR_COMMON, "Не пройдена инициализация");
        }
        this.dbConn.on(db.SEVT_DB_CONNECTOR_CONNECTED, this.onDBConnected);
        this.dbConn.on(db.SEVT_DB_CONNECTOR_DISCONNECTED, this.onDBDisconnected);
        await this.logger.info("Подключение сервера приложений к БД...");
        await this.dbConn.connect();
        await this.outQ.startProcessing();
        await this.logger.info("Сервер приложений запущен");
    }
    //Останов сервера
    async stop() {
        await this.logger.warn("Останов сервера приложений...");
        if (this.outQ) await this.outQ.stopProcessing();
        if (this.dbConn) {
            if (this.dbConn.bConnected) {
                await this.logger.warn("Отключение сервера приложений от БД...");
                try {
                    await this.dbConn.disconnect();
                    process.exit(0);
                } catch (e) {
                    await this.logger.error("Ошибка отключения от БД: " + e.sCODE + ": " + e.sMessage);
                    process.exit(1);
                }
            } else {
                process.exit(0);
            }
        }
    }
}

//------------------
//  Интерфейс модуля
//------------------

exports.ParusAppServer = ParusAppServer;
