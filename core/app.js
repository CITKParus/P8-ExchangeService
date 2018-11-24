/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: сервер приложений
*/

//----------------------
// Подключение библиотек
//----------------------

const lg = require("../core/logger"); //Протоколирование работы
const db = require("../core/db_connector"); //Взаимодействие с БД
const oq = require("../core/out_queue"); //Прослушивание очереди исходящих сообщений

//------------
// Тело модуля
//------------

//Класс сервера приложений
class ParusAppServer {
    //конструктор класса
    constructor(prms) {
        //Создаём подключение к БД
        this.dbConn = new db.DBConnector(prms.dbConnect);
        //Создаём логгер для протоколирования работы
        this.logger = new lg.Logger();
        //Создаём обработчик очереди исходящих
        this.outQ = new oq.OutQueue(prms.outgoing, this.dbConn, this.logger);
        //Привяжем методы к указателю на себя для использования в обработчиках событий
        this.onDBConnected = this.onDBConnected.bind(this);
        this.onDBDisconnected = this.onDBDisconnected.bind(this);
    }
    //При подключении к БД
    async onDBConnected(connection) {
        this.logger.setDBConnector(this.dbConn);
        await this.logger.info("Сервер приложений подключен к БД");
    }
    //При отключении от БД
    async onDBDisconnected() {
        this.logger.removeDBConnector();
        await this.logger.warn("Сервер приложений отключен от БД");
    }
    //Запуск сервера
    async run() {
        await this.logger.info("Запуск сервера приложений...");
        this.dbConn.on(db.SEVT_DB_CONNECTOR_CONNECTED, this.onDBConnected);
        this.dbConn.on(db.SEVT_DB_CONNECTOR_DISCONNECTED, this.onDBDisconnected);
        await this.logger.info("Подключение сервера приложений к БД...");
        try {
            await this.dbConn.connect();
        } catch (e) {
            await this.logger.error("Ошибка подключения к БД: " + e.sCODE + ": " + e.sMessage);
            stop();
            return;
        }
        await this.outQ.startProcessing();
        await this.logger.info("Сервер приложений запущен");
    }
    //Останов сервера
    async stop() {
        await this.logger.warn("Останов сервера приложений...");
        await this.outQ.stopProcessing();
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

//------------------
//  Интерфейс модуля
//------------------

exports.ParusAppServer = ParusAppServer;
