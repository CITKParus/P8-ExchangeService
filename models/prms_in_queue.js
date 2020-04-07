/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций обработчика очереди входящих сообщений (класс InQueue)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { IncomingMessage, ServerResponse } = require("http"); //Работа с HTTP протоколом
const { common, inComing } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { defServices } = require("./obj_services"); //Схема валидации списка сервисов
const { DBConnector } = require("../core/db_connector"); //Класс взаимодействия в БД
const { Logger } = require("../core/logger"); //Класс для протоколирования работы
const { Service } = require("./obj_service"); //Схема валидации сервиса
const { ServiceFunction } = require("./obj_service_function"); //Схема валидации функции сервиса
const { Notifier } = require("../core/notifier"); //Класс рассылки уведомлений

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров конструктора
exports.InQueue = new Schema({
    //Общие параметры сервера приложений
    common: {
        schema: common,
        required: true,
        message: {
            required: path => `Не указаны общие параметры сервера приложений (${path})`
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
    //Объект для взаимодействия с БД
    dbConn: {
        type: DBConnector,
        required: true,
        message: {
            type: path =>
                `Объект для взаимодействия с БД (${path}) имеет некорректный тип данных (ожидалось - DBConnector)`,
            required: path => `Не указан объект для взаимодействия с БД (${path})`
        }
    },
    //Объект для протоколирования работы
    logger: {
        type: Logger,
        required: true,
        message: {
            type: path =>
                `Объект для протоколирования работы (${path}) имеет некорректный тип данных (ожидалось - Logger)`,
            required: path => `Не указаны объект для протоколирования работы (${path})`
        }
    },
    //Объект для рассылки уведомлений
    notifier: {
        type: Notifier,
        required: true,
        message: {
            type: path =>
                `Объект для рассылки уведомлений (${path}) имеет некорректный тип данных (ожидалось - Notifier)`,
            required: path => `Не указан объект для рассылки уведомлений (${path})`
        }
    }
});

//Схема валидации параметров функции обработки входящего сообщения
exports.processMessage = new Schema({
    //Входящее сообщение
    req: {
        type: IncomingMessage,
        required: true,
        message: {
            type: path =>
                `Входящее сообщение (${path}) имеет некорректный тип данных (ожидалось - IncomingMessage, см. документацию к Node.JS HTTP - https://nodejs.org/dist/latest-v10.x/docs/api/http.html#http_class_http_incomingmessage)`,
            required: path => `Не указано входящее сообщение (${path})`
        }
    },
    //Ответ на входящее сообщение
    res: {
        type: ServerResponse,
        required: true,
        message: {
            type: path =>
                `Ответ на входящие сообщение (${path}) имеет некорректный тип данных (ожидалось - ServerResponse, см. документацию к Node.JS HTTP - https://nodejs.org/dist/latest-v10.x/docs/api/http.html#http_class_http_serverresponse)`,
            required: path => `Не указан ответ на входящее сообщение (${path})`
        }
    },
    //Cервис-обработчик
    service: {
        schema: Service,
        required: true,
        message: {
            required: path => `Не указан сервис для обработки входящего сообщения (${path})`
        }
    },
    //Функция сервиса-обработчика
    function: {
        schema: ServiceFunction,
        required: true,
        message: {
            required: path => `Не указана функция сервиса для обработки входящего сообщения (${path})`
        }
    }
});

//Схема валидации параметров функции запуска обслуживания очереди
exports.startProcessing = new Schema({
    //Список обслуживаемых сервисов
    services: defServices(true, "services")
});
