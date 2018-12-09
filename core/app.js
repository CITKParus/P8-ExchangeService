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
const sac = require("./service_available_controller"); //Контроль доступности удалённых сервисов
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { makeErrorText, validateObject } = require("./utils"); //Вспомогательные функции
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
        //Контроллер доступности удалённых сервисов
        this.srvAvlCtrl = null;
        //Флаг остановки сервера
        this.bStopping = false;
        //Список обслуживаемых сервисов
        this.services = [];
        //Привяжем методы к указателю на себя для использования в обработчиках событий
        this.onDBConnected = this.onDBConnected.bind(this);
        this.onDBDisconnected = this.onDBDisconnected.bind(this);
        this.onOutQStarted = this.onOutQStarted.bind(this);
        this.onOutQStopped = this.onOutQStopped.bind(this);
        this.onServiceACStarted = this.onServiceACStarted.bind(this);
        this.onServiceACStopped = this.onServiceACStopped.bind(this);
    }
    //При подключении к БД
    async onDBConnected(connection) {
        //Укажем логгеру, что можно писать в базу
        this.logger.setDBConnector(this.dbConn, true);
        //Сообщим, что подключились к БД
        await this.logger.info("Сервер приложений подключен к БД");
        //Считываем список сервисов
        await this.logger.info("Запрашиваю информацию о сервисах...");
        try {
            this.services = await this.dbConn.getServices();
        } catch (e) {
            await this.logger.error(`Ошибка получения списка сервисов: ${makeErrorText(e)}`);
            await this.stop();
            return;
        }
        await this.logger.info("Список сервисов получен");
        //Запускаем обслуживание очереди исходящих
        await this.logger.info("Запуск обработчика очереди исходящих сообщений...");
        try {
            this.outQ.startProcessing({ services: this.services });
        } catch (e) {
            await this.logger.error(`Ошибка запуска обработчика очереди исходящих сообщений: ${makeErrorText(e)}`);
            await this.stop();
            return;
        }
    }
    //При отключении от БД
    async onDBDisconnected() {
        //Укажем логгеру, что писать в базу больше нельзя
        this.logger.removeDBConnector();
        //Сообщим, что отключились от БД
        await this.logger.warn("Сервер приложений отключен от БД");
    }
    //При запуске обработчика исходящих сообщений
    async onOutQStarted() {
        //Сообщим, что запустили обработчик
        await this.logger.info("Обработчик очереди исходящих сообщений запущен");

        //Запускаем обслуживание очереди исходящих
        await this.logger.info("Запуск контроллера доступности удалённых сервисов...");
        try {
            this.srvAvlCtrl.startController({ services: this.services });
        } catch (e) {
            await this.logger.error(`Ошибка запуска контроллера доступности удалённых сервисов: ${makeErrorText(e)}`);
            await this.stop();
            return;
        }
        //Рапортуем, что запустились
        await this.logger.info("Сервер приложений запущен");
    }
    //При останове обработчика исходящих сообщений
    async onOutQStopped() {
        //Сообщим, что остановили обработчик
        await this.logger.warn("Обработчик очереди исходящих сообщений остановлен");
        //Останавливаем контроллер доступности удалённных сервисов
        await this.logger.warn("Останов контроллера доступности удалённых сервисов...");
        if (this.srvAvlCtrl) this.srvAvlCtrl.stopController();
        else await this.onServiceACStopped();
    }
    //При запуске контроллера доступности удаленных сервисов
    async onServiceACStarted() {
        //Сообщим, что запустили обработчик
        await this.logger.info("Контроллер доступности удалённых сервисов запущен");
    }
    //При останове контроллера доступности удаленных сервисов
    async onServiceACStopped() {
        //Сообщим, что остановили обработчик
        await this.logger.warn("Контроллер доступности удалённых сервисов остановлен");
        //Отключение от БД
        if (this.dbConn) {
            if (this.dbConn.bConnected) {
                await this.logger.warn("Отключение сервера приложений от БД...");
                try {
                    await this.dbConn.disconnect();
                    process.exit(0);
                } catch (e) {
                    await this.logger.error("Ошибка отключения от БД: " + e.sCode + ": " + e.sMessage);
                    process.exit(1);
                }
            } else {
                process.exit(0);
            }
        } else {
            process.exit(0);
        }
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
            //Создаём контроллер доступности удалённых сервислв
            this.srvAvlCtrl = new sac.ServiceAvailableController({ logger: this.logger, mail: prms.config.mail });
            //Скажем что инициализировали
            await this.logger.info("Сервер приложений инициализирован");
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Запуск сервера
    async run() {
        //Рапортуем, что начали запуск
        await this.logger.info("Запуск сервера приложений...");
        //Проверим, что сервер успешно инициализирован
        if (!this.logger || !this.dbConn || !this.outQ) {
            throw new ServerError(SERR_COMMON, "Не пройдена инициализация");
        }
        //Включим прослушивание событий БД (для подключения/отключения логгера к БД)
        this.dbConn.on(db.SEVT_DB_CONNECTOR_CONNECTED, this.onDBConnected);
        this.dbConn.on(db.SEVT_DB_CONNECTOR_DISCONNECTED, this.onDBDisconnected);
        //Включим прослушивание событий обработчика исходящих сообщений
        this.outQ.on(oq.SEVT_OUT_QUEUE_STARTED, this.onOutQStarted);
        this.outQ.on(oq.SEVT_OUT_QUEUE_STOPPED, this.onOutQStopped);
        //Включим прослушивание событий контроллера доступности удалённых сервисов
        this.srvAvlCtrl.on(sac.SEVT_SERVICE_AVAILABLE_CONTROLLER_STARTED, this.onServiceACStarted);
        this.srvAvlCtrl.on(sac.SEVT_SERVICE_AVAILABLE_CONTROLLER_STOPPED, this.onServiceACStopped);
        //Подключаемся к БД
        await this.logger.info("Подключение сервера приложений к БД...");
        await this.dbConn.connect();
    }
    //Останов сервера
    async stop() {
        if (!this.bStopping) {
            //Установим флаг - остановка в процессе
            this.bStopping = true;
            //Сообщаем, что начала останов сервера
            await this.logger.warn("Останов сервера приложений...");
            //Останов обслуживания очереди исходящих
            await this.logger.warn("Останов обработчика очереди исходящих сообщений...");
            if (this.outQ) this.outQ.stopProcessing();
            else await this.onOutQStopped();
        }
    }
}

//------------------
//  Интерфейс модуля
//------------------

exports.ParusAppServer = ParusAppServer;
