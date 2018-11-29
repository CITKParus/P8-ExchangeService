/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: отработка очереди исходящих сообщений
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const _ = require("lodash"); //Работа с массивами и коллекциями
const EventEmitter = require("events"); //Обработчик пользовательских событий
const ChildProcess = require("child_process"); //Работа с дочерними процессами
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { SERR_UNEXPECTED, SERR_OBJECT_BAD_INTERFACE } = require("./constants"); //Общесистемные константы
const { validateObject } = require("./utils"); //Вспомогательные функции
const { NINC_EXEC_CNT_YES, NINC_EXEC_CNT_NO } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД
const objOutQueueProcessorSchema = require("../models/obj_out_queue_processor"); //Схемы валидации сообщений обмена с обработчиком сообщения очереди
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const prmsOutQueueSchema = require("../models/prms_out_queue"); //Схемы валидации параметров функций класса

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Типовые события
const SEVT_OUT_QUEUE_STARTED = "OUT_QUEUE_STARTED"; //Обработчик очереди запущен
const SEVT_OUT_QUEUE_STOPPED = "OUT_QUEUE_STOPPED"; //Обработчик очереди остановлен

//Время отложенного старта опроса очереди (мс)
const NDETECTING_LOOP_DELAY = 3000;

//Интервал проверки завершения обработчиков (мс)
const NWORKERS_WAIT_INTERVAL = 1000;

//------------
// Тело модуля
//------------

//Класс очереди сообщений
class OutQueue extends EventEmitter {
    //Конструктор класса
    constructor(prms) {
        //Создадим экземпляр родительского класса
        super();
        //Проверяем структуру переданного объекта для подключения
        let sCheckResult = validateObject(prms, prmsOutQueueSchema.OutQueue, "Параметры конструктора класса OutQueue");
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Признак функционирования обработчика
            this.bWorking = false;
            //Параметры очереди
            this.outGoing = _.cloneDeep(prms.outGoing);
            //Количество доступных обработчиков
            this.nWorkersLeft = this.outGoing.nMaxWorkers;
            //Идентификатор таймера проверки очереди
            this.nDetectingLoopTimeOut = null;
            //Запомним подключение к БД
            this.dbConn = prms.dbConn;
            //Запомним логгер
            this.logger = prms.logger;
            //Привяжем методы к указателю на себя для использования в обработчиках событий
            this.outDetectingLoop = this.outDetectingLoop.bind(this);
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Уведомление об остановке обработчика очереди
    notifyStarted() {
        //оповестим подписчиков о появлении нового отчета
        this.emit(SEVT_OUT_QUEUE_STARTED);
    }
    //Уведомление об остановке обработчика очереди
    notifyStopped() {
        //оповестим подписчиков о появлении нового отчета
        this.emit(SEVT_OUT_QUEUE_STOPPED);
    }
    //Останов обработчика сообщения
    stopMessageWorker(worker) {
        worker.kill();
        this.nWorkersLeft++;
    }
    //Запуск обработчки очередного сообщения
    processMessage(message) {
        //Проверим, что есть доступные обработчики
        if (this.nWorkersLeft > 0) {
            //Переопределим себя для обращения внутри обработчиков событий
            const self = this;
            //Создаём новый обработчик сообщений
            const proc = ChildProcess.fork("core/out_queue_processor", { silent: false });
            //Перехват сообщений обработчика
            proc.on("message", async result => {
                //Проверяем структуру полученного сообщения
                let sCheckResult = validateObject(
                    result,
                    objOutQueueProcessorSchema.OutQueueProcessorTaskResult,
                    "Ответ обработчика очереди исходящих сообщений"
                );
                //Если структура сообщения в норме
                if (!sCheckResult) {
                    //Если обработчик вернул ошибку
                    if (result.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR) {
                        //Установим ошибочный статус в БД для сообщений и увеличим счетчик попыток отправки
                        console.log("ЖДЕМ ЗАПИСЬ В БД111");
                        await self.dbConn.setQueueState({
                            nQueueId: message.nId,
                            sExecMsg: result.sExecMsg,
                            nIncExecCnt: NINC_EXEC_CNT_YES,
                            nExecState: result.nExecState
                        });
                        //Фиксируем ошибку в протоколе работы сервиса
                        await self.logger.error(
                            "Ошибка обработки исходящего сообщения сервером приложений: " + result.sExecMsg,
                            {
                                nQueueId: message.nId
                            }
                        );
                        console.log("ДОЖДАЛИСЬ111");
                    } else {
                        //Пишем в базу успех
                        console.log("ЖДЕМ ЗАПИСЬ В БД222");
                        await self.dbConn.setQueueState({
                            nQueueId: message.nId,
                            sExecMsg: result.sExecMsg,
                            nIncExecCnt: NINC_EXEC_CNT_YES,
                            nExecState: result.nExecState
                        });
                        //Фиксируем успех в протоколе работы сервиса
                        await self.logger.info("Исходящее сообщение успешно отработано сервером приложений", {
                            nQueueId: message.nId
                        });
                        console.log("ДОЖДАЛИСЬ222");
                    }
                } else {
                    //Пришел неожиданный ответ обработчика, установим статус в БД - ошибка обработки сервером приложений
                    console.log("ЖДЕМ ЗАПИСЬ В БД");
                    await self.dbConn.setQueueState({
                        nQueueId: message.nId,
                        sExecMsg: sCheckResult,
                        nIncExecCnt: NINC_EXEC_CNT_YES,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                    });
                    //Фиксируем ошибку в протоколе работы сервиса
                    await self.logger.error(
                        "Ошибка обработки исходящего сообщения сервером приложений: " + sCheckResult,
                        {
                            nQueueId: message.nId
                        }
                    );
                    console.log("ДОЖДАЛИСЬ");
                }
                console.log("ОСТАНОВ ОБРАБОТЧИКА");
                self.stopMessageWorker(proc);
            });
            //Перехват ошибок обработчика
            proc.on("error", async e => {
                //Установим его статус в БД - ошибка обработки сервером приложений
                await self.dbConn.setQueueState({
                    nQueueId: message.nId,
                    sExecMsg: e.message,
                    nIncExecCnt: NINC_EXEC_CNT_YES,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                });
                //Так же фиксируем ошибку в протоколе работы
                await self.logger.error("Ошибка обработки исходящего сообщения сервером приложений: " + e.message, {
                    nQueueId: message.nId
                });
                //Завершим обработчик
                self.stopMessageWorker(proc);
            });
            //Перехват останова обработчика
            proc.on("exit", code => {});
            //Запускаем обработчик
            proc.send({
                queue: message,
                service: {}
            });
            //Уменьшаем количество доступных обработчиков
            this.nWorkersLeft--;
            //Вернем признак того, что сообщение обрабатывается
            return true;
        } else {
            //Вернем признак того, что сообщение не обрабатывается
            return false;
        }
    }
    //Перезапуск опроса очереди исходящих сообщений
    restartDetectingLoop() {
        //Включаем опрос очереди только если установлен флаг работы
        if (this.bWorking) {
            this.nDetectingLoopTimeOut = setTimeout(() => {
                this.outDetectingLoop();
            }, this.outGoing.nCheckTimeout);
        }
    }
    //Опрос очереди исходящих сообщений
    async outDetectingLoop() {
        //Если есть свободные обработчики
        if (this.nWorkersLeft > 0) {
            //Сходим на сервер за очередным исходящим сообщением
            try {
                //Заберем столько сообщений, сколько можем обработать одновременно
                let outMsgs = await this.dbConn.getOutgoing({ nPortionSize: this.nWorkersLeft });
                //Если есть сообщения
                if (Array.isArray(outMsgs) && outMsgs.length > 0) {
                    //Ставим их в очередь
                    for (let i = 0; i < outMsgs.length; i++) {
                        //Если сообщение успешно взято в обработку
                        if (this.processMessage(outMsgs[i])) {
                            //Скажем что оно у нас есть
                            await this.logger.info(
                                "Новое исходящее сообщение: " +
                                    outMsgs[i].nId +
                                    ", " +
                                    outMsgs[i].sInDate +
                                    ", " +
                                    outMsgs[i].sServiceFnCode +
                                    ", " +
                                    outMsgs[i].sExecState +
                                    ", " +
                                    outMsgs[i].nExecCnt,
                                { nQueueId: outMsgs[i].nId }
                            );
                            //Установим его статус в БД - обрабатывается сервером приложений
                            await this.dbConn.setQueueState({
                                nQueueId: outMsgs[i].nId,
                                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP
                            });
                        }
                    }
                } else {
                    await this.logger.info("Нет новых сообщений");
                }
                this.restartDetectingLoop();
            } catch (e) {
                if (e instanceof ServerError)
                    await this.logger.error("При получении исходящего сообщения: " + e.sCode + ": " + e.sMessage);
                else this.logger.error(SERR_UNEXPECTED + ": " + e.message);
                this.restartDetectingLoop();
            }
        } else {
            await this.logger.info("Нет свободных обработчиков");
            this.restartDetectingLoop();
        }
    }
    //Запуск обработки очереди исходящих сообщений
    startProcessing() {
        //Выставляем флаг работы
        this.bWorking = true;
        setTimeout(this.outDetectingLoop, NDETECTING_LOOP_DELAY);
        this.notifyStarted();
    }
    //Остановка обработки очереди исходящих сообщений
    stopProcessing() {
        //Выставляем флаг неработы
        this.bWorking = false;
        //Останавливаем опрос очереди
        if (this.nDetectingLoopTimeOut) {
            clearTimeout(this.nDetectingLoopTimeOut);
            this.nDetectingLoopTimeOut = null;
        }
        //Ждем завершения работы всех обработчиков
        let i = setInterval(() => {
            console.log(this.bWorking + " " + this.nWorkersLeft + " " + this.outGoing.nMaxWorkers);
            if (!this.bWorking && this.nWorkersLeft == this.outGoing.nMaxWorkers) {
                clearInterval(i);
                this.notifyStopped();
            }
        }, NWORKERS_WAIT_INTERVAL);
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.SEVT_OUT_QUEUE_STARTED = SEVT_OUT_QUEUE_STARTED;
exports.SEVT_OUT_QUEUE_STOPPED = SEVT_OUT_QUEUE_STOPPED;
exports.OutQueue = OutQueue;
