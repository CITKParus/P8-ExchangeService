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
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    },
    //Код сервиса
    sCode: {
        type: String,
        required: true,
        message: {
            type: path => `Код сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан код сервиса (${path})`
        }
    },
    //Наименование сервиса
    sName: {
        type: String,
        required: true,
        message: {
            type: path => `Наименование сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано наименование сервиса (${path})`
        }
    },
    //Тип сервиса
    nSrvType: {
        type: Number,
        enum: [NSRV_TYPE_SEND, NSRV_TYPE_RECIVE],
        required: true,
        message: {
            type: path => `Тип сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение типа сервиса (${path}) не поддерживается`,
            required: path => `Не указан типа сервиса (${path})`
        }
    },
    //Тип сервиса (строковый код)
    sSrvType: {
        type: String,
        enum: [SSRV_TYPE_SEND, SSRV_TYPE_RECIVE],
        required: true,
        message: {
            type: path => `Строковый код типа сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path => `Значение строкового кода типа сервиса (${path}) не поддерживается`,
            required: path => `Не указан строковый код типа сервиса (${path})`
        }
    },
    //Корневой каталог сервиса
    sSrvRoot: {
        type: String,
        required: true,
        message: {
            type: path => `Корневой каталог сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан корневой каталог сервиса (${path})`
        }
    },
    //Имя пользователя сервиса
    sSrvUser: {
        type: String,
        required: false,
        message: {
            type: path => `Имя пользователя сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано имя пользователя сервиса (${path})`
        }
    },
    //Пароль пользователя
    sSrvPass: {
        type: String,
        required: false,
        message: {
            type: path => `Пароль пользователя сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан пароль пользователя сервиса (${path})`
        }
    },
    //Признак необходимости оповещения о простое внешнего сервиса
    nUnavlblNtfSign: {
        type: Number,
        enum: [NUNAVLBL_NTF_SIGN_NO, NUNAVLBL_NTF_SIGN_YES],
        required: true,
        message: {
            type: path =>
                `Признак необходимости оповещения о простое внешнего сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path =>
                `Значение признака необходимости оповещения о простое внешнего сервиса (${path}) не поддерживается`,
            required: path => `Не указан признак необходимости оповещения о простое внешнего сервиса (${path})`
        }
    },
    //Признак необходимости оповещения о простое внешнего сервиса (строковый код)
    sUnavlblNtfSign: {
        type: String,
        enum: [SUNAVLBL_NTF_SIGN_NO, SUNAVLBL_NTF_SIGN_YES],
        required: true,
        message: {
            type: path =>
                `Строковый код признака необходимости оповещения о простое внешнего сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path =>
                `Значение строкового кода признака необходимости оповещения о простое внешнего сервиса (${path}) не поддерживается`,
            required: path =>
                `Не указан строковый код признака необходимости оповещения о простое внешнего сервиса (${path})`
        }
    },
    //Максимальное время простоя (мин) удалённого сервиса для генерации оповещения
    nUnavlblNtfTime: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Максимальное время простоя (мин) удалённого сервиса для генерации оповещения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path =>
                `Не указано максимальное время простоя (мин) удалённого сервиса для генерации оповещения (${path})`
        }
    },
    //Список адресов E-Mail для оповещения о простое внешнего сервиса
    sUnavlblNtfMail: {
        type: String,
        required: false,
        use: { validateUnavlblNtfMail },
        message: {
            type: path =>
                `Список адресов E-Mail для оповещения о простое внешнего сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан список адресов E-Mail для оповещения о простое внешнего сервиса (${path})`,
            validateUnavlblNtfMail: path =>
                `Неверный формат списка адресов E-Mail для оповещения о простое внешнего сервиса (${path}), для указания нескольких адресов следует использовать запятую в качестве разделителя (без пробелов)`
        }
    },
    //Список функций сервиса
    functions: defServiceFunctions(true, "functions")
});

//Схема валидации контекста сервиса
exports.ServiceCtx = new Schema({
    //Идентификатор сервиса
    nId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    },
    //Контекст
    sCtx: {
        type: String,
        required: false,
        message: {
            type: path => `Контектс сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан контекст сервиса (${path})`
        }
    },
    //Дата истечения контекста
    dCtxExp: {
        type: Date,
        required: false,
        message: {
            type: path => `Дата истечения контекста (${path}) имеет некорректный тип данных (ожидалось - Date)`,
            required: path => `Не указана дата истечения контекста (${path})`
        }
    },
    //Дата истечения контекста (строковое представление)
    sCtxExp: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Строковое представление даты истечения контекста (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано строковое представление даты истечения контекста (${path})`
        }
    },
    //Признак аутентицированности сервиса
    nIsAuth: {
        type: Number,
        enum: [NIS_AUTH_YES, NIS_AUTH_NO],
        required: true,
        message: {
            type: path =>
                `Признака аутентицированности сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение признака аутентицированности сервиса (${path}) не поддерживается`,
            required: path => `Не указан признак аутентицированности сервиса (${path})`
        }
    },
    //Признак аутентицированности сервиса (строковый код)
    sIsAuth: {
        type: String,
        enum: [SIS_AUTH_YES, SIS_AUTH_NO],
        required: true,
        message: {
            type: path =>
                `Строковый код признака аутентицированности сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path => `Значение строкового кода признака аутентицированности сервиса (${path}) не поддерживается`,
            required: path => `Не указан строковый код признака аутентицированности сервиса (${path})`
        }
    }
});

//Схема валидации сведений о просроченных сообщениях обмена сервиса
exports.ServiceExpiredQueueInfo = new Schema({
    //Идентификатор сервиса
    nId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    },
    //Количество просроченных сообщений обмена
    nCnt: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Количество просроченных сообщений обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указано количество просроченных сообщений обмена (${path})`
        }
    },
    //Информация о просроченных сообщениях обмена
    sInfoList: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Информация о просроченных сообщениях обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указана информация о просроченных сообщениях обмена (${path})`
        }
    }
}).validator({ required: val => val === null || val === 0 || val });
