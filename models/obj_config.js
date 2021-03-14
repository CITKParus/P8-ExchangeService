/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель объекта конфигурации приложения
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//-------------
//  Тело модуля
//-------------

//Функция проверки значения таймаута останова сервера
const validateTerminateTimeout = val => val >= 1000 && val <= 120000 && Number.isInteger(val);

//Функция проверки значения размера блока одновременно обрабатываемых исходящих сообщений
const validateMaxWorkers = val => val >= 1 && val <= 100 && Number.isInteger(val);

//Функция проверки значения интервала проверки наличия исходящих сообщений
const validateCheckTimeout = val => val >= 1 && val <= 60000 && Number.isInteger(val);

//Функция проверки значения порта сервера обслуживания входящих сообщений
const validateInComingPort = val => val >= 0 && val <= 65535 && Number.isInteger(val);

//Функция проверки значения порта сервера обслуживания входящих сообщений
const validateMsgMaxSize = val => val >= 1 && val <= 1000 && Number.isInteger(val);

//Схема валидации общих параметров сервера приложений
const common = new Schema({
    //Версия сервера приложений
    sVersion: {
        type: String,
        required: true,
        message: {
            type: path => `Версия сервера приложений (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указана версия сервера приложений (${path})`
        }
    },
    //Релиз сервера приложений
    sRelease: {
        type: String,
        required: true,
        message: {
            type: path => `Релиз сервера приложений (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан релиз сервера приложений (${path})`
        }
    },
    //Таймаут останова сервера (мс)
    nTerminateTimeout: {
        type: Number,
        required: true,
        use: { validateTerminateTimeout },
        message: {
            type: path => `Таймаут останова сервера (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан таймаут останова сервера (${path})`,
            validateTerminateTimeout: path =>
                `Таймаут останова сервера (${path}) должен быть целым числом в диапазоне от 1000 до 120000`
        }
    }
});

//Схема валидации параметров подключения к БД
const dbConnect = new Schema({
    //Пользователь БД
    sUser: {
        type: String,
        required: true,
        message: {
            type: path => `Имя пользователя БД (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано имя пользователя БД (${path})`
        }
    },
    //Пароль пользователя БД
    sPassword: {
        type: String,
        required: true,
        message: {
            type: path => `Пароль пользователя БД (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан пароль пользователя БД (${path})`
        }
    },
    //Схема размещения используемых объектов БД
    sSchema: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Схема размещения используемых объектов БД (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указана схема размещения используемых объектов БД (${path})`
        }
    },
    //Строка подключения к БД
    sConnectString: {
        type: String,
        required: true,
        message: {
            type: path => `Строка подключения к БД (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указана строка подключения к БД (${path})`
        }
    },
    //Наименование сервера приложений в сессии БД
    sSessionAppName: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Наименование сервера приложений в сессии БД (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано наименование сервера приложений в сессии БД (${path})`
        }
    },
    //Наименование подключаемого модуля обслуживания БД
    sConnectorModule: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Наименование подключаемого модуля обслуживания БД (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано наименование подключаемого модуля обслуживания БД (${path})`
        }
    }
});

//Схема валидации параметров обработки очереди исходящих сообщений
const outGoing = new Schema({
    //Проверять SSL-сертификаты адресов отправки сообщений (самоподписанные сертификаты будут отвергнуты)
    bValidateSSL: {
        type: Boolean,
        required: true,
        message: {
            type: path =>
                `Признак проверки SSL-сертификатов адресов отправки сообщений (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан признак проверки SSL-сертификатов адресов отправки сообщений (${path})`
        }
    },
    //Количество одновременно обрабатываемых исходящих сообщений
    nMaxWorkers: {
        type: Number,
        required: true,
        use: { validateMaxWorkers },
        message: {
            type: path =>
                `Количество одновременно обрабатываемых исходящих сообщений (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указано количество одновременно обрабатываемых исходящих сообщений (${path})`,
            validateMaxWorkers: path =>
                `Количество одновременно обрабатываемых исходящих сообщений (${path}) должно быть целым числом в диапазоне от 1 до 100`
        }
    },
    //Интервал проверки наличия исходящих сообщений (мс)
    nCheckTimeout: {
        type: Number,
        required: true,
        use: { validateCheckTimeout },
        message: {
            type: path =>
                `Интервал проверки наличия исходящих сообщений (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан интервал проверки наличия исходящих сообщений (${path})`,
            validateCheckTimeout: path =>
                `Значение интервала проверки наличия исходящих сообщений (${path}) должно быть целым числом в диапазоне от 100 до 60000`
        }
    }
});

//Схема валидации параметров обработки очереди входящих сообщений
const inComing = new Schema({
    //Порт сервера входящих сообщений
    nPort: {
        type: Number,
        required: true,
        use: { validateInComingPort },
        message: {
            type: path =>
                `Порт сервера входящих сообщений (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан порт сервера входящих сообщений (${path})`,
            validateInComingPort: path =>
                `Порт сервера входящих сообщений (${path}) должен быть целым числом в диапазоне от  0 до 65535`
        }
    },
    //Максимальный размер входящего сообщения (мб)
    nMsgMaxSize: {
        type: Number,
        required: true,
        use: { validateMsgMaxSize },
        message: {
            type: path =>
                `Максимальный размер входящего сообщения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан максимальный размер входящего сообщения (${path})`,
            validateMsgMaxSize: path =>
                `Максимальный размер входящего сообщения (${path}) должен быть целым числом в диапазоне от  1 до 1000`
        }
    },
    //Каталог размещения статических ресурсов
    sStaticDir: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Каталог размещения статических ресурсов (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан каталог размещения статических ресурсов (${path})`
        }
    }
});

//Схема валидации параметров отправки E-Mail уведомлений
const mail = new Schema({
    //Адреc сервера SMTP
    sHost: {
        type: String,
        required: true,
        message: {
            type: path => `Адреc сервера SMTP (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан aдреc сервера SMTP (${path})`
        }
    },
    //Порт сервера SMTP
    nPort: {
        type: Number,
        required: true,
        message: {
            type: path => `Порт сервера SMTP (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан порт сервера SMTP (${path})`
        }
    },
    //Имя пользователя SMTP-сервера
    sUser: {
        type: String,
        required: true,
        message: {
            type: path => `Имя пользователя SMTP-сервера (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано имя пользователя SMTP-сервера (${path})`
        }
    },
    //Пароль пользователя SMTP-сервера
    sPass: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Пароль пользователя SMTP-сервера (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан пароль пользователя SMTP-сервера (${path})`
        }
    },
    //Наименование отправителя для исходящих сообщений
    sFrom: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Наименование отправителя для исходящих сообщений (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано наименование отправителя для исходящих сообщений (${path})`
        }
    }
});

//Схема валидации файла конфигурации
const config = new Schema({
    //Общие параметры
    common: {
        schema: common,
        required: true,
        message: {
            required: path => `Не указаны общие параметры конфигурации сервера приложений (${path})`
        }
    },
    //Параметры подключения к БД
    dbConnect: {
        schema: dbConnect,
        required: true,
        message: {
            required: path => `Не указаны параметры подключения к БД (${path})`
        }
    },
    //Параметры обработки очереди исходящих сообщений
    outGoing: {
        schema: outGoing,
        required: true,
        message: {
            required: path => `Не указаны параметры обработки очереди исходящих сообщений (${path})`
        }
    },
    //Параметры обработки очереди входящих сообщений
    inComing: {
        schema: inComing,
        required: true,
        message: {
            required: path => `Не указаны параметры обработки очереди входящих сообщений (${path})`
        }
    },
    //Параметры отправки E-Mail уведомлений
    mail: {
        schema: mail,
        required: true,
        message: {
            required: path => `Не указаны параметры отправки E-Mail уведомлений (${path})`
        }
    }
});

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации общих параметров сервера приложений
exports.common = common;
//Схема валидации записи журнала работы сервиса обмена
exports.dbConnect = dbConnect;
//Схема валидации параметров обработки очереди исходящих сообщений
exports.outGoing = outGoing;
//Схема валидации параметров обработки очереди входящих сообщений
exports.inComing = inComing;
//Схема валидации параметров отправки E-Mail уведомлений
exports.mail = mail;
//Схема валидации файла конфигурации
exports.config = config;
