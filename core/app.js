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
const iq = require("./in_queue"); //Прослушивание очереди входящих сообщений
const sac = require("./service_available_controller"); //Контроль доступности удалённых сервисов
const ntf = require("./notifier"); //Отправка уведомлений
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { makeErrorText, validateObject, getIPs } = require("./utils"); //Вспомогательные функции
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
        //Обработчик очереди входящих
        this.inQ = null;
        //Контроллер доступности удалённых сервисов
        this.srvAvlCtrl = null;
        //Модуль отправки уведомлений
        this.notifier = null;
        //Флаг остановки сервера
        this.bStopping = false;
        //Таймаут останова сервера
        this.terminateTimeout = null;
        //Список обслуживаемых сервисов
        this.services = [];
        //Привяжем методы к указателю на себя для использования в обработчиках событий
        this.onDBConnected = this.onDBConnected.bind(this);
        this.onDBDisconnected = this.onDBDisconnected.bind(this);
        this.onOutQStarted = this.onOutQStarted.bind(this);
        this.onOutQStopped = this.onOutQStopped.bind(this);
        this.onInQStarted = this.onInQStarted.bind(this);
        this.onInQStopped = this.onInQStopped.bind(this);
        this.onNotifierStarted = this.onNotifierStarted.bind(this);
        this.onNotifierStopped = this.onNotifierStopped.bind(this);
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
        //Запускаем обслуживание очереди входящих
        await this.logger.info("Запуск обработчика очереди входящих сообщений...");
        try {
            this.inQ.startProcessing({ services: this.services });
        } catch (e) {
            await this.logger.error(`Ошибка запуска обработчика очереди входящих сообщений: ${makeErrorText(e)}`);
            await this.stop();
            return;
        }
    }
    //При останове обработчика исходящих сообщений
    async onOutQStopped() {
        //Сообщим, что остановили обработчик
        await this.logger.warn("Обработчик очереди исходящих сообщений остановлен");
        //Останавливаем очередь обработки входящих
        await this.logger.warn("Останов обработчика очереди входящих сообщений...");
        if (this.inQ) this.inQ.stopProcessing();
        else await this.onInQStopped();
    }
    //При запуске обработчика входящих сообщений
    async onInQStarted(nPort, sHost) {
        //Сообщим, что запустили обработчик
        await this.logger.info(
            `Обработчик очереди входящих сообщений запущен (порт - ${nPort}, доступные IP - ${sHost === "0.0.0.0" ? getIPs().join("; ") : sHost})`
        );
        //Запускаем модуль отправки уведомлений
        await this.logger.info("Запуск модуля отправки уведомлений...");
        try {
            this.notifier.startNotifier();
        } catch (e) {
            await this.logger.error(`Ошибка запуска модуля отправки уведомлений: ${makeErrorText(e)}`);
            await this.stop();
            return;
        }
    }
    //При останове обработчика входящих сообщений
    async onInQStopped() {
        //Сообщим, что остановили обработчик
        await this.logger.warn("Обработчик очереди входящих сообщений остановлен");
        //Останавливаем модуль отправки уведомлений
        await this.logger.warn("Останов модуля отправки уведомлений...");
        if (this.notifier) this.notifier.stopNotifier();
        else await this.onNotifierStopped();
    }
    //При запуске модуля отправки уведомлений
    async onNotifierStarted() {
        //Сообщим, что запустили модуль
        await this.logger.info(`Модуль отправки уведомлений запущен`);
        //Запускаем контроллер доступности удалённых сервисов
        await this.logger.info("Запуск контроллера доступности удалённых сервисов...");
        try {
            this.srvAvlCtrl.startController({ services: this.services });
        } catch (e) {
            await this.logger.error(`Ошибка запуска контроллера доступности удалённых сервисов: ${makeErrorText(e)}`);
            await this.stop();
            return;
        }
    }
    //При останове модуля отправки уведомлений
    async onNotifierStopped() {
        //Сообщим, что остановили модуль
        await this.logger.warn("Модуль отправки уведомлений остановлен");
        //Останавливаем контроллер доступности удалённных сервисов
        await this.logger.warn("Останов контроллера доступности удалённых сервисов...");
        if (this.srvAvlCtrl) this.srvAvlCtrl.stopController();
        else await this.onServiceACStopped();
    }
    //При запуске контроллера доступности удаленных сервисов
    async onServiceACStarted() {
        //Сообщим, что запустили обработчик
        await this.logger.info("Контроллер доступности удалённых сервисов запущен");
        //Рапортуем, что запустились
        await this.logger.info("Сервер приложений запущен");
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
                } catch (e) {
                    await this.logger.error(`Ошибка отключения от БД: ${e.sCode}: ${e.sMessage}`);
                }
                //Мы закончили останов - сброс таймера аварийного останова, процесс завершится самостоятельно
                if (this.terminateTimeout) {
                    clearTimeout(this.terminateTimeout);
                }
            }
        }
    }
    //Инициализация сервера
    async init(prms) {
        await this.logger.info("Инициализация сервера приложений...");
        //Проверяем структуру переданного объекта конфигурации
        let sCheckResult = validateObject(prms, prmsAppSchema.init, "Параметры инициализации");
        //Если настройки верны - будем стартовать
        if (!sCheckResult) {
            //Протоколируем версию и релиз
            await this.logger.info(
                `Версия сервера приложений: ${prms.config.common.sVersion}, релиз: ${prms.config.common.sRelease}`
            );
            //Создаём подключение к БД
            this.dbConn = new db.DBConnector({
                connectSettings: {
                    ...prms.config.dbConnect,
                    sRelease: prms.config.common.sRelease,
                    bControlSystemVersion: prms.config.common.bControlSystemVersion,
                    nPoolMin: prms.config.inComing.nPoolMin,
                    nPoolMax: prms.config.inComing.nPoolMax,
                    nPoolIncrement: prms.config.inComing.nPoolIncrement,
                    nMaxWorkers: prms.config.outGoing.nMaxWorkers
                }
            });
            //Создаём модуль рассылки уведомлений
            this.notifier = new ntf.Notifier({ logger: this.logger, mail: prms.config.mail });
            //Создаём обработчик очереди исходящих
            this.outQ = new oq.OutQueue({
                outGoing: prms.config.outGoing,
                dbConn: this.dbConn,
                logger: this.logger,
                notifier: this.notifier,
                sProxy: prms.config.outGoing.sProxy
            });
            //Создаём обработчик очереди входящих
            this.inQ = new iq.InQueue({
                common: prms.config.common,
                inComing: prms.config.inComing,
                dbConn: this.dbConn,
                logger: this.logger,
                notifier: this.notifier
            });
            //Создаём контроллер доступности удалённых сервисов
            this.srvAvlCtrl = new sac.ServiceAvailableController({
                logger: this.logger,
                notifier: this.notifier,
                dbConn: this.dbConn,
                sProxy: prms.config.outGoing.sProxy
            });
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
        //Включим прослушивание событий обработчика входящих сообщений
        this.inQ.on(iq.SEVT_IN_QUEUE_STARTED, this.onInQStarted);
        this.inQ.on(iq.SEVT_IN_QUEUE_STOPPED, this.onInQStopped);
        //Включим прослушивание событий модуля рассылки уведомлений
        this.notifier.on(ntf.SEVT_NOTIFIER_STARTED, this.onNotifierStarted);
        this.notifier.on(ntf.SEVT_NOTIFIER_STOPPED, this.onNotifierStopped);
        //Включим прослушивание событий контроллера доступности удалённых сервисов
        this.srvAvlCtrl.on(sac.SEVT_SERVICE_AVAILABLE_CONTROLLER_STARTED, this.onServiceACStarted);
        this.srvAvlCtrl.on(sac.SEVT_SERVICE_AVAILABLE_CONTROLLER_STOPPED, this.onServiceACStopped);
        //Подключаемся к БД
        await this.logger.info("Подключение сервера приложений к БД...");
        await this.dbConn.connect();
    }
    //Останов сервера
    async stop(terminateTimeout) {
        if (!this.bStopping) {
            //Установим флаг - остановка в процессе
            this.bStopping = true;
            //Запомним таймер аварийного останова
            this.terminateTimeout = terminateTimeout;
            //Сообщаем, что начался останов сервера
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
