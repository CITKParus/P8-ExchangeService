/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций модуля обработки исходящих сообщений
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { OutQueueProcessorTask } = require("./obj_out_queue_processor"); //Схемы валидации объектов обработчика исходящих сообщений

//------------
// Тело модуля
//------------

//Валидация данных сообщения очереди
const validateBuffer = val => {
    //Либо null
    if (val === null) {
        return true;
    } else {
        //Либо Buffer
        return val instanceof Buffer;
    }
};

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
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции отправки успеха обработки
exports.sendOKResult = new Schema({
    //Данные сообщения очереди обмена
    blMsg: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - null или Buffer)`,
            required: path => `Не указаны данные сообщения очереди обмена (${path})`
        }
    },
    //Данные ответа сообщения очереди обмена
    blResp: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные ответа сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - null или Buffer)`,
            required: path => `Не указаны данные ответа сообщения очереди обмена (${path})`
        }
    }
}).validator({ required: val => typeof val != "undefined" });

//Параметры функции отправки сообщения родителю без обработки
exports.sendUnChange = new Schema({
    //Задача обработки
    task: {
        schema: OutQueueProcessorTask,
        required: true,
        message: {
            required: path => `Не указана задача для обработки (${path})`
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
