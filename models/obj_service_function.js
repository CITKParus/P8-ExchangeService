/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель функции сервиса
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { validateMailList } = require("./common"); //Общие объекты валидации моделей данных

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

//Признак необходимости аутентифицированности сервиса для исполнения функции
const NAUTH_ONLY_YES = 1; //Требуется аутентификация
const NAUTH_ONLY_NO = 0; //Аутентификация не требуется
const SAUTH_ONLY_YES = "AUTH_ONLY_YES"; //Требуется аутентификация (строковый код)
const SAUTH_ONLY_NO = "AUTH_ONLY_NO"; //Аутентификация не требуется (строковый код)

//Признак оповещения об ошибке исполнения сообщения очереди для функции обработки
const NERR_NTF_SIGN_NO = 0; //Не оповещать об ошибке исполнения
const NERR_NTF_SIGN_YES = 1; //Оповещать об ошибке исполнения
const SERR_NTF_SIGN_NO = "ERR_NTF_SIGN_NO"; //Не оповещать об ошибке исполнения (строковый код)
const SERR_NTF_SIGN_YES = "ERR_NTF_SIGN_YES"; //Оповещать об ошибке исполнения (строковый код)

//-------------
//  Тело модуля
//-------------

//Функция проверки наименования обработчика со стороны сервера приложений
const validateAppSrvFn = val => {
    if (val) {
        let r = /^[a-z0-9_.-]+(.js)\/[a-z0-9_.-]+$/;
        return r.test(val.toLowerCase());
    }
    return true;
};

//Валидация списка адресов E-Mail для оповещения об ошибке обработки сообщения очереди
const validateErrNtfMail = val => {
    return validateMailList(val);
};

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
exports.NAUTH_ONLY_YES = NAUTH_ONLY_YES;
exports.NAUTH_ONLY_NO = NAUTH_ONLY_NO;
exports.SAUTH_ONLY_YES = SAUTH_ONLY_YES;
exports.SAUTH_ONLY_NO = SAUTH_ONLY_NO;
exports.NERR_NTF_SIGN_NO = NERR_NTF_SIGN_NO;
exports.NERR_NTF_SIGN_YES = NERR_NTF_SIGN_YES;
exports.SERR_NTF_SIGN_NO = SERR_NTF_SIGN_NO;
exports.SERR_NTF_SIGN_YES = SERR_NTF_SIGN_YES;

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
    //Идентификатор родительского сервиса функции
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type:
                "Идентификатор родительского сервиса функции (nServiceId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор родительского сервиса функции (nServiceId)"
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
    //Обработчик сообщения со стороны БД
    sPrcResp: {
        type: String,
        required: false,
        message: {
            type:
                "Обработчик сообщения со стороны БД для функции сервиса (sPrcResp) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан обработчик сообщения со стороны БД для функции сервиса (sPrcResp)"
        }
    },
    //Обработчик сообщения "до" на строне сервера приложений для функции сервиса
    sAppSrvBefore: {
        type: String,
        required: false,
        use: { validateAppSrvFn },
        message: {
            type:
                "Обработчик сообщения 'до' на строне сервера приложений для функции сервиса (sAppSrvBefore) имеет некорректный тип данных (ожидалось - String)",
            required:
                "Не указан обработчик сообщения 'до' на строне сервера приложений для функции сервиса (sAppSrvBefore)",
            validateAppSrvFn:
                "Обработчик сообщения 'до' на строне сервера приложений для функции сервиса (sAppSrvBefore) имеет некорректный формат, ожидалось: <МОДУЛЬ>.js/<ФУНКЦИЯ>"
        }
    },
    //Обработчик сообщения "после" на строне сервера приложений для функции сервиса
    sAppSrvAfter: {
        type: String,
        required: false,
        use: { validateAppSrvFn },
        message: {
            type:
                "Обработчик сообщения 'после' на строне сервера приложений для функции сервиса (sAppSrvAfter) имеет некорректный тип данных (ожидалось - String)",
            required:
                "Не указан обработчик сообщения 'после' на строне сервера приложений для функции сервиса (sAppSrvAfter)",
            validateAppSrvFn:
                "Обработчик сообщения 'после' на строне сервера приложений для функции сервиса (sAppSrvBefore) имеет некорректный формат, ожидалось: <МОДУЛЬ>.js/<ФУНКЦИЯ>"
        }
    },
    //Признак необходимости аутентификации для исполнения функции сервсиа обмена
    nAuthOnly: {
        type: Number,
        enum: [NAUTH_ONLY_NO, NAUTH_ONLY_YES],
        required: true,
        message: {
            type:
                "Признак необходимости аутентификации для исполнения функции сервсиа обмена (nAuthOnly) имеет некорректный тип данных (ожидалось - Number)",
            enum:
                "Значение признака необходимости аутентификации для исполнения функции сервсиа обмена (nAuthOnly) не поддерживается",
            required: "Не указан признак необходимости аутентификации для исполнения функции сервсиа обмена (nAuthOnly)"
        }
    },
    //Признак необходимости аутентификации для исполнения функции сервсиа обмена (строковый код)
    sAuthOnly: {
        type: String,
        enum: [SAUTH_ONLY_NO, SAUTH_ONLY_YES],
        required: true,
        message: {
            type:
                "Строковый код признака необходимости аутентификации для исполнения функции сервсиа обмена (sAuthOnly) имеет некорректный тип данных (ожидалось - String)",
            enum:
                "Значение строкового кода признака необходимости аутентификации для исполнения функции сервсиа обмена (sAuthOnly) не поддерживается",
            required:
                "Не указан строковый код признака необходимости аутентификации для исполнения функции сервсиа обмена (sAuthOnly)"
        }
    },
    //Признак оповещения об ошибке исполнения сообщения очереди для функции обработки
    nErrNtfSign: {
        type: Number,
        enum: [NERR_NTF_SIGN_NO, NERR_NTF_SIGN_YES],
        required: true,
        message: {
            type:
                "Признак оповещения об ошибке исполнения сообщения очереди для функции обработки (nErrNtfSign) имеет некорректный тип данных (ожидалось - Number)",
            enum:
                "Значение признака оповещения об ошибке исполнения сообщения очереди для функции обработки (nErrNtfSign) не поддерживается",
            required:
                "Не указан признак оповещения об ошибке исполнения сообщения очереди для функции обработки (nErrNtfSign)"
        }
    },
    //Признак оповещения об ошибке исполнения сообщения очереди для функции обработки (строковый код)
    sErrNtfSign: {
        type: String,
        enum: [SERR_NTF_SIGN_NO, SERR_NTF_SIGN_YES],
        required: true,
        message: {
            type:
                "Строковый код признака оповещения об ошибке исполнения сообщения очереди для функции обработки (sErrNtfSign) имеет некорректный тип данных (ожидалось - String)",
            enum:
                "Значение строкового кода признака оповещения об ошибке исполнения сообщения очереди для функции обработки (sErrNtfSign) не поддерживается",
            required:
                "Не указан строковый код признака оповещения об ошибке исполнения сообщения очереди для функции обработки (sErrNtfSign)"
        }
    },
    //Список адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки
    sErrNtfMail: {
        type: String,
        required: false,
        use: { validateErrNtfMail },
        message: {
            type:
                "Список адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки (sErrNtfMail) имеет некорректный тип данных (ожидалось - String)",
            required:
                "Не указан список адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки (sErrNtfMail)",
            validateErrNtfMail:
                "Неверный формат списка адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки (sErrNtfMail), для указания нескольких адресов следует использовать запятую в качестве разделителя (без пробелов)"
        }
    }
});
