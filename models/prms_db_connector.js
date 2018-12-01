/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров функций модуля взаимодействия с БД (класс DBConnector)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { dbConnect } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { NLOG_STATE_INF, NLOG_STATE_WRN, NLOG_STATE_ERR } = require("./obj_log"); //Схемы валидации записи журнала работы сервиса обмена
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
} = require("./obj_queue"); //Схемы валидации сообщения очереди обмена

//----------
// Константы
//----------

//Признак инкремента количества попыток исполнения позиции очереди
NINC_EXEC_CNT_NO = 0; //Не инкрементировать
NINC_EXEC_CNT_YES = 1; //Инкрементировать

//------------------
//  Интерфейс модуля
//------------------

//Константы
exports.NINC_EXEC_CNT_NO = NINC_EXEC_CNT_NO;
exports.NINC_EXEC_CNT_YES = NINC_EXEC_CNT_YES;

//Схема валидации параметров конструктора
exports.DBConnector = new Schema({
    //Параметры подключения к БД
    connectSettings: {
        schema: dbConnect,
        required: true,
        message: {
            required: "Не указаны параметры подключения к БД (connectSettings)"
        }
    }
});

//Схема валидации параметров функции получения списка функций сервиса
exports.getServiceFunctions = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор сервиса (nServiceId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор сервиса (nServiceId)"
        }
    }
});

//Схема валидации параметров функции записи в журнал работы сервиса
exports.putLog = new Schema({
    //Тип сообщения журнала работы сервиса
    nLogState: {
        type: Number,
        enum: [NLOG_STATE_INF, NLOG_STATE_WRN, NLOG_STATE_ERR],
        required: true,
        message: {
            type: "Тип сообщения журнала работы сервиса (nLogState) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение типа сообщения журнала работы сервиса (nLogState) не поддерживается",
            required: "Не указан тип сообщения журнала работы сервиса (nLogState)"
        }
    },
    //Сообщение журнала работы сервиса
    sMsg: {
        type: String,
        required: false,
        message: {
            type: "Сообщение журнала работы сервиса (sMsg) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано сообщение журнала работы сервиса (sMsg)"
        }
    },
    //Идентификатор связанного сервиса
    nServiceId: {
        type: Number,
        required: false,
        message: {
            type:
                "Идентификатор связанного сервиса сообщения журнала работы сервиса (nServiceId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор связанного сервиса сообщения журнала работы сервиса (nServiceId)"
        }
    },
    //Идентификатор связанной функции-обработчика сервиса
    nServiceFnId: {
        type: Number,
        required: false,
        message: {
            type:
                "Идентификатор связанной функции-обработчика сообщения журнала работы сервиса (nServiceFnId) имеет некорректный тип данных (ожидалось - Number)",
            required:
                "Не указан идентификатор связанной функции-обработчика сообщения журнала работы сервиса (nServiceFnId)"
        }
    },
    //Идентификатор связанной позиции очереди обмена
    nQueueId: {
        type: Number,
        required: false,
        message: {
            type:
                "Идентификатор связанной позиции очереди обмена сообщения журнала работы сервиса (nQueueId) имеет некорректный тип данных (ожидалось - Number)",
            required:
                "Не указан идентификатор связанной позиции очереди обмена сообщения журнала работы сервиса (nQueueId)"
        }
    }
});

//Схема валидации параметров функции считывания исходящих сообщений
exports.getOutgoing = new Schema({
    //Количество считываемых сообщений очереди
    nPortionSize: {
        type: Number,
        required: true,
        message: {
            type:
                "Количество считываемых сообщений очереди (nPortionSize) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указано количество считываемых сообщений очереди (nPortionSize)"
        }
    }
});

//Схема валидации параметров функции установки состояния позиции очереди
exports.setQueueState = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор позиции очереди (nQueueId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор позиции очереди (nQueueId)"
        }
    },
    //Код состояния
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
            type: "Код состояния (nExecState) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение кода состояния (nExecState) не поддерживается",
            required: "Не указан код состояния (nExecState)"
        }
    },
    //Сообщение обработчика
    sExecMsg: {
        type: String,
        required: false,
        message: {
            type: "Сообщение обработчика (sExecMsg) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано сообщени обработчика (sExecMsg)"
        }
    },
    //Флаг инкремента количества исполнений
    nIncExecCnt: {
        type: Number,
        enum: [NINC_EXEC_CNT_NO, NINC_EXEC_CNT_YES],
        required: false,
        message: {
            type:
                "Флаг инкремента количества исполнений (nIncExecCnt) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение флага инкремента количества исполнений (nIncExecCnt) не поддерживается",
            required: "Не указан флаг икремента количества исполнений (nIncExecCnt)"
        }
    }
});
