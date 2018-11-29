/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель сообщений обмена с обработчиком очереди исходящих сообщений
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { Queue } = require("./obj_queue"); //Схема валидации сообщения очереди обмена
const { Service } = require("./obj_service"); //Схема валидации сервиса
const { NQUEUE_EXEC_STATE_APP_OK, NQUEUE_EXEC_STATE_APP_ERR } = require("./obj_queue"); //Схема валидации сообщения очереди обмена

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации задачи обработчику очереди исходящих сообщений
exports.OutQueueProcessorTask = new Schema({
    //Запись журнала обмена для обработки
    queue: {
        //schema: Queue,
        required: false,
        message: {
            required: "Не указано обрабатываемое сообщение очереди (queue)"
        }
    },
    //Cервис
    service: {
        //schema: Service,
        required: false,
        message: {
            required: "Не указан сервис для обработки сообщения очереди (service)"
        }
    }
});

//Схема валидации ответа обработчика очереди исходящих сообщений
exports.OutQueueProcessorTaskResult = new Schema({
    //Состояние обработки сообщения очереди обмена
    nExecState: {
        type: Number,
        enum: [NQUEUE_EXEC_STATE_APP_OK, NQUEUE_EXEC_STATE_APP_ERR],
        required: true,
        message: {
            type:
                "Состояние обработки сообщения очереди обмена (nExecState) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение состояния обработки сообщения очереди обмена (nExecState) не поддерживается",
            required: "Не указано состояние обработки сообщения очереди обмена (nExecState)"
        }
    },
    //Информация от обработчика сообщения очереди обмена
    sExecMsg: {
        type: String,
        required: false,
        message: {
            type:
                "Информация от обработчика сообщения очереди обмена (sExecMsg) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указана информация от обработчика сообщения очереди обмена (sExecMsg)"
        }
    },
    //Данные ответа
    blResp: {
        type: Buffer,
        required: false,
        message: {
            type: "Данные ответа сообщения очереди обмена (blResp) имеют некорректный тип данных (ожидалось - Buffer)",
            required: "Не указаны данные ответа сообщения очереди обмена (blResp)"
        }
    }
});
