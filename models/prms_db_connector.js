/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров процедур модуля взаимодействия с БД (класс DBConnector)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
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

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров конструктора
exports.DBConnector = new Schema({
    //Имя пользователя БД
    sUser: {
        type: String,
        required: true,
        message: {
            type: "Имя пользователя БД (sUser) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано имя пользователя БД (sUser)"
        }
    },
    //Пароль пользователя БД
    sPassword: {
        type: String,
        required: true,
        message: {
            type: "Пароль пользователя БД (sPassword) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан пароль пользователя БД (sPassword)"
        }
    },
    //Строка подключения к БД
    sConnectString: {
        type: String,
        required: true,
        message: {
            type: "Строка подключения к БД (sConnectString) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указана строка подключения к БД (sConnectString)"
        }
    },
    //Наименование сервера приложений в сессии БД
    sSessionAppName: {
        type: String,
        required: true,
        message: {
            type:
                "Наименование сервера приложений в сессии БД (sSessionAppName) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано наименование сервера приложений в сессии БД (sSessionAppName)"
        }
    },
    //Наименование пользовательского модуля для взаимодействия с БД
    sConnectorModule: {
        type: String,
        required: true,
        message: {
            type:
                "Наименование пользовательского модуля для взаимодействия с БД (sConnectorModule) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано наименование пользовательского модуля для взаимодействия с БД (sConnectorModule)"
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
    }
});
