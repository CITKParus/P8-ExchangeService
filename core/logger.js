/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: протоколирование работы
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const db = require("../core/db_connector.js"); //Модуль взаимодействия с БД

//------------
// Тело модуля
//------------

//Типы сообщений протокола
const SLOGGER_MESSAGE_TYPE_ERROR = "ERROR"; // Ошибка
const SLOGGER_MESSAGE_TYPE_WARN = "WARN"; // Предупреждение
const SLOGGER_MESSAGE_TYPE_INFO = "INFO"; // Информация

//Сообщение протокола
class LoggerMessage {
    //Конструктор класса
    constructor(sType, sMessage, prms) {
        this.sType = sType;
        this.sMessage = sMessage;
        if (prms) {
            this.nServiceId = prms.nServiceId;
            this.nServiceFnId = prms.nServiceFnId;
            this.nQueueId = prms.nQueueId;
        }
    }
}

//Класс управления протоколом
class Logger {
    //Конструктор класса
    constructor() {
        this.dbConnector = "";
        this.bLogDB = false;
    }
    //Включение/выключение записи протоколов в БД
    setLogDB(bLogDB) {
        this.bLogDB = bLogDB;
    }
    //Установка объекта для протоколирования в БД
    setDBConnector(dbConnector) {
        if (dbConnector instanceof db.DBConnector) {
            this.dbConnector = dbConnector;
            this.bLogDB = true;
        }
    }
    //Удаление объекта для протоколирования в БД
    removeDBConnector() {
        this.dbConnector = "";
        this.bLogDB = false;
    }
    //Протоколирование в БД
    async logToDB(loggerMessage) {
        //Если надо протоколировать и есть чем
        if (this.bLogDB && this.dbConnector && this.dbConnector.bConnected) {
            //Если протоколируем стандартное сообщение
            if (loggerMessage instanceof LoggerMessage) {
                //Подготовим доп. сведения для протокола
                let logData = {};
                _.extend(logData, loggerMessage);
                //Анализируем тип сообщения
                switch (loggerMessage.sType) {
                    case SLOGGER_MESSAGE_TYPE_ERROR: {
                        await this.dbConnector.putLogErr(loggerMessage.sMessage, logData);
                        break;
                    }
                    case SLOGGER_MESSAGE_TYPE_WARN: {
                        await this.dbConnector.putLogWrn(loggerMessage.sMessage, logData);
                        break;
                    }
                    case SLOGGER_MESSAGE_TYPE_INFO: {
                        await this.dbConnector.putLogInf(loggerMessage.sMessage, logData);
                        break;
                    }
                    default:
                        await this.dbConnector.putLogInf(loggerMessage.sMessage, logData);
                        break;
                }
            } else {
                //Для нестандартных - есдиный способ протоколирования
                await this.dbConnector.putLogInf(loggerMessage);
            }
        }
    }
    //Протоколирование
    async log(loggerMessage) {
        let sMessage = "";
        let sPrefix = "LOG MESSAGE";
        let sColorPattern = "";
        //Конструируем сообщение
        if (loggerMessage instanceof LoggerMessage) {
            switch (loggerMessage.sType) {
                case SLOGGER_MESSAGE_TYPE_ERROR: {
                    sPrefix = "ERROR";
                    sColorPattern = "\x1b[31m%s\x1b[0m%s";
                    break;
                }
                case SLOGGER_MESSAGE_TYPE_WARN: {
                    sPrefix = "WARNING";
                    sColorPattern = "\x1b[33m%s\x1b[0m%s";
                    break;
                }
                case SLOGGER_MESSAGE_TYPE_INFO: {
                    sPrefix = "INFORMATION";
                    sColorPattern = "\x1b[32m%s\x1b[0m%s";
                    break;
                }
                default:
                    break;
            }
            sMessage = loggerMessage.sMessage;
        } else {
            sMessage = loggerMessage;
        }
        //Выдаём сообщение
        console.log(sColorPattern, sPrefix + ": ", sMessage);
        //Протоколируем в БД, если это необходимо
        if (this.bLogDB)
            try {
                await this.logToDB(loggerMessage);
            } catch (e) {
                console.log("LOGGER ERROR: " + e.sMessage);
            }
    }
    //Протоколирование ошибки
    async error(sMsg) {
        await this.log(new LoggerMessage(SLOGGER_MESSAGE_TYPE_ERROR, sMsg));
    }
    //Протоколирование предупреждения
    async warn(sMsg) {
        await this.log(new LoggerMessage(SLOGGER_MESSAGE_TYPE_WARN, sMsg));
    }
    //Протоколирование информации
    async info(sMsg) {
        await this.log(new LoggerMessage(SLOGGER_MESSAGE_TYPE_INFO, sMsg));
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.SLOGGER_MESSAGE_TYPE_ERROR = SLOGGER_MESSAGE_TYPE_ERROR;
exports.SLOGGER_MESSAGE_TYPE_WARN = SLOGGER_MESSAGE_TYPE_WARN;
exports.SLOGGER_MESSAGE_TYPE_INFO = SLOGGER_MESSAGE_TYPE_INFO;
exports.LoggerMessage = LoggerMessage;
exports.Logger = Logger;
