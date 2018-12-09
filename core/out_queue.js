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
const { SERR_OBJECT_BAD_INTERFACE } = require("./constants"); //Общесистемные константы
const { makeErrorText, validateObject } = require("./utils"); //Вспомогательные функции
const { NINC_EXEC_CNT_YES } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД
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
            //Список обслуживаемых сервисов
            this.services = null;
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
            //Список обрабатываемых в текущий момент сообщений очереди
            this.inProgress = [];
            //Привяжем методы к указателю на себя для использования в обработчиках событий
            this.outDetectingLoop = this.outDetectingLoop.bind(this);
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Уведомление о запуске обработчика очереди
    notifyStarted() {
        //Оповестим подписчиков о запуске
        this.emit(SEVT_OUT_QUEUE_STARTED);
    }
    //Уведомление об остановке обработчика очереди
    notifyStopped() {
        //Оповестим подписчиков об останове
        this.emit(SEVT_OUT_QUEUE_STOPPED);
    }
    //Добавление идентификатора позиции очереди в список обрабатываемых
    addInProgress(prms) {
        //Проверяем структуру переданного объекта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.addInProgress,
            "Параметры функции добавления идентификатора позиции очереди в список обрабатываемых"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Проверим, что такого идентификатора ещё нет в списке обрабатываемых
            const i = this.inProgress.indexOf(prms.nQueueId);
            //Если нет - добавим
            if (i === -1) this.inProgress.push(prms.nQueueId);
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Удаление идентификатора позиции очереди из списка обрабатываемых
    rmInProgress(prms) {
        //Проверяем структуру переданного объекта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.rmInProgress,
            "Параметры функции удаления идентификатора позиции очереди из списка обрабатываемых"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Если удаляемый идентификатор есть в списке
            const i = this.inProgress.indexOf(prms.nQueueId);
            //Удалим его
            if (i > -1) {
                this.inProgress.splice(i, 1);
            }
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Проверка наличия идентификатора позиции очереди в списке обрабатываемых
    isInProgress(prms) {
        //Проверяем структуру переданного объекта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.isInProgress,
            "Параметры функции проверки наличия идентификатора позиции очереди в списке обрабатываемых"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Проверим наличие идентификатора в списке
            return !(this.inProgress.indexOf(prms.nQueueId) === -1);
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Старт обработчика
    startQueueProcessor(prms) {
        //Проверяем структуру переданного объекта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.startQueueProcessor,
            "Параметры функции запуска обработчика сообщения очереди"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Добавляем идентификатор позиции очереди в список обрабатываемых
            this.addInProgress({ nQueueId: prms.queue.nId });
            //Отдаём команду дочернему процессу обработчика на старт исполнения
            prms.proc.send({
                nQueueId: prms.queue.nId,
                connectSettings: this.dbConn.connectSettings,
                service: _.find(this.services, { nId: prms.queue.nServiceId }),
                function: _.find(_.find(this.services, { nId: prms.queue.nServiceId }).functions, {
                    nId: prms.queue.nServiceFnId
                })
            });
            //Уменьшаем количество доступных обработчиков
            this.nWorkersLeft--;
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Останов обработчика
    stopQueueProcessor(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.stopQueueProcessor,
            "Параметры функции останова обработчика сообщения очереди"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Удаляем идентификатор позиции очереди из списка обрабатываемых
            this.rmInProgress({ nQueueId: prms.nQueueId });
            //Завершаем дочерний процесс обработчика
            prms.proc.kill();
            //Увеличиваем количество доступных обработчиков
            this.nWorkersLeft++;
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Запуск обработки очередного сообщения
    processMessage(prms) {
        //Проверяем структуру переданного объекта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.processMessage,
            "Параметры функции запуска обработки очередного сообщения"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Проверим, что есть доступные обработчики
            if (this.nWorkersLeft > 0) {
                //Переопределим себя для обращения внутри обработчиков событий
                const self = this;
                //Создаём новый обработчик сообщений
                const proc = ChildProcess.fork("core/out_queue_processor", { silent: false });
                //Текущее состояние сообщения
                let curQueue = null;
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
                        if (result.sResult == "ERR") {
                            //Фиксируем ошибку обработки - протокол работы сервиса
                            await self.logger.error(`Ошибка обработки исходящего сообщения: ${result.sMsg}`, {
                                nQueueId: prms.queue.nId
                            });
                            //Фиксируем ошибку обработки - статус сообщения
                            await this.dbConn.setQueueState({
                                nQueueId: prms.queue.nId,
                                sExecMsg: result.sMsg,
                                nIncExecCnt: NINC_EXEC_CNT_YES,
                                nExecState:
                                    prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                                        ? prms.queue.nExecState
                                        : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                            });
                        }
                    } else {
                        //Пришел неожиданный ответ обработчика - запись в протокол работы сервиса
                        await self.logger.error(
                            `Неожиданный ответ обработчика для сообщения ${prms.queue.nId}: ${sCheckResult}`,
                            { nQueueId: prms.queue.nId }
                        );
                        //Фиксируем ошибку обработки - статус сообщения
                        await this.dbConn.setQueueState({
                            nQueueId: prms.queue.nId,
                            sExecMsg: `Неожиданный ответ обработчика для сообщения ${prms.queue.nId}: ${sCheckResult}`,
                            nIncExecCnt: NINC_EXEC_CNT_YES,
                            nExecState:
                                prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                                    ? prms.queue.nExecState
                                    : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                        });
                    }
                    //Останавливаем обработчик и инкрементируем флаг их доступного количества
                    try {
                        this.stopQueueProcessor({ nQueueId: prms.queue.nId, proc });
                    } catch (e) {
                        //Отразим в протоколе ошибку останова
                        await self.logger.error(
                            `Ошибка останова обработчика исходящего сообщения: ${makeErrorText(e)}`,
                            { nQueueId: prms.queue.nId }
                        );
                    }
                });
                //Перехват ошибок обработчика
                proc.on("error", async e => {
                    //Фиксируем ошибку в протоколе работы
                    await self.logger.error(`Ошибка обработки исходящего сообщения: ${makeErrorText(e)}`, {
                        nQueueId: prms.queue.nId
                    });
                    //Фиксируем ошибку обработки - статус сообщения
                    await this.dbConn.setQueueState({
                        nQueueId: prms.queue.nId,
                        sExecMsg: makeErrorText(e),
                        nIncExecCnt: NINC_EXEC_CNT_YES,
                        nExecState:
                            prms.queue.nExecCnt + 1 < prms.queue.nRetryAttempts
                                ? prms.queue.nExecState
                                : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                    });
                    //Останавливаем обработчик и инкрементируем флаг их доступного количества
                    try {
                        this.stopQueueProcessor({ nQueueId: prms.queue.nId, proc });
                    } catch (e) {
                        //Отразим в протоколе ошибку останова
                        await self.logger.error(
                            `Ошибка останова обработчика исходящего сообщения: ${makeErrorText(e)}`,
                            { nQueueId: prms.queue.nId }
                        );
                    }
                });
                //Перехват останова обработчика
                proc.on("exit", code => {});
                //Запускаем обработчик
                this.startQueueProcessor({ queue: prms.queue, proc });
            }
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Перезапуск опроса очереди исходящих сообщений
    async restartDetectingLoop() {
        //Включаем опрос очереди только если установлен флаг работы
        if (this.bWorking) {
            this.nDetectingLoopTimeOut = await setTimeout(async () => {
                await this.outDetectingLoop();
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
                    //Обходим их
                    for (let i = 0; i < outMsgs.length; i++) {
                        //И запускаем обработчики
                        if (!this.isInProgress({ nQueueId: outMsgs[i].nId })) {
                            try {
                                this.processMessage({ queue: outMsgs[i] });
                            } catch (e) {
                                //Фиксируем ошибку обработки сервером приложений - статус сообщения
                                await this.dbConn.setQueueState({
                                    nQueueId: outMsgs[i].nId,
                                    sExecMsg: makeErrorText(e),
                                    nIncExecCnt: NINC_EXEC_CNT_YES,
                                    nExecState:
                                        outMsgs[i].nExecCnt + 1 < outMsgs[i].nRetryAttempts
                                            ? outMsgs[i].nExecState
                                            : objQueueSchema.NQUEUE_EXEC_STATE_ERR
                                });
                                //Фиксируем ошибку обработки сервером приложений - запись в протокол работы сервера приложений
                                await this.logger.error(makeErrorText(e), { nQueueId: outMsgs[i].nId });
                            }
                        }
                    }
                }
                //Запустили отработку всех считанных - перезапускаем цикл опроса исходящих сообщений
                await this.restartDetectingLoop();
            } catch (e) {
                //Фиксируем ошибку в протоколе работы сервера приложений
                await this.logger.error(makeErrorText(e));
                await this.restartDetectingLoop();
            }
        } else {
            //Нет свободных обработчиков - ждём и перезапускаем цикл опроса
            await this.restartDetectingLoop();
        }
    }
    //Запуск обработки очереди исходящих сообщений
    startProcessing(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.startProcessing,
            "Параметры функции запуска обработки очереди исходящих сообщений"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Выставляем флаг работы
            this.bWorking = true;
            //запоминаем список обслуживаемых сервисов
            this.services = prms.services;
            //Начинаем слушать очередь исходящих
            setTimeout(this.outDetectingLoop, NDETECTING_LOOP_DELAY);
            //И оповещаем всех что запустились
            this.notifyStarted();
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
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
