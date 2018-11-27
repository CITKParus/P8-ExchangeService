/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: отработка очереди исходящих сообщений
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const _ = require("lodash"); //Работа с массивами и коллекциями
const EventEmitter = require("events"); //Обработчик пользовательских событий
const { checkObject } = require("../core/utils"); //Вспомогательные функции

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Типовые события
const SEVT_OUT_QUEUE_NEW = "OUT_QUEUE_NEW"; //Новое сообщение в очереди

//------------
// Тело модуля
//------------

//Класс очереди сообщений
class OutQueue extends EventEmitter {
    //конструктор класса
    constructor(prms, dbConn, logger) {
        //Создадим экземпляр родительского класса
        super();
        //Проверяем структуру переданного объекта с параметрами очереди
        let sCheckResult = checkObject(prms, {
            fields: [{ sName: "nPortionSize", bRequired: true }, { sName: "nCheckTimeout", bRequired: true }]
        });
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Хранилище очереди сообщений
            this.queue = [];
            //Признак функционирования обработчика
            this.bWorking = false;
            //Параметры очереди
            _.extend(this, prms);
            //Запомним подключение к БД
            this.dbConn = dbConn;
            //Запомним логгер
            this.logger = logger;
            //Привяжем методы к указателю на себя для использования в обработчиках событий
            this.outDetectingLoop = this.outDetectingLoop.bind(this);
        } else {
            throw new ServerError(
                glConst.SERR_OBJECT_BAD_INTERFACE,
                "Объект имеет недопустимый интерфейс: " + sCheckResult
            );
        }
    }
    //Добавление нового исходящего сообщения в очередь для отработки
    addMessage(message) {
        //Cоздадим новый элемент очереди
        let tmp = {};
        _.extend(tmp, message);
        //добавим его в очередь
        this.queue.push(tmp);
    }
    //Уведомление о получении нового сообщения
    notifyNewOutMessage(message) {
        //оповестим подписчиков о появлении нового отчета
        this.emit(SEVT_OUT_QUEUE_NEW, message);
    }
    //Перезапуск опроса очереди исходящих сообщений
    restartDetectingLoop() {
        if (this.bWorking)
            setTimeout(() => {
                this.outDetectingLoop();
            }, this.nCheckTimeout);
    }
    //Опрос очереди исходящих сообщений
    async outDetectingLoop() {
        //Сходим на сервер за очередным исходящим сообщением
        try {
            let outMsgs = await this.dbConn.getOutgoing({ nPortionSize: this.nPortionSize });
            if (Array.isArray(outMsgs) && outMsgs.length > 0) {
                let logAll = outMsgs.map(async msg => {
                    await this.logger.info(
                        "Новое исходящее сообщение: " +
                            msg.nId +
                            ", " +
                            msg.sInDate +
                            ", " +
                            msg.sServiceFnCode +
                            ", " +
                            msg.sExecState,
                        { nQueueId: msg.nId }
                    );
                });
                await Promise.all(logAll);
            } else {
                await this.logger.info("Нет новых сообщений");
            }
            this.restartDetectingLoop();
        } catch (e) {
            await this.logger.error("При получении исходящего сообщения: " + e.sCode + ": " + e.sMessage);
            this.restartDetectingLoop();
        }
    }
    //Запуск обработки очереди печати
    async startProcessing() {
        await this.logger.info("Запуск обработчика очереди исходящих сообщений...");
        this.bWorking = true;
        setTimeout(this.outDetectingLoop, 3000);
        await this.logger.info("Обработчик очереди исходящих сообщений запущен");
    }
    //Остановка обработки очереди печати
    async stopProcessing() {
        await this.logger.warn("Останов обработчика очереди исходящих сообщений...");
        this.bWorking = false;
        await this.logger.warn("Обработчик очереди исходящих сообщений остановлен");
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.SEVT_OUT_QUEUE_NEW = SEVT_OUT_QUEUE_NEW;
exports.OutQueue = OutQueue;
