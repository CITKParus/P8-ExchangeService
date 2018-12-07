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

//-------------
//  Тело модуля
//-------------

const validateChildProcess = val => {
    return val["constructor"]["name"] === "ChildProcess";
};

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
            required: path => `Не указаны параметры обработки очереди исходящих сообщений (${path})`
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

//Схема валидации параметров функции добавления идентификатора сообщения очереди в список обрабатываемых
exports.addInProgress = new Schema({
    //Идентификатор сообщения
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сообщения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сообщения (${path})`
        }
    }
});

//Схема валидации параметров функции удаления идентификатора сообщения очереди из списка обрабатываемых
exports.rmInProgress = new Schema({
    //Идентификатор сообщения
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сообщения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сообщения (${path})`
        }
    }
});

//Схема валидации параметров функции проверки наличия идентификатора сообщения очереди в списке обрабатываемых
exports.isInProgress = new Schema({
    //Идентификатор сообщения
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сообщения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сообщения (${path})`
        }
    }
});

//Схема валидации параметров функции запуска обработчика сообщения очереди
exports.startQueueProcessor = new Schema({
    //Обрабатываемое сообщение очереди
    queue: {
        schema: Queue,
        required: true,
        message: {
            required: path => `Не указано обрабатываемое сообщение очреди (${path})`
        }
    },
    //Процесс обработчика
    proc: {
        use: { validateChildProcess },
        required: true,
        message: {
            validateChildProcess: path =>
                `Процесс обработчика (${path}) имеет некорректный тип данных (ожидалось - ChildProcess)`,
            required: path => `Не указан процесс обработчика (${path})`
        }
    }
});

//Схема валидации параметров функции останова обработчика сообщения очереди
exports.stopQueueProcessor = new Schema({
    //Идентификатор сообщения
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сообщения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сообщения (${path})`
        }
    },
    //Процесс обработчика
    proc: {
        use: { validateChildProcess },
        required: true,
        message: {
            validateChildProcess: path =>
                `Процесс обработчика (${path}) имеет некорректный тип данных (ожидалось - ChildProcess)`,
            required: path => `Не указан процесс обработчика (${path})`
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
            required: path => `Не указано обрабатываемое исходящее сообщение (${path})`
        }
    }
});

//Схема валидации параметров функции запуска обслуживания очереди
exports.startProcessing = new Schema({
    //Список обслуживаемых сервисов
    services: defServices(true, "services")
});
