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
    //Установка финальных статусов сообщения в БД
    async finalise(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.finalise,
            "Параметры функции установки финальных статусов сообщения в БД"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Если больше нет попыток исполнения и сообщение не в статусе успешной обработки сервером БД
            if (
                prms.queue.nExecState != objQueueSchema.NQUEUE_EXEC_STATE_DB_OK &&
                prms.queue.nExecCnt >= prms.queue.nRetryAttempts
            ) {
                //То считаем, что оно выполнено с ошибками и больше пытаться не надо
                await this.dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    sExecMsg: prms.queue.sExecMsg,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                });
            } else {
                //Если сообщение успешно исполнено сервером БД - то значит оно успешно исполнено вообще
                if (prms.queue.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_DB_OK) {
                    await this.dbConn.setQueueState({
                        nQueueId: prms.queue.nId,
                        nIncExecCnt: prms.queue.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_OK
                    });
                } else {
                    //Если сообщение в статусе исполнения сервером приложений (чего здесь быть не может) - это ошибка
                    if (prms.queue.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP) {
                        //То выставим ему ошибку исполнения сервером приложений
                        await this.dbConn.setQueueState({
                            nQueueId: prms.queue.nId,
                            sExecMsg: prms.queue.sExecMsg,
                            nIncExecCnt: prms.queue.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                        });
                    } else {
                        //Если сообщение в статусе исполнения сервером БД (чего здесь быть не может) - это ошибка
                        if (prms.queue.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_DB) {
                            //То выставим ему ошибку исполнения сервером БД
                            await this.dbConn.setQueueState({
                                nQueueId: prms.queue.nId,
                                sExecMsg: prms.queue.sExecMsg,
                                nIncExecCnt: prms.queue.nExecCnt == 0 ? NINC_EXEC_CNT_YES : NINC_EXEC_CNT_NO,
                                nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                            });
                        }
                    }
                }
            }
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Запуск обработки сообщения сервером БД
    async dbProcess(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsOutQueueSchema.dbProcess,
            "Параметры функции запуска обработки ообщения сервером БД"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Буфер для текущего состояния сообщения
            let curQueue = null;
            //Обрабатываем
            try {
                //Фиксируем начало исполнения сервером БД - в статусе сообщения
                curQueue = await this.dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB
                });
                //Вызов обработчика БД
                curQueue = await this.dbConn.execQueueDBPrc({ nQueueId: prms.queue.nId });
                //Фиксируем успешное исполнение сервером БД - в статусе сообщения
                curQueue = await this.dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB_OK
                });
                //Фиксируем успешное исполнение сервером БД - в протоколе работы сервиса
                await this.logger.info(`Исходящее сообщение ${prms.queue.nId} успешно отработано сервером БД`, {
                    nQueueId: prms.queue.nId
                });
            } catch (e) {
                //Сформируем текст ошибки
                let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                //Фиксируем ошибку обработки сервером БД - в статусе сообщения
                curQueue = await this.dbConn.setQueueState({
                    nQueueId: prms.queue.nId,
                    sExecMsg: sErr,
                    nIncExecCnt: NINC_EXEC_CNT_YES,
                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR
                });
                //Фиксируем ошибку обработки сервером БД - в протоколе работы сервиса
                await this.logger.error(
                    `Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером БД: ${sErr}`,
                    { nQueueId: prms.queue.nId }
                );
            }
            //Вернём текущее состоянии сообщения очереди
            return curQueue;
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Запуск обработки очередного сообщения
    async processMessage(prms) {
        //Проверяем структуру переданного объекта для старта
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
                //Скажем что начали обработку
                await self.logger.info(
                    `Обрабатываю исходящее сообщение: ${prms.queue.nId}, ${prms.queue.sInDate}, ${
                        prms.queue.sServiceFnCode
                    }, ${prms.queue.sExecState}, попытка исполнения - ${prms.queue.nExecCnt + 1}`,
                    { nQueueId: prms.queue.nId }
                );
                //Установим его статус в БД - обрабатывается сервером приложений (только для новых или повторно обрабатываемых сервером приложений)
                if (
                    prms.queue.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_INQUEUE ||
                    prms.queue.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
                ) {
                    curQueue = await self.dbConn.setQueueState({
                        nQueueId: prms.queue.nId,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP
                    });
                }
                //Установим его статус в БД - обрабатывается в БД (только если сюда пришло сообщение на повторную обработку сервером БД)
                if (prms.queue.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR) {
                    curQueue = await self.dbConn.setQueueState({
                        nQueueId: prms.queue.nId,
                        nExecState: objQueueSchema.NQUEUE_EXEC_STATE_DB
                    });
                }
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
                        //Движение события по статусам в зависимости от того в каком состоянии его вернул обработчик
                        try {
                            //Работаем от статуса сообщения полученного от обработчика
                            switch (result.nExecState) {
                                //Ошибка обработки
                                case objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR: {
                                    //Установим ошибочный статус в БД для сообщений и увеличим счетчик попыток отправки
                                    curQueue = await self.dbConn.setQueueState({
                                        nQueueId: prms.queue.nId,
                                        sExecMsg: result.sExecMsg,
                                        nIncExecCnt: NINC_EXEC_CNT_YES,
                                        nExecState: result.nExecState
                                    });
                                    //Фиксируем ошибку в протоколе работы сервиса
                                    await self.logger.error(
                                        `Ошибка обработки исходящего сообщения ${prms.queue.nId} сервером приложений: ${
                                            result.sExecMsg
                                        }`,
                                        { nQueueId: prms.queue.nId }
                                    );
                                    break;
                                }
                                //Успех обработки
                                case objQueueSchema.NQUEUE_EXEC_STATE_APP_OK: {
                                    //Если состояние менялось (а не просто повторная отработка)
                                    if (result.nExecState != prms.queue.nExecState) {
                                        //Пишем в базу успех отработки сервером приложений - результаты обработки
                                        curQueue = await self.dbConn.setQueueAppSrvResult({
                                            nQueueId: prms.queue.nId,
                                            blMsg: result.blMsg ? new Buffer(result.blMsg) : null,
                                            blResp: result.blResp ? new Buffer(result.blResp) : null
                                        });
                                        //Пишем в базу успех отработки сервером приложений - статус сообщения
                                        curQueue = await self.dbConn.setQueueState({
                                            nQueueId: prms.queue.nId,
                                            nExecState: result.nExecState
                                        });
                                        //Пишем в базу успех отработки сервером приложений - запись в протокол работы сервера приложений
                                        await self.logger.info(
                                            `Исходящее сообщение ${
                                                prms.queue.nId
                                            } успешно отработано сервером приложений`,
                                            { nQueueId: prms.queue.nId }
                                        );
                                    }
                                    //Запускаем обработку сервером БД
                                    curQueue = await self.dbProcess(prms);
                                    break;
                                }
                                //Обработчик ничего не делал
                                default: {
                                    //Обработчик ничего не делал, но если сообщение сообщение в статусе - ошибка обработки сервером БД или обрабатывается сервером БД, то запустим обработчик БД
                                    if (result.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_DB_ERR) {
                                        //Запускаем обработчик сервера БД
                                        curQueue = await self.dbProcess(prms);
                                    } else {
                                        //Во всех остальных случаях - ничего не делаем вообще
                                        curQueue = prms.queue;
                                    }
                                    break;
                                }
                            }
                        } catch (e) {
                            //Сформируем текст ошибки
                            let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                            if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                            //Фиксируем ошибку обработки сервером приложений - статус сообщения
                            curQueue = await self.dbConn.setQueueState({
                                nQueueId: prms.queue.nId,
                                sExecMsg: sErr,
                                nIncExecCnt: NINC_EXEC_CNT_YES
                            });
                            //Фиксируем ошибку обработки сервером приложений - запись в протокол работы сервера приложений
                            await self.logger.error(sErr, { nQueueId: prms.queue.nId });
                        }
                    } else {
                        //Пришел неожиданный ответ обработчика - статус сообщения
                        curQueue = await self.dbConn.setQueueState({
                            nQueueId: prms.queue.nId,
                            sExecMsg: sCheckResult,
                            nIncExecCnt: NINC_EXEC_CNT_YES
                        });
                        //Пришел неожиданный ответ обработчика - запись в протокол работы сервера приложений
                        await self.logger.error(
                            `Неожиданный ответ обработчика для сообщения ${prms.queue.nId}: ${sCheckResult}`,
                            { nQueueId: prms.queue.nId }
                        );
                    }
                    //Выставляем финальные статусы
                    try {
                        await self.finalise({ queue: curQueue });
                    } catch (e) {
                        //Сформируем текст ошибки
                        let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                        if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                        //Установим его статус в БД - ошибка установки финального статуса
                        await self.dbConn.setQueueState({
                            nQueueId: prms.queue.nId,
                            sExecMsg: sErr,
                            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                        });
                        //Пришел неожиданный ответ обработчика - запись в протокол работы сервера приложений
                        await self.logger.error(`Фатальная ошибка обработчика сообщения ${prms.queue.nId}: ${sErr}`, {
                            nQueueId: prms.queue.nId
                        });
                    }
                    //Останавливаем обработчик и инкрементируем флаг их доступного количества
                    proc.kill();
                    this.nWorkersLeft++;
                });
                //Перехват ошибок обработчика
                proc.on("error", async e => {
                    //Сформируем текст ошибки
                    let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                    if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                    //Установим его статус в БД - ошибка обработки сервером приложений
                    let curQueue = await self.dbConn.setQueueState({
                        nQueueId: prms.queue.nId,
                        sExecMsg: sErr,
                        nIncExecCnt: NINC_EXEC_CNT_YES
                    });
                    //Так же фиксируем ошибку в протоколе работы
                    await self.logger.error(`Ошибка обработки исходящего сообщения сервером приложений: ${sErr}`, {
                        nQueueId: prms.queue.nId
                    });
                    //Выставляем финальные статусы
                    try {
                        await self.finalise({ queue: curQueue });
                    } catch (e) {
                        //Сформируем текст ошибки
                        let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                        if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                        //Установим его статус в БД - ошибка установки финального статуса
                        await self.dbConn.setQueueState({
                            nQueueId: prms.queue.nId,
                            sExecMsg: sErr,
                            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                        });
                        //Пришел неожиданный ответ обработчика - запись в протокол работы сервера приложений
                        await self.logger.error(`Фатальная ошибка обработчика сообщения ${prms.queue.nId}: ${sErr}`, {
                            nQueueId: prms.queue.nId
                        });
                    }
                    //Останавливаем обработчик и инкрементируем флаг их доступного количества
                    proc.kill();
                    this.nWorkersLeft++;
                });
                //Перехват останова обработчика
                proc.on("exit", code => {});
                //Запускаем обработчик
                proc.send({
                    nQueueId: prms.queue.nId,
                    nExecState: prms.queue.nExecState,
                    blMsg: prms.queue.blMsg,
                    blResp: prms.queue.blResp,
                    service: _.find(this.services, { nId: prms.queue.nServiceId }),
                    function: _.find(_.find(this.services, { nId: prms.queue.nServiceId }).functions, {
                        nId: prms.queue.nServiceFnId
                    })
                });
                //Уменьшаем количество доступных обработчиков
                this.nWorkersLeft--;
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
                        try {
                            await this.processMessage({ queue: outMsgs[i] });
                        } catch (e) {
                            //Какие непредвиденные ошибки при обработке текущего сообщения - подготовим текст ошибки
                            let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                            if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                            //Фиксируем ошибку обработки сервером приложений - статус сообщения (сам статус - не меняем, здесь только фатальные ошибки, но делаем инкремент количества попыток)
                            let curQueue = await this.dbConn.setQueueState({
                                nQueueId: outMsgs[i].nId,
                                sExecMsg: sErr,
                                nIncExecCnt: NINC_EXEC_CNT_YES
                            });
                            //Фиксируем ошибку обработки сервером приложений - запись в протокол работы сервера приложений
                            await this.logger.error(sErr, { nQueueId: outMsgs[i].nId });
                            //Выставляем финальные статусы
                            try {
                                await this.finalise({ queue: curQueue });
                            } catch (e) {
                                //Сформируем текст ошибки
                                let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                                if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                                //Установим его статус в БД - ошибка установки финального статуса
                                await self.dbConn.setQueueState({
                                    nQueueId: outMsgs[i].nId,
                                    sExecMsg: sErr,
                                    nExecState: objQueueSchema.NQUEUE_EXEC_STATE_ERR
                                });
                                //Пришел неожиданный ответ обработчика - запись в протокол работы сервера приложений
                                await self.logger.error(
                                    `Фатальная ошибка обработчика сообщения ${outMsgs[i].nId}: ${sErr}`,
                                    { nQueueId: outMsgs[i].nId }
                                );
                            }
                        }
                    }
                }
                //Запустили отработку всех считанных - перезапускаем цикл опроса исходящих сообщений
                await this.restartDetectingLoop();
            } catch (e) {
                //Какие непредвиденные ошибки при получении списка сообщений - подготовим текст ошибки
                let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
                if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
                //Фиксируем ошибку в протоколе работы сервера приложений
                await this.logger.error(sErr);
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
