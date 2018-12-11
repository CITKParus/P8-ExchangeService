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
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { SERR_OBJECT_BAD_INTERFACE } = require("./constants"); //Общесистемные константы
const { makeErrorText, validateObject } = require("./utils"); //Вспомогательные функции
const { NINC_EXEC_CNT_YES } = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля взаимодействия с БД
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
        this.emit(SEVT_IN_QUEUE_STARTED);
    }
    //Уведомление об остановке обработчика очереди
    notifyStopped() {
        //Оповестим подписчиков об останове
        this.emit(SEVT_IN_QUEUE_STOPPED);
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
            //Запускаем сервер
            this.webApp.use("*", (req, res) => {
                res.status(200).send("<html><body><center><h1>Сервер приложений ПП Пурс 8</h1></center></body></html>");
            });
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! КОНТРОЛЬ ЗАПУСКА!!!!!!!!!!!!!!
            this.srv = this.webApp.listen(this.inComing.nPort, () => {
                //И оповещаем всех что запустились
                this.notifyStarted();
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
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! КОНТРОЛЬ ОСТАНОВА!!!!!!!!!!!!!!
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
