/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций обработчика очереди исходящих сообщений (класс OutQueue)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { outGoing } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { defServices } = require("./obj_services"); //Схема валидации списка сервисов
const { Queue } = require("./obj_queue"); //Схема валидации сообщения очереди
const { DBConnector } = require("../core/db_connector"); //Класс взаимодействия в БД
const { Logger } = require("../core/logger"); //Класс для протоколирования работы

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров конструктора
exports.OutQueue = new Schema({
    //Параметры обработки очереди исходящих сообщений
    outGoing: {
        schema: outGoing,
        required: true,
        message: {
            required: "Не указаны параметры обработки очереди исходящих сообщений (outGoing)"
        }
    },
    //Объект для взаимодействия с БД
    dbConn: {
        type: DBConnector,
        required: true,
        message: {
            type: "Объект для взаимодействия с БД (dbConn) имеет некорректный тип данных (ожидалось - DBConnector)",
            required: "Не указан объект для взаимодействия с БД (dbConn)"
        }
    },
    //Объект для протоколирования работы
    logger: {
        type: Logger,
        required: true,
        message: {
            type: "Объект для протоколирования работы (logger) имеет некорректный тип данных (ожидалось - Logger)",
            required: "Не указаны объект для протоколирования работы (logger)"
        }
    }
});

//Схема валидации параметров функции установки финальных статусов сообщения в БД
exports.finalise = new Schema({
    //Обрабатываемое исходящее сообщение
    queue: {
        schema: Queue,
        required: true,
        message: {
            required: "Не указано обрабатываемое исходящее сообщение (queue)"
        }
    }
});

//Схема валидации параметров функции запуска обработчика БД
exports.dbProcess = new Schema({
    //Обрабатываемое исходящее сообщение
    queue: {
        schema: Queue,
        required: true,
        message: {
            required: "Не указано обрабатываемое исходящее сообщение (queue)"
        }
    }
});

//Схема валидации параметров функции передачи исходящего сообшения на обработку
exports.processMessage = new Schema({
    //Обрабатываемое исходящее сообщение
    queue: {
        schema: Queue,
        required: true,
        message: {
            required: "Не указано обрабатываемое исходящее сообщение (queue)"
        }
    }
});

//Схема валидации параметров функции запуска обслуживания очереди
exports.startProcessing = new Schema({
    //Список обслуживаемых сервисов
    services: defServices(true, "services")
});
