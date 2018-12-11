/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций обработчика очереди входящих сообщений (класс InQueue)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { inComing } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { defServices } = require("./obj_services"); //Схема валидации списка сервисов
const { DBConnector } = require("../core/db_connector"); //Класс взаимодействия в БД
const { Logger } = require("../core/logger"); //Класс для протоколирования работы

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров конструктора
exports.InQueue = new Schema({
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
    }
});

//Схема валидации параметров функции запуска обслуживания очереди
exports.startProcessing = new Schema({
    //Список обслуживаемых сервисов
    services: defServices(true, "services")
});
