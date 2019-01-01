/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель сервиса
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { defServiceFunctions } = require("./obj_service_functions"); //Схема валидации списка функций сервиса
const { validateMailList } = require("./common"); //Общие объекты валидации моделей данных

//----------
// Константы
//----------

//Типы сервисов
const NSRV_TYPE_SEND = 0; //Отправка сообщений
const NSRV_TYPE_RECIVE = 1; //Получение сообщений
const SSRV_TYPE_SEND = "SEND"; //Отправка сообщений (строковый код)
const SSRV_TYPE_RECIVE = "RECIVE"; //Получение сообщений (строковый код)

//Признак оповещения о простое удаленного сервиса
const NUNAVLBL_NTF_SIGN_NO = 0; //Не оповещать о простое
const NUNAVLBL_NTF_SIGN_YES = 1; //Оповещать о простое
const SUNAVLBL_NTF_SIGN_NO = "UNAVLBL_NTF_NO"; //Не оповещать о простое (строковый код)
const SUNAVLBL_NTF_SIGN_YES = "UNAVLBL_NTF_YES"; //Оповещать о простое (строковый код)

//Признак аутентифицированности сервиса
const NIS_AUTH_YES = 1; //Аутентифицирован
const NIS_AUTH_NO = 0; //Неаутентифицирован
const SIS_AUTH_YES = "IS_AUTH_YES"; //Аутентифицирован (строковый код)
const SIS_AUTH_NO = "IS_AUTH_NO"; //Неаутентифицирован (строковый код)

//-------------
//  Тело модуля
//-------------

//Валидация списка адресов E-Mail для оповещения о простое внешнего сервиса
const validateUnavlblNtfMail = val => {
    return validateMailList(val);
};

//------------------
//  Интерфейс модуля
//------------------

//Константы
exports.NSRV_TYPE_SEND = NSRV_TYPE_SEND;
exports.NSRV_TYPE_RECIVE = NSRV_TYPE_RECIVE;
exports.SSRV_TYPE_SEND = SSRV_TYPE_SEND;
exports.SSRV_TYPE_RECIVE = SSRV_TYPE_RECIVE;
exports.NUNAVLBL_NTF_SIGN_NO = NUNAVLBL_NTF_SIGN_NO;
exports.NUNAVLBL_NTF_SIGN_YES = NUNAVLBL_NTF_SIGN_YES;
exports.SUNAVLBL_NTF_SIGN_NO = SUNAVLBL_NTF_SIGN_NO;
exports.SUNAVLBL_NTF_SIGN_YES = SUNAVLBL_NTF_SIGN_YES;
exports.NIS_AUTH_YES = NIS_AUTH_YES;
exports.NIS_AUTH_NO = NIS_AUTH_NO;
exports.SIS_AUTH_YES = SIS_AUTH_YES;
exports.SIS_AUTH_NO = SIS_AUTH_NO;

//Схема валидации сервиса
exports.Service = new Schema({
    //Идентификатор сервиса
    nId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор сервиса (nId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор сервиса (nId)"
        }
    },
    //Код сервиса
    sCode: {
        type: String,
        required: true,
        message: {
            type: "Код сервиса (sCode) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан код сервиса (sCode)"
        }
    },
    //Наименование сервиса
    sName: {
        type: String,
        required: true,
        message: {
            type: "Наименование сервиса (sName) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано наименование сервиса (sName)"
        }
    },
    //Тип сервиса
    nSrvType: {
        type: Number,
        enum: [NSRV_TYPE_SEND, NSRV_TYPE_RECIVE],
        required: true,
        message: {
            type: "Тип сервиса (nSrvType) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение типа сервиса (nSrvType) не поддерживается",
            required: "Не указан типа сервиса (nSrvType)"
        }
    },
    //Тип сервиса (строковый код)
    sSrvType: {
        type: String,
        enum: [SSRV_TYPE_SEND, SSRV_TYPE_RECIVE],
        required: true,
        message: {
            type: "Строковый код типа сервиса (sSrvType) имеет некорректный тип данных (ожидалось - String)",
            enum: "Значение строкового кода типа сервиса (sSrvType) не поддерживается",
            required: "Не указан строковый код типа сервиса (sSrvType)"
        }
    },
    //Корневой каталог сервиса
    sSrvRoot: {
        type: String,
        required: true,
        message: {
            type: "Корневой каталог сервиса (sSrvRoot) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан корневой каталог сервиса (sSrvRoot)"
        }
    },
    //Имя пользователя сервиса
    sSrvUser: {
        type: String,
        required: false,
        message: {
            type: "Имя пользователя сервиса (sSrvUser) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано имя пользователя сервиса (sSrvUser)"
        }
    },
    //Пароль пользователя
    sSrvPass: {
        type: String,
        required: false,
        message: {
            type: "Пароль пользователя сервиса (sSrvPass) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан пароль пользователя сервиса (sSrvPass)"
        }
    },
    //Признак необходимости оповещения о простое внешнего сервиса
    nUnavlblNtfSign: {
        type: Number,
        enum: [NUNAVLBL_NTF_SIGN_NO, NUNAVLBL_NTF_SIGN_YES],
        required: true,
        message: {
            type:
                "Признак необходимости оповещения о простое внешнего сервиса (nUnavlblNtfSign) имеет некорректный тип данных (ожидалось - Number)",
            enum:
                "Значение признака необходимости оповещения о простое внешнего сервиса (nUnavlblNtfSign) не поддерживается",
            required: "Не указан признак необходимости оповещения о простое внешнего сервиса (nUnavlblNtfSign)"
        }
    },
    //Признак необходимости оповещения о простое внешнего сервиса (строковый код)
    sUnavlblNtfSign: {
        type: String,
        enum: [SUNAVLBL_NTF_SIGN_NO, SUNAVLBL_NTF_SIGN_YES],
        required: true,
        message: {
            type:
                "Строковый код признака необходимости оповещения о простое внешнего сервиса (sUnavlblNtfSign) имеет некорректный тип данных (ожидалось - String)",
            enum:
                "Значение строкового кода признака необходимости оповещения о простое внешнего сервиса (sUnavlblNtfSign) не поддерживается",
            required:
                "Не указан строковый код признака необходимости оповещения о простое внешнего сервиса (sUnavlblNtfSign)"
        }
    },
    //Максимальное время простоя (мин) удалённого сервиса для генерации оповещения
    nUnavlblNtfTime: {
        type: Number,
        required: true,
        message: {
            type:
                "Максимальное время простоя (мин) удалённого сервиса для генерации оповещения (nUnavlblNtfTime) имеет некорректный тип данных (ожидалось - Number)",
            required:
                "Не указано максимальное время простоя (мин) удалённого сервиса для генерации оповещения (nUnavlblNtfTime)"
        }
    },
    //Список адресов E-Mail для оповещения о простое внешнего сервиса
    sUnavlblNtfMail: {
        type: String,
        required: false,
        use: { validateUnavlblNtfMail },
        message: {
            type:
                "Список адресов E-Mail для оповещения о простое внешнего сервиса (sUnavlblNtfMail) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан список адресов E-Mail для оповещения о простое внешнего сервиса (sUnavlblNtfMail)",
            validateUnavlblNtfMail:
                "Неверный формат списка адресов E-Mail для оповещения о простое внешнего сервиса (sUnavlblNtfMail), для указания нескольких адресов следует использовать запятую в качестве разделителя (без пробелов)"
        }
    },
    //Список функций сервиса
    functions: defServiceFunctions(true, "functions"),
    //Контекст работы сервиса
    context: {
        type: Object,
        required: true,
        message: {
            type: "Контекст работы сервиса (context) имеет некорректный тип данных (ожидалось - Object)",
            required: "Не указан контекст работы сервиса (context)"
        }
    }
});

//Схема валидации контекста сервиса
exports.ServiceCtx = new Schema({
    //Идентификатор сервиса
    nId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор сервиса (nId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор сервиса (nId)"
        }
    },
    //Контекст
    sCtx: {
        type: String,
        required: false,
        message: {
            type: "Контектс сервиса (sCtx) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан контекст сервиса (sCtx)"
        }
    },
    //Дата истечения контекста
    dCtxExp: {
        type: Date,
        required: false,
        message: {
            type: "Дата истечения контекста (dCtxExp) имеет некорректный тип данных (ожидалось - Date)",
            required: "Не указана дата истечения контекста (dCtxExp)"
        }
    },
    //Дата истечения контекста (строковое представление)
    sCtxExp: {
        type: String,
        required: false,
        message: {
            type:
                "Строковое представление даты истечения контекста (sCtxExp) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано строковое представление даты истечения контекста (sCtxExp)"
        }
    },
    //Признак аутентицированности сервиса
    nIsAuth: {
        type: Number,
        enum: [NIS_AUTH_YES, NIS_AUTH_NO],
        required: true,
        message: {
            type: "Признака аутентицированности сервиса (nIsAuth) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение признака аутентицированности сервиса (nIsAuth) не поддерживается",
            required: "Не указан признак аутентицированности сервиса (nIsAuth)"
        }
    },
    //Признак аутентицированности сервиса (строковый код)
    sIsAuth: {
        type: String,
        enum: [SIS_AUTH_YES, SIS_AUTH_NO],
        required: true,
        message: {
            type:
                "Строковый код признака аутентицированности сервиса (sIsAuth) имеет некорректный тип данных (ожидалось - String)",
            enum: "Значение строкового кода признака аутентицированности сервиса (sIsAuth) не поддерживается",
            required: "Не указан строковый код признака аутентицированности сервиса (sIsAuth)"
        }
    }
});
