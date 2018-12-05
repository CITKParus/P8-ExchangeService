/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель сообщений обмена с обработчиком очереди исходящих сообщений
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { Service } = require("./obj_service"); //Схема валидации сервиса
const { ServiceFunction } = require("./obj_service_function"); //Схема валидации функции сервиса
const {
    NQUEUE_EXEC_STATE_INQUEUE,
    NQUEUE_EXEC_STATE_APP,
    NQUEUE_EXEC_STATE_APP_OK,
    NQUEUE_EXEC_STATE_APP_ERR,
    NQUEUE_EXEC_STATE_DB,
    NQUEUE_EXEC_STATE_DB_OK,
    NQUEUE_EXEC_STATE_DB_ERR,
    NQUEUE_EXEC_STATE_OK,
    NQUEUE_EXEC_STATE_ERR
} = require("./obj_queue"); //Схема валидации сообщения очереди обмена

//------------
// Тело модуля
//------------

//Валидация данных сообщения очереди
const validateBuffer = val => {
    //Либо null
    if (val === null) {
        return true;
    } else {
        //Либо данные для формирования Buffer
        const s = new Schema({
            type: {
                type: String,
                required: true
            },
            data: {
                type: Array,
                required: true
            }
        });
        const errs = s.validate(val, { strip: false });
        return errs.length == 0;
    }
};

//------------------
//  Интерфейс модуля
//------------------

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
    //Состояние обработки сообщения очереди обмена
    nExecState: {
        type: Number,
        enum: [
            NQUEUE_EXEC_STATE_INQUEUE,
            NQUEUE_EXEC_STATE_APP,
            NQUEUE_EXEC_STATE_APP_OK,
            NQUEUE_EXEC_STATE_APP_ERR,
            NQUEUE_EXEC_STATE_DB,
            NQUEUE_EXEC_STATE_DB_OK,
            NQUEUE_EXEC_STATE_DB_ERR,
            NQUEUE_EXEC_STATE_OK,
            NQUEUE_EXEC_STATE_ERR
        ],
        required: true,
        message: {
            type: path =>
                `Состояние обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение состояния обработки сообщения очереди обмена (${path}) не поддерживается`,
            required: path => `Не указано состояние обработки сообщения очереди обмена (${path})`
        }
    },
    //Данные сообщения очереди обмена
    blMsg: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные записи журнала обмена для обработки (${path}) имеют некорректный тип данных (ожидалось - null или {type: String, data: Array})`,
            required: path => `Не указаны данные сообщения очереди обмена (${path})`
        }
    },
    //Данные ответа на сообщение очереди обмена
    blResp: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные ответа (${path}) имеют некорректный тип данных (ожидалось - null или {type: String, data: Array})`,
            required: path => `Не указаны данные ответа (${path})`
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
}).validator({
    required: val => typeof val != "undefined"
});

//Схема валидации ответа обработчика очереди исходящих сообщений
exports.OutQueueProcessorTaskResult = new Schema({
    //Состояние обработки сообщения очереди обмена
    nExecState: {
        type: Number,
        enum: [
            NQUEUE_EXEC_STATE_INQUEUE,
            NQUEUE_EXEC_STATE_APP,
            NQUEUE_EXEC_STATE_APP_OK,
            NQUEUE_EXEC_STATE_APP_ERR,
            NQUEUE_EXEC_STATE_DB,
            NQUEUE_EXEC_STATE_DB_OK,
            NQUEUE_EXEC_STATE_DB_ERR,
            NQUEUE_EXEC_STATE_OK,
            NQUEUE_EXEC_STATE_ERR
        ],
        required: true,
        message: {
            type: path =>
                `Состояние обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение состояния обработки сообщения очереди обмена (${path}) не поддерживается`,
            required: path => `Не указано состояние обработки сообщения очереди обмена (${path})`
        }
    },
    //Информация от обработчика сообщения очереди обмена
    sExecMsg: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Информация от обработчика сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указана информация от обработчика сообщения очереди обмена (${path})`
        }
    },
    //Данные сообщения очереди обмена
    blMsg: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - null или {type: String, data: Array})`,
            required: path => `Не указаны данные сообщения очереди обмена (${path})`
        }
    },
    //Данные ответа сообщения очереди обмена
    blResp: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные ответа сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - null или {type: String, data: Array})`,
            required: path => `Не указаны данные ответа сообщения очереди обмена (${path})`
        }
    }
}).validator({
    required: val => typeof val != "undefined"
});
