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
            type: path =>
                `Идентификатор сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сообщения очереди обмена (${path})`
        }
    },
    //Дата постановки сообщения в очередь обмена
    dInDate: {
        type: Date,
        required: true,
        message: {
            type: path =>
                `Дата постановки сообщения в очередь обмена (${path}) имеет некорректный тип данных (ожидалось - Date)`,
            required: path => `Не указана дата постановки сообщения в очередь обмена (${path})`
        }
    },
    //Дата постановки сообщения в очередь обмена (строковое представление)
    sInDate: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Строковое представление даты постановки сообщения в очередь обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано строковое представление даты постановки сообщения в очередь обмена (${path})`
        }
    },
    //Пользователь поставивший сообщение в очередь обмена
    sInAuth: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Пользователь, поставивший сообщение в очередь обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан пользователь, поставивший сообщение в очередь обмена (${path})`
        }
    },
    //Идентификатор сервиса-обработчика сообщения очереди обмена
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор сервиса-обработчика сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса-обработчика сообщения очереди обмена (${path})`
        }
    },
    //Код сервиса-обработчика сообщения очереди обмена
    sServiceCode: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Код сервиса-обработчика сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан код сервиса-обработчика сообщения очереди обмена (${path})`
        }
    },
    //Идентификатор функции сервиса-обработчика сообщения очереди обмена
    nServiceFnId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор функции сервиса-обработчика сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор функции сервиса-обработчика сообщения очереди обмена (${path})`
        }
    },
    //Код функции сервиса-обработчика сообщения очереди обмена
    sServiceFnCode: {
        type: String,
        required: true,
        message: {
            type: path =>
                `Код функции сервиса-обработчика сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан код функции сервиса-обработчика сообщения очереди обмена (${path})`
        }
    },
    //Дата обработки сообщения очереди обмена
    dExecDate: {
        type: Date,
        required: false,
        message: {
            type: path =>
                `Дата обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Date)`,
            required: path => `Не указана дата обработки сообщения очереди обмена (${path})`
        }
    },
    //Дата обработки сообщения очереди обмена (строковое представление)
    sExecDate: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Строковое представление даты обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано строковое представление даты обработки сообщения очереди обмена (${path})`
        }
    },
    //Количество попыток обработки сообщения очереди обмена
    nExecCnt: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Количество попыток обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указано количество попыток обработки сообщения очереди обмена (${path})`
        }
    },
    //Предельное количество попыток обработки сообщения очереди обмена
    nRetryAttempts: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Предельное количество попыток обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указано предельное количество попыток обработки сообщения очереди обмена (${path})`
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
            type: path =>
                `Строковый код состояния обработки сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - String)`,
            enum: path =>
                `Значение строкового кода состояния обработки сообщения очереди обмена (${path}) не поддерживается`,
            required: path => `Не указан строковый код состояния обработки сообщения очереди обмена (${path})`
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
    //Идентификатор связанного сообщения очереди обмена
    nQueueId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанного сообщения очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор связанного сообщения очереди обмена (${path})`
        }
    },
    //Параметры сообщения
    sOptions: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Параметры сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - String)`,
            required: path => `Не указаны параметры сообщения очереди обмена (${path})`
        }
    },
    //Параметры ответа
    sOptionsResp: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Параметры ответа на сообщение очереди обмена (${path}) имеют некорректный тип данных (ожидалось - String)`,
            required: path => `Не указаны параметры ответа на сообщение очереди обмена (${path})`
        }
    },
    //Приоритет в очереди обмена
    nPriority: {
        type: Number,
        required: true,
        message: {
            type: path => 
                `Приоритет в очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан приоритет в очереди обмена (${path})`
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
            type: path =>
                `Данные сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указаны данные сообщения очереди обмена (${path})`
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
            type: path =>
                `Данные ответа сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указаны данные ответа сообщения очереди обмена (${path})`
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
    //Параметры ответа на сообщение очереди обмена
    sOptionsResp: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Параметры ответа на сообщение очереди обмена (${path}) имеют некорректный тип данных (ожидалось - String)`,
            required: path => `Не указаны параметры ответа на сообщение очереди обмена (${path})`
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
