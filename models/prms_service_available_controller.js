/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций контроллера доступности сервисов (класс ServiceAvailableController)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { defServices } = require("./obj_services"); //Схема валидации списка сервисов
const { Notifier } = require("../core/notifier"); //Класс рассылки уведомлений
const { Logger } = require("../core/logger"); //Класс для протоколирования работы
const { DBConnector } = require("../core/db_connector"); //Класс взаимодействия в БД

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров конструктора
exports.ServiceAvailableController = new Schema({
    //Объект для рассылки уведомлений
    notifier: {
        type: Notifier,
        required: true,
        message: {
            type: path =>
                `Объект для рассылки уведомлений (${path}) имеет некорректный тип данных (ожидалось - Notifier)`,
            required: path => `Не указан объект для рассылки уведомлений (${path})`
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
    //Объект для взаимодействия с БД
    dbConn: {
        type: DBConnector,
        required: true,
        message: {
            type: path =>
                `Объект для взаимодействия с БД (${path}) имеет некорректный тип данных (ожидалось - DBConnector)`,
            required: path => `Не указан объект для взаимодействия с БД (${path})`
        }
    }
});

//Схема валидации параметров функции запуска контроллера
exports.startController = new Schema({
    //Список обслуживаемых сервисов
    services: defServices(true, "services")
});
