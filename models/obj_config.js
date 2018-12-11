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

//Функция проверки значения размера блока одновременно обрабатываемых исходящих сообщений
const validateMaxWorkers = val => val >= 1 && val <= 100 && Number.isInteger(val);

//Функция проверки значения интервала проверки наличия исходящих сообщений
const validateCheckTimeout = val => val >= 1 && val <= 60000 && Number.isInteger(val);

//Функция проверки значения порта сервера обслуживания входящих сообщений
const validateInComingPort = val => val >= 0 && val <= 65535 && Number.isInteger(val);

//Схема валидации параметров подключения к БД
const dbConnect = new Schema({
    //Пользователь БД
    sUser: {
        type: String,
        required: true,
        message: {
            type: "Имя пользователя БД (sUser) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано имя пользователя БД (sUser)"
        }
    },
    //Пароль пользователя БД
    sPassword: {
        type: String,
        required: true,
        message: {
            type: "Пароль пользователя БД (sPassword) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан пароль пользователя БД (sPassword)"
        }
    },
    //Строка подключения к БД
    sConnectString: {
        type: String,
        required: true,
        message: {
            type: "Строка подключения к БД (sConnectString) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указана строка подключения к БД (sConnectString)"
        }
    },
    //Наименование сервера приложений в сессии БД
    sSessionAppName: {
        type: String,
        required: true,
        message: {
            type:
                "Наименование сервера приложений в сессии БД (sSessionAppName) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано наименование сервера приложений в сессии БД (sSessionAppName)"
        }
    },
    //Наименование подключаемого модуля обслуживания БД
    sConnectorModule: {
        type: String,
        required: true,
        message: {
            type:
                "Наименование подключаемого модуля обслуживания БД (sConnectorModule) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано наименование подключаемого модуля обслуживания БД (sConnectorModule)"
        }
    }
});

//Схема валидации параметров обработки очереди исходящих сообщений
const outGoing = new Schema({
    //Количество одновременно обрабатываемых исходящих сообщений
    nMaxWorkers: {
        type: Number,
        required: true,
        use: { validateMaxWorkers },
        message: {
            type:
                "Количество одновременно обрабатываемых исходящих сообщений (nMaxWorkers) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указано количество одновременно обрабатываемых исходящих сообщений (nMaxWorkers)",
            validateMaxWorkers:
                "Количество одновременно обрабатываемых исходящих сообщений (nMaxWorkers) должно быть целым числом в диапазоне от 1 до 100"
        }
    },
    //Интервал проверки наличия исходящих сообщений (мс)
    nCheckTimeout: {
        type: Number,
        required: true,
        use: { validateCheckTimeout },
        message: {
            type:
                "Интервал проверки наличия исходящих сообщений (nCheckTimeout) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан интервал проверки наличия исходящих сообщений (nCheckTimeout)",
            validateCheckTimeout:
                "Значение интервала проверки наличия исходящих сообщений (nCheckTimeout) должно быть целым числом в диапазоне от 100 до 60000"
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
            type: "Порт сервера входящих сообщений (nPort) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан порт сервера входящих сообщений (nPort)",
            validateInComingPort:
                "Порт сервера входящих сообщений (nPort) должен быть целым числом в диапазоне от  0 до 65535"
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
            type: "Адреc сервера SMTP (sHost) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан aдреc сервера SMTP (sHost)"
        }
    },
    //Порт сервера SMTP
    nPort: {
        type: Number,
        required: true,
        message: {
            type: "Порт сервера SMTP (nPort) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан порт сервера SMTP (nPort)"
        }
    },
    //Имя пользователя SMTP-сервера
    sUser: {
        type: String,
        required: true,
        message: {
            type: "Имя пользователя SMTP-сервера (sUser) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано имя пользователя SMTP-сервера (sUser)"
        }
    },
    //Пароль пользователя SMTP-сервера
    sPass: {
        type: String,
        required: true,
        message: {
            type: "Пароль пользователя SMTP-сервера (sPass) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан пароль пользователя SMTP-сервера (sPass)"
        }
    },
    //Наименование отправителя для исходящих сообщений
    sFrom: {
        type: String,
        required: true,
        message: {
            type:
                "Наименование отправителя для исходящих сообщений (sFrom) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано наименование отправителя для исходящих сообщений (sFrom)"
        }
    }
});

//Схема валидации файла конфигурации
const config = new Schema({
    //Параметры подключения к БД
    dbConnect: {
        schema: dbConnect,
        required: true,
        message: {
            required: "Не указаны параметры подключения к БД (dbConnect)"
        }
    },
    //Параметры обработки очереди исходящих сообщений
    outGoing: {
        schema: outGoing,
        required: true,
        message: {
            required: "Не указаны параметры обработки очереди исходящих сообщений (outGoing)"
        }
    },
    //Параметры отправки E-Mail уведомлений
    mail: {
        schema: mail,
        required: true,
        message: {
            required: "Не указаны параметры отправки E-Mail уведомлений (mail)"
        }
    }
});

//------------------
//  Интерфейс модуля
//------------------

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
