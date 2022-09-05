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
const NFN_PRMS_TYPE_HEAD = 2; //HEAD-запрос
const NFN_PRMS_TYPE_PUT = 3; //PUT-запрос
const NFN_PRMS_TYPE_DELETE = 4; //DELETE-запрос
const NFN_PRMS_TYPE_CONNECT = 5; //CONNECT-запрос
const NFN_PRMS_TYPE_OPTIONS = 6; //OPTIONS-запрос
const NFN_PRMS_TYPE_TRACE = 7; //TRACE-запрос
const NFN_PRMS_TYPE_PATCH = 8; //PATCH-запрос
const SFN_PRMS_TYPE_POST = "POST"; //POST-запрос
const SFN_PRMS_TYPE_GET = "GET"; //GET-запрос
const SFN_PRMS_TYPE_HEAD = "HEAD"; //HEAD-запрос
const SFN_PRMS_TYPE_PUT = "PUT"; //PUT-запрос
const SFN_PRMS_TYPE_DELETE = "DELETE"; //DELETE-запрос
const SFN_PRMS_TYPE_CONNECT = "CONNECT"; //CONNECT-запрос
const SFN_PRMS_TYPE_OPTIONS = "OPTIONS"; //OPTIONS-запрос
const SFN_PRMS_TYPE_TRACE = "TRACE"; //TRACE-запрос
const SFN_PRMS_TYPE_PATCH = "PATCH"; //PATCH-запрос

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
exports.NFN_PRMS_TYPE_HEAD = NFN_PRMS_TYPE_HEAD;
exports.NFN_PRMS_TYPE_PUT = NFN_PRMS_TYPE_PUT;
exports.NFN_PRMS_TYPE_DELETE = NFN_PRMS_TYPE_DELETE;
exports.NFN_PRMS_TYPE_CONNECT = NFN_PRMS_TYPE_CONNECT;
exports.NFN_PRMS_TYPE_OPTIONS = NFN_PRMS_TYPE_OPTIONS;
exports.NFN_PRMS_TYPE_TRACE = NFN_PRMS_TYPE_TRACE;
exports.NFN_PRMS_TYPE_PATCH = NFN_PRMS_TYPE_PATCH;
exports.SFN_PRMS_TYPE_POST = SFN_PRMS_TYPE_POST;
exports.SFN_PRMS_TYPE_GET = SFN_PRMS_TYPE_GET;
exports.SFN_PRMS_TYPE_HEAD = SFN_PRMS_TYPE_HEAD;
exports.SFN_PRMS_TYPE_PUT = SFN_PRMS_TYPE_PUT;
exports.SFN_PRMS_TYPE_DELETE = SFN_PRMS_TYPE_DELETE;
exports.SFN_PRMS_TYPE_CONNECT = SFN_PRMS_TYPE_CONNECT;
exports.SFN_PRMS_TYPE_OPTIONS = SFN_PRMS_TYPE_OPTIONS;
exports.SFN_PRMS_TYPE_TRACE = SFN_PRMS_TYPE_TRACE;
exports.SFN_PRMS_TYPE_PATCH = SFN_PRMS_TYPE_PATCH;
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
            type: path => `Идентификатор функции сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор функции сервиса (${path})`
        }
    },
    //Идентификатор родительского сервиса функции
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор родительского сервиса функции (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор родительского сервиса функции (${path})`
        }
    },
    //Код функции сервиса
    sCode: {
        type: String,
        required: true,
        message: {
            type: path => `Код функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан код функции сервиса (${path})`
        }
    },
    //Тип функции сервиса
    nFnType: {
        type: Number,
        enum: [NFN_TYPE_DATA, NFN_TYPE_LOGIN, NFN_TYPE_LOGOUT],
        required: true,
        message: {
            type: path => `Тип функции сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение типа функции сервиса (${path}) не поддерживается`,
            required: path => `Не указан тип функции сервиса (${path})`
        }
    },
    //Тип функции сервиса (строковый код)
    sFnType: {
        type: String,
        enum: [SFN_TYPE_DATA, SFN_TYPE_LOGIN, SFN_TYPE_LOGOUT],
        required: true,
        message: {
            type: path =>
                `Строковый код типа функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path => `Значение строкового кода типа функции сервиса (${path}) не поддерживается`,
            required: path => `Не указан строковый код типа функции сервиса (${path})`
        }
    },
    //Адрес функции сервиса
    sFnURL: {
        type: String,
        required: true,
        message: {
            type: path => `Адрес функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан адрес функции сервиса (${path})`
        }
    },
    //Способ передачи параметров функции сервиса
    nFnPrmsType: {
        type: Number,
        enum: [
            NFN_PRMS_TYPE_GET,
            NFN_PRMS_TYPE_POST,
            NFN_PRMS_TYPE_HEAD,
            NFN_PRMS_TYPE_PUT,
            NFN_PRMS_TYPE_DELETE,
            NFN_PRMS_TYPE_CONNECT,
            NFN_PRMS_TYPE_OPTIONS,
            NFN_PRMS_TYPE_TRACE,
            NFN_PRMS_TYPE_PATCH
        ],
        required: true,
        message: {
            type: path =>
                `Способ передачи параметров функции сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение способа передачи параметров функции сервиса (${path}) не поддерживается`,
            required: path => `Не указан способ передачи параметров функции сервиса (${path})`
        }
    },
    //Способ передачи параметров функции сервиса (строковый код)
    sFnPrmsType: {
        type: String,
        enum: [
            SFN_PRMS_TYPE_GET,
            SFN_PRMS_TYPE_POST,
            SFN_PRMS_TYPE_HEAD,
            SFN_PRMS_TYPE_PUT,
            SFN_PRMS_TYPE_DELETE,
            SFN_PRMS_TYPE_CONNECT,
            SFN_PRMS_TYPE_OPTIONS,
            SFN_PRMS_TYPE_TRACE,
            SFN_PRMS_TYPE_PATCH
        ],
        required: true,
        message: {
            type: path =>
                `Строковый код способа передачи параметров функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path =>
                `Значение строкового кода способа передачи параметров функции сервиса (${path}) не поддерживается`,
            required: path => `Не указан строковый код способа передачи параметров функции сервиса (${path})`
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
            type: path =>
                `График повторной отправки запроса функции сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение графика повторной отправки запроса функции сервиса (${path}) не поддерживается`,
            required: path => `Не указан график повторной отправки запроса функции сервиса (${path})`
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
            type: path =>
                `Строковый код графика повторной отправки запроса функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path =>
                `Значение строкового кода графика повторной отправки запроса функции сервиса (${path}) не поддерживается`,
            required: path => `Не указан строковый код графика повторной отправки запроса функции сервиса (${path})`
        }
    },
    //Идентификатор типового сообщения обмена, обрабатываемого функцией сервиса
    nMsgId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор типового сообщения обмена, обрабатываемого функцией сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path =>
                `Не указан идентификатор типового сообщения обмена, обрабатываемого функцией сервиса (${path})`
        }
    },
    //Код типового сообщения обмена, обрабатываемого функцией сервиса
    sMsgCode: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Код типового сообщения обмена, обрабатываемого функцией сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан код типового сообщения обмена, обрабатываемого функцией сервиса (${path})`
        }
    },
    //Обработчик сообщения со стороны БД
    sPrcResp: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Обработчик сообщения со стороны БД для функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан обработчик сообщения со стороны БД для функции сервиса (${path})`
        }
    },
    //Обработчик сообщения "до" на строне сервера приложений для функции сервиса
    sAppSrvBefore: {
        type: String,
        required: false,
        use: { validateAppSrvFn },
        message: {
            type: path =>
                `Обработчик сообщения 'до' на строне сервера приложений для функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path =>
                `Не указан обработчик сообщения 'до' на строне сервера приложений для функции сервиса (${path})`,
            validateAppSrvFn: path =>
                `Обработчик сообщения 'до' на строне сервера приложений для функции сервиса (${path}) имеет некорректный формат, ожидалось: <МОДУЛЬ>.js/<ФУНКЦИЯ>`
        }
    },
    //Обработчик сообщения "после" на строне сервера приложений для функции сервиса
    sAppSrvAfter: {
        type: String,
        required: false,
        use: { validateAppSrvFn },
        message: {
            type: path =>
                `Обработчик сообщения 'после' на строне сервера приложений для функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path =>
                `Не указан обработчик сообщения 'после' на строне сервера приложений для функции сервиса (${path})`,
            validateAppSrvFn: path =>
                `Обработчик сообщения 'после' на строне сервера приложений для функции сервиса (${path}) имеет некорректный формат, ожидалось: <МОДУЛЬ>.js/<ФУНКЦИЯ>`
        }
    },
    //Признак необходимости аутентификации для исполнения функции сервсиа обмена
    nAuthOnly: {
        type: Number,
        enum: [NAUTH_ONLY_NO, NAUTH_ONLY_YES],
        required: true,
        message: {
            type: path =>
                `Признак необходимости аутентификации для исполнения функции сервсиа обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path =>
                `Значение признака необходимости аутентификации для исполнения функции сервсиа обмена (${path}) не поддерживается`,
            required: path =>
                `Не указан признак необходимости аутентификации для исполнения функции сервсиа обмена (${path})`
        }
    },
    //Признак необходимости аутентификации для исполнения функции сервсиа обмена (строковый код)
    sAuthOnly: {
        type: String,
        enum: [SAUTH_ONLY_NO, SAUTH_ONLY_YES],
        required: true,
        message: {
            type: path =>
                `Строковый код признака необходимости аутентификации для исполнения функции сервсиа обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path =>
                `Значение строкового кода признака необходимости аутентификации для исполнения функции сервсиа обмена (${path}) не поддерживается`,
            required: path =>
                `Не указан строковый код признака необходимости аутентификации для исполнения функции сервсиа обмена (${path})`
        }
    },
    //Признак оповещения об ошибке исполнения сообщения очереди для функции обработки
    nErrNtfSign: {
        type: Number,
        enum: [NERR_NTF_SIGN_NO, NERR_NTF_SIGN_YES],
        required: true,
        message: {
            type: path =>
                `Признак оповещения об ошибке исполнения сообщения очереди для функции обработки (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path =>
                `Значение признака оповещения об ошибке исполнения сообщения очереди для функции обработки (${path}) не поддерживается`,
            required: path =>
                `Не указан признак оповещения об ошибке исполнения сообщения очереди для функции обработки (${path})`
        }
    },
    //Признак оповещения об ошибке исполнения сообщения очереди для функции обработки (строковый код)
    sErrNtfSign: {
        type: String,
        enum: [SERR_NTF_SIGN_NO, SERR_NTF_SIGN_YES],
        required: true,
        message: {
            type: path =>
                `Строковый код признака оповещения об ошибке исполнения сообщения очереди для функции обработки (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path =>
                `Значение строкового кода признака оповещения об ошибке исполнения сообщения очереди для функции обработки (${path}) не поддерживается`,
            required: path =>
                `Не указан строковый код признака оповещения об ошибке исполнения сообщения очереди для функции обработки (${path})`
        }
    },
    //Список адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки
    sErrNtfMail: {
        type: String,
        required: false,
        use: { validateErrNtfMail },
        message: {
            type: path =>
                `Список адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path =>
                `Не указан список адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки (${path})`,
            validateErrNtfMail: path =>
                `Неверный формат списка адресов E-Mail для оповещения об ошибке исполнения сообщения очереди для функции обработки (${path}), для указания нескольких адресов следует использовать запятую в качестве разделителя (без пробелов)`
        }
    }
});
