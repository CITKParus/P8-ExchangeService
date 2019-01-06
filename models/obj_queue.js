/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель сообщения очереди обмена
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//----------
// Константы
//----------

//Состояния исполнения сообщений очереди обмена
const NQUEUE_EXEC_STATE_INQUEUE = 0; //Поставлено в очередь
const NQUEUE_EXEC_STATE_APP = 1; //Обрабатывается сервером приложений
const NQUEUE_EXEC_STATE_APP_OK = 2; //Успешно обработано сервером приложений
const NQUEUE_EXEC_STATE_APP_ERR = 3; //Ошибка обработки сервером приложений
const NQUEUE_EXEC_STATE_DB = 4; //Обрабатывается СУБД
const NQUEUE_EXEC_STATE_DB_OK = 5; //Успешно обработано СУБД
const NQUEUE_EXEC_STATE_DB_ERR = 6; //Ошибка обработки СУБД
const NQUEUE_EXEC_STATE_OK = 7; //Обработано успешно
const NQUEUE_EXEC_STATE_ERR = 8; //Обработано с ошибками
const SQUEUE_EXEC_STATE_INQUEUE = "INQUEUE"; //Поставлено в очередь (строковый код)
const SQUEUE_EXEC_STATE_APP = "APP"; //Обрабатывается сервером приложений (строковый код)
const SQUEUE_EXEC_STATE_APP_OK = "APP_OK"; //Успешно обработано сервером приложений (строковый код)
const SQUEUE_EXEC_STATE_APP_ERR = "APP_ERR"; //Ошибка обработки сервером приложений (строковый код)
const SQUEUE_EXEC_STATE_DB = "DB"; //Обрабатывается СУБД (строковый код)
const SQUEUE_EXEC_STATE_DB_OK = "DB_OK"; //Успешно обработано СУБД (строковый код)
const SQUEUE_EXEC_STATE_DB_ERR = "DB_ERR"; //Ошибка обработки СУБД (строковый код)
const SQUEUE_EXEC_STATE_OK = "OK"; //Обработано успешно (строковый код)
const SQUEUE_EXEC_STATE_ERR = "ERR"; //Обработано с ошибками (строковый код)

//Коды результатов исполнения обработчика сообщения
const SPRC_RESP_RESULT_OK = "OK"; //Обработано успешно
const SPRC_RESP_RESULT_ERR = "ERR"; //Ошибка обработки
const SPRC_RESP_RESULT_UNAUTH = "UNAUTH"; //Неаутентифицирован

//Флаг сброса данных сообщения
const NQUEUE_RESET_DATA_NO = 0; //Не сбрасывать
const NQUEUE_RESET_DATA_YES = 1; //Сбросить

//------------------
//  Интерфейс модуля
//------------------

//Константы
exports.NQUEUE_EXEC_STATE_INQUEUE = NQUEUE_EXEC_STATE_INQUEUE;
exports.NQUEUE_EXEC_STATE_APP = NQUEUE_EXEC_STATE_APP;
exports.NQUEUE_EXEC_STATE_APP_OK = NQUEUE_EXEC_STATE_APP_OK;
exports.NQUEUE_EXEC_STATE_APP_ERR = NQUEUE_EXEC_STATE_APP_ERR;
exports.NQUEUE_EXEC_STATE_DB = NQUEUE_EXEC_STATE_DB;
exports.NQUEUE_EXEC_STATE_DB_OK = NQUEUE_EXEC_STATE_DB_OK;
exports.NQUEUE_EXEC_STATE_DB_ERR = NQUEUE_EXEC_STATE_DB_ERR;
exports.NQUEUE_EXEC_STATE_OK = NQUEUE_EXEC_STATE_OK;
exports.NQUEUE_EXEC_STATE_ERR = NQUEUE_EXEC_STATE_ERR;
exports.SQUEUE_EXEC_STATE_INQUEUE = SQUEUE_EXEC_STATE_INQUEUE;
exports.SQUEUE_EXEC_STATE_APP = SQUEUE_EXEC_STATE_APP;
exports.SQUEUE_EXEC_STATE_APP_OK = SQUEUE_EXEC_STATE_APP_OK;
exports.SQUEUE_EXEC_STATE_APP_ERR = SQUEUE_EXEC_STATE_APP_ERR;
exports.SQUEUE_EXEC_STATE_DB = SQUEUE_EXEC_STATE_DB;
exports.SQUEUE_EXEC_STATE_DB_OK = SQUEUE_EXEC_STATE_DB_OK;
exports.SQUEUE_EXEC_STATE_DB_ERR = SQUEUE_EXEC_STATE_DB_ERR;
exports.SQUEUE_EXEC_STATE_OK = SQUEUE_EXEC_STATE_OK;
exports.SQUEUE_EXEC_STATE_ERR = SQUEUE_EXEC_STATE_ERR;
exports.SPRC_RESP_RESULT_OK = SPRC_RESP_RESULT_OK;
exports.SPRC_RESP_RESULT_ERR = SPRC_RESP_RESULT_ERR;
exports.SPRC_RESP_RESULT_UNAUTH = SPRC_RESP_RESULT_UNAUTH;
exports.NQUEUE_RESET_DATA_NO = NQUEUE_RESET_DATA_NO;
exports.NQUEUE_RESET_DATA_YES = NQUEUE_RESET_DATA_YES;

//Схема валидации сообщения очереди обмена
exports.Queue = new Schema({
    //Идентификатор сообщения очереди обмена
    nId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор сообщения очереди обмена (nId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор сообщения очереди обмена (nId)"
        }
    },
    //Дата постановки сообщения в очередь обмена
    dInDate: {
        type: Date,
        required: true,
        message: {
            type:
                "Дата постановки сообщения в очередь обмена (dInDate) имеет некорректный тип данных (ожидалось - Date)",
            required: "Не указана дата постановки сообщения в очередь обмена (dInDate)"
        }
    },
    //Дата постановки сообщения в очередь обмена (строковое представление)
    sInDate: {
        type: String,
        required: true,
        message: {
            type:
                "Строковое представление даты постановки сообщения в очередь обмена (sInDate) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано строковое представление даты постановки сообщения в очередь обмена (sInDate)"
        }
    },
    //Пользователь поставивший сообщение в очередь обмена
    sInAuth: {
        type: String,
        required: true,
        message: {
            type:
                "Пользователь, поставивший сообщение в очередь обмена (sInAuth) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан пользователь, поставивший сообщение в очередь обмена (sInAuth)"
        }
    },
    //Идентификатор сервиса-обработчика сообщения очереди обмена
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type:
                "Идентификатор сервиса-обработчика сообщения очереди обмена (nServiceId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор сервиса-обработчика сообщения очереди обмена (nServiceId)"
        }
    },
    //Код сервиса-обработчика сообщения очереди обмена
    sServiceCode: {
        type: String,
        required: true,
        message: {
            type:
                "Код сервиса-обработчика сообщения очереди обмена (sServiceCode) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан код сервиса-обработчика сообщения очереди обмена (sServiceCode)"
        }
    },
    //Идентификатор функции сервиса-обработчика сообщения очереди обмена
    nServiceFnId: {
        type: Number,
        required: true,
        message: {
            type:
                "Идентификатор функции сервиса-обработчика сообщения очереди обмена (nServiceFnId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор функции сервиса-обработчика сообщения очереди обмена (nServiceFnId)"
        }
    },
    //Код функции сервиса-обработчика сообщения очереди обмена
    sServiceFnCode: {
        type: String,
        required: true,
        message: {
            type:
                "Код функции сервиса-обработчика сообщения очереди обмена (sServiceFnCode) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указан код функции сервиса-обработчика сообщения очереди обмена (sServiceFnCode)"
        }
    },
    //Дата обработки сообщения очереди обмена
    dExecDate: {
        type: Date,
        required: false,
        message: {
            type:
                "Дата обработки сообщения очереди обмена (dExecDate) имеет некорректный тип данных (ожидалось - Date)",
            required: "Не указана дата обработки сообщения очереди обмена (dExecDate)"
        }
    },
    //Дата обработки сообщения очереди обмена (строковое представление)
    sExecDate: {
        type: String,
        required: false,
        message: {
            type:
                "Строковое представление даты обработки сообщения очереди обмена (sExecDate) имеет некорректный тип данных (ожидалось - String)",
            required: "Не указано строковое представление даты обработки сообщения очереди обмена (sExecDate)"
        }
    },
    //Количество попыток обработки сообщения очереди обмена
    nExecCnt: {
        type: Number,
        required: true,
        message: {
            type:
                "Количество попыток обработки сообщения очереди обмена (nExecCnt) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указано количество попыток обработки сообщения очереди обмена (nExecCnt)"
        }
    },
    //Предельное количество попыток обработки сообщения очереди обмена
    nRetryAttempts: {
        type: Number,
        required: true,
        message: {
            type:
                "Предельное количество попыток обработки сообщения очереди обмена (nRetryAttempts) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указано предельное количество попыток обработки сообщения очереди обмена (nRetryAttempts)"
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
            type:
                "Состояние обработки сообщения очереди обмена (nExecState) имеет некорректный тип данных (ожидалось - Number)",
            enum: "Значение состояния обработки сообщения очереди обмена (nExecState) не поддерживается",
            required: "Не указано состояние обработки сообщения очереди обмена (nExecState)"
        }
    },
    //Состояние обработки сообщения очереди обмена (строковый код)
    sExecState: {
        type: String,
        enum: [
            SQUEUE_EXEC_STATE_INQUEUE,
            SQUEUE_EXEC_STATE_APP,
            SQUEUE_EXEC_STATE_APP_OK,
            SQUEUE_EXEC_STATE_APP_ERR,
            SQUEUE_EXEC_STATE_DB,
            SQUEUE_EXEC_STATE_DB_OK,
            SQUEUE_EXEC_STATE_DB_ERR,
            SQUEUE_EXEC_STATE_OK,
            SQUEUE_EXEC_STATE_ERR
        ],
        required: true,
        message: {
            type:
                "Строковый код состояния обработки сообщения очереди обмена (sExecState) имеет некорректный тип данных (ожидалось - String)",
            enum:
                "Значение строкового кода состояния обработки сообщения очереди обмена (sExecState) не поддерживается",
            required: "Не указан строковый код состояния обработки сообщения очереди обмена (sExecState)"
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
    //Идентификатор связанного сообщения очереди обмена
    nQueueId: {
        type: Number,
        required: false,
        message: {
            type:
                "Идентификатор связанного сообщения очереди обмена (nQueueId) имеет некорректный тип данных (ожидалось - Number)",
            required: "Не указан идентификатор связанного сообщения очереди обмена (nQueueId)"
        }
    }
});

//Схема валидации данных сообщения очереди обмена
exports.QueueMsg = new Schema({
    //Данные сообщения очереди обмена
    blMsg: {
        type: Buffer,
        required: true,
        message: {
            type: "Данные сообщения очереди обмена (blMsg) имеют некорректный тип данных (ожидалось - Buffer)",
            required: "Не указаны данные сообщения очереди обмена (blMsg)"
        }
    }
}).validator({ required: val => val === null || val });

//Схема валидации данных ответа сообщения очереди обмена
exports.QueueResp = new Schema({
    //Данные ответа сообщения очереди обмена
    blResp: {
        type: Buffer,
        required: true,
        message: {
            type: "Данные ответа сообщения очереди обмена (blResp) имеют некорректный тип данных (ожидалось - Buffer)",
            required: "Не указаны данные ответа сообщения очереди обмена (blResp)"
        }
    }
}).validator({ required: val => val === null || val });

//Схема валидации результата обработки сообщения очереди
exports.QueuePrcResult = new Schema({
    //Состояние обработки сообщения очереди обмена
    sResult: {
        type: String,
        enum: [SPRC_RESP_RESULT_OK, SPRC_RESP_RESULT_ERR, SPRC_RESP_RESULT_UNAUTH],
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
