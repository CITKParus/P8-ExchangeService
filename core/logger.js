/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: протоколирование работы
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const { validateObject } = require("../core/utils"); //Вспомогательные функции
const db = require("./db_connector"); //Модуль взаимодействия с БД
const { NLOG_STATE_INF, NLOG_STATE_WRN, NLOG_STATE_ERR } = require("../models/obj_log"); //Схемы валидации записи журнала работы сервиса обмена
const prmsLoggerSchema = require("../models/prms_logger"); //Схемы валидации параметров функций модуля

//------------
// Тело модуля
//------------

//Класс управления протоколом
class Logger {
    //Конструктор класса
    constructor() {
        this.dbConnector = null;
        this.bLogDB = false;
    }
    //Включение/выключение записи протоколов в БД
    setLogDB(bLogDB) {
        if (this.dbConnector) this.bLogDB = bLogDB;
    }
    //Установка объекта для протоколирования в БД
    setDBConnector(dbConnector, bLogDB) {
        if (dbConnector instanceof db.DBConnector) {
            this.dbConnector = dbConnector;
            if (bLogDB === true) this.setLogDB(true);
            else this.setLogDB(false);
        }
    }
    //Удаление объекта для протоколирования в БД
    removeDBConnector() {
        this.dbConnector = null;
        this.setLogDB(false);
    }
    //Протоколирование
    async log(prms) {
        //Проверяем структуру переданного объекта для подключения
        let sCheckResult = validateObject(prms, prmsLoggerSchema.log, "Параметры функции протоколирования");
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Определим оформление сообщения
            let sPrefix = "ИНФОРМАЦИЯ";
            let sColorPattern = "";
            switch (prms.nLogState) {
                case NLOG_STATE_ERR: {
                    sPrefix = "ОШИБКА";
                    sColorPattern = "\x1b[31m%s\x1b[0m%s";
                    break;
                }
                case NLOG_STATE_WRN: {
                    sPrefix = "ПРЕДУПРЕЖДЕНИЕ";
                    sColorPattern = "\x1b[33m%s\x1b[0m%s";
                    break;
                }
                case NLOG_STATE_INF: {
                    sPrefix = "ИНФОРМАЦИЯ";
                    sColorPattern = "\x1b[32m%s\x1b[0m%s";
                    break;
                }
                default:
                    break;
            }
            //Выдаём сообщение
            console.log(sColorPattern, sPrefix + ": ", prms.sMsg);
            //Протоколируем в БД, если это необходимо
            if (this.bLogDB) {
                try {
                    //Если есть чем протоколировать
                    if (this.dbConnector && this.dbConnector.bConnected) {
                        await this.dbConnector.putLog(prms);
                    }
                } catch (e) {
                    console.log("\x1b[31m%s\x1b[0m%s", "ОШИБКА ПРОТОКОЛИРОВАНИЯ: ", e.sMessage);
                }
            }
        } else {
            console.log("\x1b[31m%s\x1b[0m%s", "ОШИБКА ПРОТОКОЛИРОВАНИЯ: ", sCheckResult);
            console.log(prms);
        }
    }
    //Протоколирование ошибки
    async error(sMsg, prms) {
        //Подготовим параметры для протоколирования
        let logData = {};
        if (prms) logData = _.cloneDeep(prms);
        //Выставим сообщение и тип записи журнала
        logData.nLogState = NLOG_STATE_ERR;
        logData.sMsg = sMsg;
        //Протоколируем
        await this.log(logData);
    }
    //Протоколирование предупреждения
    async warn(sMsg, prms) {
        //Подготовим параметры для протоколирования
        let logData = {};
        if (prms) logData = _.cloneDeep(prms);
        //Выставим сообщение и тип записи журнала
        logData.nLogState = NLOG_STATE_WRN;
        logData.sMsg = sMsg;
        //Протоколируем
        await this.log(logData);
    }
    //Протоколирование информации
    async info(sMsg, prms) {
        //Подготовим параметры для протоколирования
        let logData = {};
        if (prms) logData = _.cloneDeep(prms);
        //Выставим сообщение и тип записи журнала
        logData.nLogState = NLOG_STATE_INF;
        logData.sMsg = sMsg;
        //Протоколируем
        await this.log(logData);
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.Logger = Logger;
