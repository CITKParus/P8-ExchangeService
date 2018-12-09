/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций контроллера доступности сервисов (класс ServiceAvailableController)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { defServices } = require("./obj_services"); //Схема валидации списка сервисов
const { mail } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { Logger } = require("../core/logger"); //Класс для протоколирования работы

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров конструктора
exports.ServiceAvailableController = new Schema({
    //Параметры отправки E-Mail уведомлений
    mail: {
        schema: mail,
        required: true,
        message: {
            required: path => `Не указаны параметры отправки E-Mail уведомлений (${path})`
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

//Схема валидации параметров функции отправки E-Mail уведомления о недоступности сервиса
exports.sendUnAvailableMail = new Schema({
    //Список адресов E-Mail для отправки уведомления
    sTo: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Список адресов E-Mail для отправки уведомления (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан cписок адресов E-Mail для отправки уведомления (${path})`
        }
    },
    //Заголовок сообщения
    sSubject: {
        type: String,
        required: true,
        message: {
            type: path => `Заголовок сообщения (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан заголовок сообщения (${path})`
        }
    },
    //Текст уведомления
    sMessage: {
        type: String,
        required: true,
        message: {
            type: path => `Текст уведомления (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан текст уведомления (${path})`
        }
    }
});

//Схема валидации параметров функции запуска контроллера
exports.startController = new Schema({
    //Список обслуживаемых сервисов
    services: defServices(true, "services")
});
