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
const { NFORCE_NO, NFORCE_YES } = require("./common"); //Общие алгоритмы валидации
const {
    NQUEUE_EXEC_STATE_INQUEUE,
    NQUEUE_EXEC_STATE_APP,
    NQUEUE_EXEC_STATE_APP_OK,
    NQUEUE_EXEC_STATE_APP_ERR,
    NQUEUE_EXEC_STATE_DB,
    NQUEUE_EXEC_STATE_DB_OK,
    NQUEUE_EXEC_STATE_DB_ERR,
    NQUEUE_EXEC_STATE_OK,
    NQUEUE_EXEC_STATE_ERR,
    NQUEUE_RESET_DATA_NO,
    NQUEUE_RESET_DATA_YES
} = require("./obj_queue"); //Схемы валидации сообщения очереди обмена

//----------
// Константы
//----------

//Признак инкремента количества попыток исполнения позиции очереди
NINC_EXEC_CNT_NO = 0; //Не инкрементировать
NINC_EXEC_CNT_YES = 1; //Инкрементировать

//Признак оригинала данных
NIS_ORIGINAL_NO = 0; //Оригинал
NIS_ORIGINAL_YES = 1; //Не оригинал

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

//Константы
exports.NINC_EXEC_CNT_NO = NINC_EXEC_CNT_NO;
exports.NINC_EXEC_CNT_YES = NINC_EXEC_CNT_YES;
exports.NIS_ORIGINAL_NO = NIS_ORIGINAL_NO;
exports.NIS_ORIGINAL_YES = NIS_ORIGINAL_YES;

//Схема валидации параметров конструктора
exports.DBConnector = new Schema({
    //Параметры подключения к БД
    connectSettings: {
        schema: dbConnect,
        required: true,
        message: {
            required: path => `Не указаны параметры подключения к БД (${path})`
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
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции получения контекста сервиса
exports.getServiceContext = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции установки контектса сервиса
exports.setServiceContext = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    },
    //Контекст сервиса
    sCtx: {
        type: String,
        required: true,
        message: {
            type: path => `Контекст сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан контекст сервиса (${path})`
        }
    },
    //Дата истечения контекста сервиса
    dCtxExp: {
        type: Date,
        required: false,
        message: {
            type: path => `Дата истечения контекст сервиса (${path}) имеет некорректный тип данных (ожидалось - Date)`,
            required: path => `Не указана дата истечения контекста сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции очистки контекста сервиса
exports.clearServiceContext = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции проверки аутентифицированности сервиса
exports.isServiceAuth = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции постановки в очередь задания на аутентификацию сервиса
exports.putServiceAuthInQueue = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
        }
    },
    //Признак принудительного завершения сессии
    nForce: {
        type: Number,
        required: false,
        enum: [NFORCE_YES, NFORCE_NO],
        message: {
            type: path =>
                `Признак принудительного завершения сессии (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение признака принудительного завершения сессии (${path}) не поддерживается`,
            required: path => `Не указан признак принудительного завершения сессии (${path})`
        }
    }
});

//Схема валидации параметров функции получения информации о просроченных сообщениях обмена сервиса
exports.getServiceExpiredQueueInfo = new Schema({
    //Идентификатор сервиса
    nServiceId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор сервиса (${path})`
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
            type: path =>
                `Тип сообщения журнала работы сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение типа сообщения журнала работы сервиса (${path}) не поддерживается`,
            required: path => `Не указан тип сообщения журнала работы сервиса (${path})`
        }
    },
    //Сообщение журнала работы сервиса
    sMsg: {
        type: String,
        required: false,
        message: {
            type: path =>
                `Сообщение журнала работы сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано сообщение журнала работы сервиса (${path})`
        }
    },
    //Идентификатор связанного сервиса
    nServiceId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанного сервиса сообщения журнала работы сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор связанного сервиса сообщения журнала работы сервиса (${path})`
        }
    },
    //Идентификатор связанной функции-обработчика сервиса
    nServiceFnId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанной функции-обработчика сообщения журнала работы сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path =>
                `Не указан идентификатор связанной функции-обработчика сообщения журнала работы сервиса (${path})`
        }
    },
    //Идентификатор связанной позиции очереди обмена
    nQueueId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанной позиции очереди обмена сообщения журнала работы сервиса (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path =>
                `Не указан идентификатор связанной позиции очереди обмена сообщения журнала работы сервиса (${path})`
        }
    }
});

//Схема валидации параметров функции считывания позиции очереди
exports.getQueue = new Schema({
    //Идентификатор позиции очереди обмена
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор позиции очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди обмена (${path})`
        }
    }
});

//Схема валидации параметров функции добавления позиции очереди
exports.putQueue = new Schema({
    //Идентификатор функции сервиса обработчика позиции очереди
    nServiceFnId: {
        type: Number,
        required: true,
        message: {
            type: path =>
                `Идентификатор функции сервиса обработчика позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор функции сервиса обработчика позиции очереди (${path})`
        }
    },
    //Данные сообщения очереди обмена
    blMsg: {
        use: { validateBuffer },
        required: false,
        message: {
            validateBuffer: path =>
                `Данные сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - null или Buffer)`,
            required: path => `Не указаны данные сообщения очереди обмена (${path})`
        }
    },
    //Идентификатор связанной позиции очереди обмена
    nQueueId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанной позиции очереди обмена (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор связанной позиции очереди обмена (${path})`
        }
    },
    //Идентификатор связанной организации
    nLnkCompanyId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанной организации (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор связанной организации (${path})`
        }
    },
    //Идентификатор связанного документа
    nLnkDocumentId: {
        type: Number,
        required: false,
        message: {
            type: path =>
                `Идентификатор связанного документа (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор связанного документа (${path})`
        }
    },
    //Код связанного раздела
    sLnkUnitcode: {
        type: String,
        required: false,
        message: {
            type: path => `Код связанного раздела (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан код связанного раздела (${path})`
        }
    },
    //Параметры сообщения
    sOptions: {
        type: String,
        required: false,
        message: {
            type: path => `Параметры сообщения (${path}) имеют некорректный тип данных (ожидалось - String)`,
            required: path => `Не указаны параметры сообщения (${path})`
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
            type: path =>
                `Количество считываемых сообщений очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указано количество считываемых сообщений очереди (${path})`
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
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
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
        required: false,
        message: {
            type: path => `Код состояния (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение кода состояния (${path}) не поддерживается`,
            required: path => `Не указан код состояния (${path})`
        }
    },
    //Сообщение обработчика
    sExecMsg: {
        type: String,
        required: false,
        message: {
            type: path => `Сообщение обработчика (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указано сообщени обработчика (${path})`
        }
    },
    //Флаг инкремента количества исполнений
    nIncExecCnt: {
        type: Number,
        enum: [NINC_EXEC_CNT_NO, NINC_EXEC_CNT_YES],
        required: false,
        message: {
            type: path =>
                `Флаг инкремента количества исполнений (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение флага инкремента количества исполнений (${path}) не поддерживается`,
            required: path => `Не указан флаг икремента количества исполнений (${path})`
        }
    },
    //Флаг сброса данных сообщения
    nResetData: {
        type: Number,
        enum: [NQUEUE_RESET_DATA_NO, NQUEUE_RESET_DATA_YES],
        required: false,
        message: {
            type: path => `Флаг сброса данных сообщения (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение флага сброса данных сообщения (${path}) не поддерживается`,
            required: path => `Не указан флаг сброса данных сообщения (${path})`
        }
    }
});

//Схема валидации параметров функции считывание данных сообщения из позиции очереди
exports.getQueueMsg = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    }
});

//Схема валидации параметров функции записи данных сообщения в позицию очереди
exports.setQueueMsg = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    },
    //Данные сообщения очереди обмена
    blMsg: {
        use: { validateBuffer },
        required: true,
        message: {
            validateBuffer: path =>
                `Данные сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - null или Buffer)`,
            required: path => `Не указаны данные сообщения очереди обмена (${path})`
        }
    }
}).validator({ required: val => val === null || val });

//Схема валидации параметров функции записи параметров сообщения в позицию очереди
exports.setQueueOptions = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    },
    //Параметры сообщения очереди обмена
    sOptions: {
        type: String,
        required: true,
        message: {
            validateBuffer: path =>
                `Парамметры сообщения очереди обмена (${path}) имеют некорректный тип данных (ожидалось - String)`,
            required: path => `Не указаны параметры сообщения очереди обмена (${path})`
        }
    }
}).validator({ required: val => val === null || val === 0 || val });

//Схема валидации параметров функции считывание ответа на сообщение из позиции очереди
exports.getQueueResp = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    }
});

//Схема валидации параметров функции записи ответа на сообщение в позицию очереди
exports.setQueueResp = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
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
    },
    //Признак передачи оригинала ответа
    nIsOriginal: {
        type: Number,
        enum: [NIS_ORIGINAL_NO, NIS_ORIGINAL_YES],
        required: true,
        message: {
            type: path =>
                `Признак передачи оригинала ответа (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            enum: path => `Значение признака передачи оригинала ответа (${path}) не поддерживается`,
            required: path => `Не указан признак передачи оригинала ответа (${path})`
        }
    }
}).validator({ required: val => val === null || val === 0 || val });

//Схема валидации параметров функции записи параметров ответа на сообщение в позицию очереди
exports.setQueueOptionsResp = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    },
    //Параметры ответа на сообщение очереди обмена
    sOptionsResp: {
        type: String,
        required: true,
        message: {
            validateBuffer: path =>
                `Парамметры ответа на сообщение очереди обмена (${path}) имеют некорректный тип данных (ожидалось - String)`,
            required: path => `Не указаны параметры ответа на сообщение очереди обмена (${path})`
        }
    }
}).validator({ required: val => val === null || val === 0 || val });

//Схема валидации параметров функции установки результата обработки позиции очереди
exports.setQueueAppSrvResult = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    },
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
}).validator({ required: val => val === null || val });

//Схема валидации параметров функции исполнения обработчика со стороны БД для позиции очереди
exports.execQueueDBPrc = new Schema({
    //Идентификатор позиции очереди
    nQueueId: {
        type: Number,
        required: true,
        message: {
            type: path => `Идентификатор позиции очереди (${path}) имеет некорректный тип данных (ожидалось - Number)`,
            required: path => `Не указан идентификатор позиции очереди (${path})`
        }
    }
});
