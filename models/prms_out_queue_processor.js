/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций модуля обработки исходящих сообщений
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { Queue } = require("./obj_queue"); //Схема валидации позиции очереди
const { OutQueueProcessorTask } = require("./obj_out_queue_processor"); //Схемы валидации объектов обработчика исходящих сообщений
const { Service } = require("./obj_service"); //Схема валидации сервиса
const { ServiceFunction } = require("./obj_service_function"); //Схема валидации функции сервиса

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров функции отправки ошибки обработки
exports.sendErrorResult = new Schema({
    //Сообщение об ошибке
    sMessage: {
        type: String,
        required: true,
        message: {
            type: path => `Сообщение об ошибке (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано сообщение об ошибке (${path})`
        }
    }
});

//Схема валидации параметров функции обработчки сообщения сервером приложений
exports.appProcess = new Schema({
    //Обрабатываемое сообщение очереди
    queue: {
        schema: Queue,
        required: true,
        message: {
            required: path => `Не указано обрабатываемое сообщение очреди (${path})`
        }
    },
    //Cервис-обработчик
    service: {
        schema: Service,
        required: true,
        message: {
            required: path => `Не указан сервис для обработки сообщения очереди (${path})`
        }
    },
    //Функция сервиса-обработчика
    function: {
        schema: ServiceFunction,
        required: true,
        message: {
            required: path => `Не указана функция сервиса для обработки сообщения очереди (${path})`
        }
    }
});

//Схема валидации параметров функции обработчки сообщения сервером БД
exports.dbProcess = new Schema({
    //Обрабатываемое сообщение очереди
    queue: {
        schema: Queue,
        required: true,
        message: {
            required: path => `Не указано обрабатываемое сообщение очреди (${path})`
        }
    },
    //Функция сервиса-обработчика
    function: {
        schema: ServiceFunction,
        required: true,
        message: {
            required: path => `Не указана функция сервиса для обработки сообщения очереди (${path})`
        }
    }
});

//Параметры функции обработки сообщения
exports.processTask = new Schema({
    //Задача обработки
    task: {
        schema: OutQueueProcessorTask,
        required: true,
        message: {
            required: path => `Не указана задача для обработки (${path})`
        }
    }
});
