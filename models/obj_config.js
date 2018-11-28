/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель объекта конфигурации приложения
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//------------------
//  Тело моделя
//------------------

//Функция проверки значения размера блока одновременно обрабатываемых исходящих сообщений
const checkMaxWorkers = val => val >= 1 && val <= 100 && Number.isInteger(val);

//Функция проверки значения интервала проверки наличия исходящих сообщений
const checkCheckTimeout = val => val >= 100 && val <= 60000 && Number.isInteger(val);

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
    //Размер блока одновременно обрабатываемых исходящих сообщений
    nMaxWorkers: {
        type: Number,
        required: true,
        use: { checkMaxWorkers },
        message: {
            type:
                "Размер блока одновременно обрабатываемых исходящих сообщений (nPortionSize) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан размер блока одновременно обрабатываемых исходящих сообщений (nPortionSize)",
            checkMaxWorkers:
                "Значение размера блока одновременно обрабатываемых исходящих сообщений (nPortionSize) должно быть целым числом в диапазоне от 1 до 100"
        }
    },
    //Интервал проверки наличия исходящих сообщений (мс)
    nCheckTimeout: {
        type: Number,
        required: true,
        use: { checkCheckTimeout },
        message: {
            type:
                "Интервал проверки наличия исходящих сообщений (nCheckTimeout) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан интервал проверки наличия исходящих сообщений (nCheckTimeout)",
            checkCheckTimeout:
                "Значение интервала проверки наличия исходящих сообщений (nCheckTimeout) должно быть целым числом в диапазоне от 100 до 60000"
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
    }
});

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации записи журнала работы сервиса обмена
exports.dbConnect = dbConnect;
//Схема валидации параметров обработки очереди исходящих сообщений
exports.outGoing = outGoing;
//Схема валидации файла конфигурации
exports.config = config;
