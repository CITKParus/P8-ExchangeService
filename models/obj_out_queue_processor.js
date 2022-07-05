/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель сообщений обмена с обработчиком очереди исходящих сообщений
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { dbConnect } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { Service } = require("./obj_service"); //Схема валидации сервиса
const { ServiceFunction } = require("./obj_service_function"); //Схема валидации функции сервиса

//----------
// Константы
//----------

//Состояния обработки сообщений очереди обмена
const STASK_RESULT_OK = "OK"; //Обработано успешно
const STASK_RESULT_ERR = "ERR"; //Обработано с ошибками
const STASK_RESULT_UNAUTH = "UNAUTH"; //Не обработано из-за отсутсвия аутентификации

//------------------
//  Интерфейс модуля
//------------------

//Константы
exports.STASK_RESULT_OK = STASK_RESULT_OK;
exports.STASK_RESULT_ERR = STASK_RESULT_ERR;
exports.STASK_RESULT_UNAUTH = STASK_RESULT_UNAUTH;

//Схема валидации задачи обработчику очереди исходящих сообщений
exports.OutQueueProcessorTask = new Schema({
    //Идентификатор записи журнала обмена для обработки
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор записи журнала обмена для обработки (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор записи журнала обмена для обработки (${path})`
        }
    },
    //Параметры подключения к БД
    connectSettings: {
        schema: dbConnect,
        required: true,
        message: {
            required: path => `Не указаны параметры подключения к БД (${path})`
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

//Схема валидации ответа обработчика очереди исходящих сообщений
exports.OutQueueProcessorTaskResult = new Schema({
    //Состояние обработки сообщения очереди обмена
    sResult: {
        type: String,
        enum: [STASK_RESULT_OK, STASK_RESULT_ERR, STASK_RESULT_UNAUTH],
        required: true,
        message: {
            type: path =>
                `Состояние обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path => `Значение состояния обработки сообщения очереди обмена (${path}) не поддерживается`,
            required: path => `Не указано состояние обработки сообщения очереди обмена (${path})`
        }
    },
    //Информация от обработчика сообщения очереди обмена
    sMsg: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Информация от обработчика сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указана информация от обработчика сообщения очереди обмена (${path})`
        }
    }
}).validator({
    required: val => typeof val != "undefined"
});

//Схема валидации результата работы функции "предобработки" сообщения очереди сервером приложений
exports.OutQueueProcessorFnBefore = new Schema({
    //Параметры запроса удалённому сервису
    options: {
        type: Object,
        required: false,
        message: {
            type: path =>
                `Параметры запроса удалённому сервису (${path}) имеют некорректный тип данных (ожидалось - Object, см. документацию к REQUEST - https://github.com/request/request)`,
            required: path => `Не указаны параметры запроса удалённому сервису (${path})`
        }
    },
    //Обработанное сообщение очереди
    blMsg: {
        type: Buffer,
        required: false,
        message: {
            type: path =>
                `Обработанное сообщение очереди  (${path}) имеет некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указано обработанное сообщение очереди (${path})`
        }
    },
    //Флаг ошибки аутентификации на удаленном сервисе
    bUnAuth: {
        type: Boolean,
        required: false,
        message: {
            type: path =>
                `Флаг ошибки аутентификации на удаленном сервисе  (${path}) имеет некорректный тип данных (ожидалось - Boolean)`,
            required: path => `Не указан флаг ошибки аутентификации на удаленном сервисе (${path})`
        }
    },
    //Контекст сервиса
    sCtx: {
        type: String,
        required: false,
        message: {
            type: path => `Контектс сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан контекст сервиса (${path})`
        }
    },
    //Дата истечения контекста
    dCtxExp: {
        type: Date,
        required: false,
        message: {
            type: path => `Дата истечения контекста (${path}) имеет некорректный тип данных (ожидалось - Date)`,
            required: path => `Не указана дата истечения контекста (${path})`
        }
    },
    //Флаг прекращения дальнейшей обработки сообщения
    bStopPropagation: {
        type: Boolean,
        required: false,
        message: {
            type: path =>
                `Флаг прекращения дальнейшей обработки сообщения  (${path}) имеет некорректный тип данных (ожидалось - Boolean)`,
            required: path => `Не указан флаг прекращения дальнейшей обработки сообщения (${path})`
        }
    }
});

//Схема валидации результата работы функции "постобработки" сообщения очереди сервером приложений
exports.OutQueueProcessorFnAfter = new Schema({
    //Результат обработки ответа удалённого сервиса
    blResp: {
        type: Buffer,
        required: false,
        message: {
            type: path =>
                `Результат обработки ответа удалённого сервиса  (${path}) имеет некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указан результат обработки ответа удалённого сервиса (${path})`
        }
    },
    //Флаг ошибки аутентификации на удаленном сервисе
    bUnAuth: {
        type: Boolean,
        required: false,
        message: {
            type: path =>
                `Флаг ошибки аутентификации на удаленном сервисе  (${path}) имеет некорректный тип данных (ожидалось - Boolean)`,
            required: path => `Не указан флаг ошибки аутентификации на удаленном сервисе (${path})`
        }
    },
    //Контекст сервиса
    sCtx: {
        type: String,
        required: false,
        message: {
            type: path => `Контектс сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан контекст сервиса (${path})`
        }
    },
    //Дата истечения контекста
    dCtxExp: {
        type: Date,
        required: false,
        message: {
            type: path => `Дата истечения контекста (${path}) имеет некорректный тип данных (ожидалось - Date)`,
            required: path => `Не указана дата истечения контекста (${path})`
        }
    }
});
