/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель функции сервиса
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//----------
// Константы
//----------

//Типы функций сервиса
const NFN_TYPE_DATA = 0; //Обмен данными
const NFN_TYPE_LOGIN = 1; //Начало сеанса
const NFN_TYPE_LOGOUT = 2; //Завершение сеанса
const SFN_TYPE_DATA = "DATA"; //Обмен данными (строковый код)
const SFN_TYPE_LOGIN = "LOGIN"; //Начало сеанса (строковый код)
const SFN_TYPE_LOGOUT = "LOGOUT"; //Завершение сеанса (строковый код)

//Способы передачи параметров функциям сервиса
const NFN_PRMS_TYPE_POST = 0; //POST-запрос
const NFN_PRMS_TYPE_GET = 1; //GET-запрос
const SFN_PRMS_TYPE_POST = "POST"; //POST-запрос
const SFN_PRMS_TYPE_GET = "GET"; //GET-запрос

//Расписание повторного исполнения функции
const NRETRY_SCHEDULE_UNDEF = 0; //Не определено
const NRETRY_SCHEDULE_SEC = 1; //Секунда
const NRETRY_SCHEDULE_MIN = 2; //Минута
const NRETRY_SCHEDULE_HOUR = 3; //Час
const NRETRY_SCHEDULE_DAY = 4; //Сутки
const NRETRY_SCHEDULE_WEEK = 5; //Неделя
const NRETRY_SCHEDULE_MONTH = 6; //Месяц
const SRETRY_SCHEDULE_UNDEF = "UNDEFINED"; //Не определено (строковый код)
const SRETRY_SCHEDULE_SEC = "SEC"; //Секунда (строковый код)
const SRETRY_SCHEDULE_MIN = "MIN"; //Минута (строковый код)
const SRETRY_SCHEDULE_HOUR = "HOUR"; //Час (строковый код)
const SRETRY_SCHEDULE_DAY = "DAY"; //Сутки (строковый код)
const SRETRY_SCHEDULE_WEEK = "WEEK"; //Неделя (строковый код)
const SRETRY_SCHEDULE_MONTH = "MONTH"; //Месяц (строковый код)

//------------------
//  Интерфейс модуля
//------------------

//Константы
exports.NFN_TYPE_DATA = NFN_TYPE_DATA;
exports.NFN_TYPE_LOGIN = NFN_TYPE_LOGIN;
exports.NFN_TYPE_LOGOUT = NFN_TYPE_LOGOUT;
exports.SFN_TYPE_DATA = SFN_TYPE_DATA;
exports.SFN_TYPE_LOGIN = SFN_TYPE_LOGIN;
exports.SFN_TYPE_LOGOUT = SFN_TYPE_LOGOUT;
exports.NFN_PRMS_TYPE_POST = NFN_PRMS_TYPE_POST;
exports.NFN_PRMS_TYPE_GET = NFN_PRMS_TYPE_GET;
exports.SFN_PRMS_TYPE_POST = SFN_PRMS_TYPE_POST;
exports.SFN_PRMS_TYPE_GET = SFN_PRMS_TYPE_GET;
exports.NRETRY_SCHEDULE_UNDEF = NRETRY_SCHEDULE_UNDEF;
exports.NRETRY_SCHEDULE_SEC = NRETRY_SCHEDULE_SEC;
exports.NRETRY_SCHEDULE_MIN = NRETRY_SCHEDULE_MIN;
exports.NRETRY_SCHEDULE_HOUR = NRETRY_SCHEDULE_HOUR;
exports.NRETRY_SCHEDULE_DAY = NRETRY_SCHEDULE_DAY;
exports.NRETRY_SCHEDULE_WEEK = NRETRY_SCHEDULE_WEEK;
exports.NRETRY_SCHEDULE_MONTH = NRETRY_SCHEDULE_MONTH;
exports.SRETRY_SCHEDULE_UNDEF = SRETRY_SCHEDULE_UNDEF;
exports.SRETRY_SCHEDULE_SEC = SRETRY_SCHEDULE_SEC;
exports.SRETRY_SCHEDULE_MIN = SRETRY_SCHEDULE_MIN;
exports.SRETRY_SCHEDULE_HOUR = SRETRY_SCHEDULE_HOUR;
exports.SRETRY_SCHEDULE_DAY = SRETRY_SCHEDULE_DAY;
exports.SRETRY_SCHEDULE_WEEK = SRETRY_SCHEDULE_WEEK;
exports.SRETRY_SCHEDULE_MONTH = SRETRY_SCHEDULE_MONTH;

//Схема валидации функции сервиса
exports.ServiceFunction = new Schema({
    //Идентификатор функции сервиса
    nId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор функции сервиса (nId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор функции сервиса (nId)"
        }
    },
    //Код функции сервиса
    sCode: {
        type: String,
        required: true,
        message: {
            type: "Код функции сервиса (sCode) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан код функции сервиса (sCode)"
        }
    },
    //Тип функции сервиса
    nFnType: {
        type: Number,
        enum: [NFN_TYPE_DATA, NFN_TYPE_LOGIN, NFN_TYPE_LOGOUT],
        required: true,
        message: {
            type: "Тип функции сервиса (nFnType) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение типа функции сервиса (nFnType) не поддерживается",
            required: "Не указан тип функции сервиса (nFnType)"
        }
    },
    //Тип функции сервиса (строковый код)
    sFnType: {
        type: String,
        enum: [SFN_TYPE_DATA, SFN_TYPE_LOGIN, SFN_TYPE_LOGOUT],
        required: true,
        message: {
            type: "Строковый код типа функции сервиса (sFnType) имеет некорректный тип данных (ожидалось - String)",
            enum: "Значение строкового кода типа функции сервиса (sFnType) не поддерживается",
            required: "Не указан строковый код типа функции сервиса (sFnType)"
        }
    },
    //Адрес функции сервиса
    sFnURL: {
        type: String,
        required: true,
        message: {
            type: "Адрес функции сервиса (sFnURL) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан адрес функции сервиса (sFnURL)"
        }
    },
    //Способ передачи параметров функции сервиса
    nFnPrmsType: {
        type: Number,
        enum: [NFN_PRMS_TYPE_GET, NFN_PRMS_TYPE_POST],
        required: true,
        message: {
            type:
                "Способ передачи параметров функции сервиса (nFnPrmsType) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение способа передачи параметров функции сервиса (nFnPrmsType) не поддерживается",
            required: "Не указан способ передачи параметров функции сервиса (nFnPrmsType)"
        }
    },
    //Способ передачи параметров функции сервиса (строковый код)
    sFnPrmsType: {
        type: String,
        enum: [SFN_PRMS_TYPE_GET, SFN_PRMS_TYPE_POST],
        required: true,
        message: {
            type:
                "Строковый код способа передачи параметров функции сервиса (sFnPrmsType) имеет некорректный тип данных (ожидалось - String)",
            enum:
                "Значение строкового кода способа передачи параметров функции сервиса (sFnPrmsType) не поддерживается",
            required: "Не указан строковый код способа передачи параметров функции сервиса (sFnPrmsType)"
        }
    },
    //График повторной отправки запроса функции сервиса
    nRetrySchedule: {
        type: Number,
        enum: [
            NRETRY_SCHEDULE_UNDEF,
            NRETRY_SCHEDULE_SEC,
            NRETRY_SCHEDULE_MIN,
            NRETRY_SCHEDULE_HOUR,
            NRETRY_SCHEDULE_DAY,
            NRETRY_SCHEDULE_WEEK,
            NRETRY_SCHEDULE_MONTH
        ],
        required: true,
        message: {
            type:
                "График повторной отправки запроса функции сервиса (nRetrySchedule) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение графика повторной отправки запроса функции сервиса (nRetrySchedule) не поддерживается",
            required: "Не указан график повторной отправки запроса функции сервиса (nRetrySchedule)"
        }
    },
    //График повторной отправки запроса функции сервиса (строковый код)
    sRetrySchedule: {
        type: String,
        enum: [
            SRETRY_SCHEDULE_UNDEF,
            SRETRY_SCHEDULE_SEC,
            SRETRY_SCHEDULE_MIN,
            SRETRY_SCHEDULE_HOUR,
            SRETRY_SCHEDULE_DAY,
            SRETRY_SCHEDULE_WEEK,
            SRETRY_SCHEDULE_MONTH
        ],
        required: true,
        message: {
            type:
                "Строковый код графика повторной отправки запроса функции сервиса (sRetrySchedule) имеет некорректный тип данных (ожидалось - String)",
            enum:
                "Значение строкового кода графика повторной отправки запроса функции сервиса (sRetrySchedule) не поддерживается",
            required: "Не указан строковый код графика повторной отправки запроса функции сервиса (sRetrySchedule)"
        }
    },
    //Идентификатор типового сообщения обмена, обрабатываемого функцией сервиса
    nMsgId: {
        type: Number,
        required: true,
        message: {
            type:
                "Идентификатор типового сообщения обмена, обрабатываемого функцией сервиса (nMsgId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор типового сообщения обмена, обрабатываемого функцией сервиса (nMsgId)"
        }
    },
    //Код типового сообщения обмена, обрабатываемого функцией сервиса
    sMsgCode: {
        type: String,
        required: true,
        message: {
            type:
                "Код типового сообщения обмена, обрабатываемого функцией сервиса (sMsgCode) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан код типового сообщения обмена, обрабатываемого функцией сервиса (sMsgCode)"
        }
    },
    //Обработчик сообщения "до" на строне сервера приложений для функции сервиса
    sAppSrvBefore: {
        type: String,
        required: false,
        message: {
            type:
                "Обработчик сообщения 'до' на строне сервера приложений для функции сервиса (sAppSrvBefore) имеет некорректный тип данных (ожидалось - String)",
            required:
                "Не указан обработчик сообщения 'до' на строне сервера приложений для функции сервиса (sAppSrvBefore)"
        }
    },
    //Обработчик сообщения "после" на строне сервера приложений для функции сервиса
    sAppSrvAfter: {
        type: String,
        required: false,
        message: {
            type:
                "Обработчик сообщения 'после' на строне сервера приложений для функции сервиса (sAppSrvAfter) имеет некорректный тип данных (ожидалось - String)",
            required:
                "Не указан обработчик сообщения 'после' на строне сервера приложений для функции сервиса (sAppSrvBefore)"
        }
    }
});
