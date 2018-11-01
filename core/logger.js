/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: протоколирование работы
*/

//------------
// Тело модуля
//------------

//Тип сообщения протокола - ошибка
const LOGGER_MESSAGE_TYPE_ERROR = "ERROR";

//Тип сообщения протокола - предупреждение
const LOGGER_MESSAGE_TYPE_WARN = "WARN";

//Тип сообщения протокола - информация
const LOGGER_MESSAGE_TYPE_INFO = "INFO";

//Сообщение протокола
class LoggerMessage {
    //Конструктор класса
    constructor(type, message) {
        this.type = type;
        this.message = message;
    }
}

//Класс управления протоколом
class Logger {
    //Конструктор класса
    constructor() {}
    //Протоколирование ошибки
    error(msg) {
        this.log(new LoggerMessage(LOGGER_MESSAGE_TYPE_ERROR, msg));
    }
    //Протоколирование предупреждения
    warn(msg) {
        this.log(new LoggerMessage(LOGGER_MESSAGE_TYPE_WARN, msg));
    }
    //Протоколирование информации
    info(msg) {
        this.log(new LoggerMessage(LOGGER_MESSAGE_TYPE_INFO, msg));
    }
    //Протоколирование
    log(loggerMessage) {
        let message = "";
        let prefix = "LOG MESSAGE";
        let colorPattern = "";
        //Конструируем сообщение
        if (loggerMessage instanceof LoggerMessage) {
            switch (loggerMessage.type) {
                case LOGGER_MESSAGE_TYPE_ERROR: {
                    prefix = "ERROR";
                    colorPattern = "\x1b[31m%s\x1b[0m%s";
                    break;
                }
                case LOGGER_MESSAGE_TYPE_WARN: {
                    prefix = "WARNING";
                    colorPattern = "\x1b[33m%s\x1b[0m%s";
                    break;
                }
                case LOGGER_MESSAGE_TYPE_INFO: {
                    prefix = "INFORMATION";
                    colorPattern = "\x1b[32m%s\x1b[0m%s";
                    break;
                }
                default:
                    break;
            }
            message = loggerMessage.message;
        } else {
            message = loggerMessage;
        }
        //Выдаём сообщение
        console.log(colorPattern, prefix + ": ", message);
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.LOGGER_MESSAGE_TYPE_ERROR = LOGGER_MESSAGE_TYPE_ERROR;
exports.LOGGER_MESSAGE_TYPE_WARN = LOGGER_MESSAGE_TYPE_WARN;
exports.LOGGER_MESSAGE_TYPE_INFO = LOGGER_MESSAGE_TYPE_INFO;
exports.LoggerMessage = LoggerMessage;
exports.Logger = Logger;
