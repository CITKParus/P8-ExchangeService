/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель интерфейса подключаемого модуля взаимодействия с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//------------
// Тело модуля
//------------

const validateAsyncFunctionType = val => {
    let sFn = {}.toString.call(val);
    return sFn === "[object AsyncFunction]";
};

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации подключаемого модуля взаимодействия с БД
exports.dbConnectorModule = new Schema({
    //Подключение к БД
    connect: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция подключения к БД (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция подключения к БД (${path})`
        }
    },
    //Отключение от БД
    disconnect: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция отключения от БД (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция отключения от БД (${path})`
        }
    },
    //Получение списка сервисов
    getServices: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция получения списка сервисов (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция получения списка сервисов (${path})`
        }
    },
    //Получения списка функций сервиса
    getServiceFunctions: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция получения списка функций сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция получения списка функций сервиса (${path})`
        }
    },
    //Получение контекста сервиса
    getServiceContext: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция получения контекста сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция получения контекста сервиса (${path})`
        }
    },
    //Установка контекста сервиса
    setServiceContext: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция установки контекста сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция установки контекста сервиса (${path})`
        }
    },
    //Очистка контекста сервиса
    clearServiceContext: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция очистки контекста сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция очистки контекста сервиса (${path})`
        }
    },
    //Проверка атуентифицированности сервиса
    isServiceAuth: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция проверки атуентифицированности сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция проверки атуентифицированности сервиса (${path})`
        }
    },
    //Постановка в очередь задания на аутентификацию сервиса
    putServiceAuthInQueue: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция постановки в очередь задания на аутентификацию сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция постановки в очередь задания на аутентификацию сервиса (${path})`
        }
    },
    //Получение информации о просроченных сообщениях обмена сервиса
    getServiceExpiredQueueInfo: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция получения информации о просроченных сообщениях обмена сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path =>
                `Не реализована функция получения информации о просроченных сообщениях обмена сервиса (${path})`
        }
    },
    //Протоколирование работы сервиса
    log: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция протоколирования работы сервиса (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция протоколирования работы сервиса (${path})`
        }
    },
    //Считывание записи очереди обмена
    getQueue: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция считывания записи очереди обмена (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция считывания записи очереди обмена (${path})`
        }
    },
    //Добавление сообщения очереди
    putQueue: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция добавления сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция добавления сообщения очереди (${path})`
        }
    },
    //Считывание записей исходящих сообщений очереди
    getQueueOutgoing: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция считывания записей исходящих сообщений очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция считывания записей исходящих сообщений очереди (${path})`
        }
    },
    //Уставновка состояния записи очереди
    setQueueState: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция установки состояния записи очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция установки состояния записи очереди (${path})`
        }
    },
    //Считывание данных сообщения очереди
    getQueueMsg: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция считывания данных сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция считывания данных сообщения очереди (${path})`
        }
    },
    //Установка данных сообщения очереди
    setQueueMsg: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция установки данных сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция установки данных сообщения очереди (${path})`
        }
    },
    //Установка параметров сообщения очереди
    setQueueOptions: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция установки параметров сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция установки параметров сообщения очереди (${path})`
        }
    },
    //Считывание результата обработки сообщения очереди
    getQueueResp: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция считывания результата обработки сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция считывания результата обработки сообщения очереди (${path})`
        }
    },
    //Установка результата обработки сообщения очереди
    setQueueResp: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция установки результата обработки сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path => `Не реализована функция установки результата обработки сообщения очереди (${path})`
        }
    },
    //Установка параметров результата обработки сообщения очереди
    setQueueOptionsResp: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция установки параметров результата обработки сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path =>
                `Не реализована функция установки параметров результата обработки сообщения очереди (${path})`
        }
    },
    //Исполнение обработчика со стороны БД для сообщения очереди
    execQueuePrc: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType: path =>
                `Функция исполнения обработчика со стороны БД для сообщения очереди (${path}) имеет неверный формат (ожидалось - AsyncFunction)`,
            required: path =>
                `Не реализована функция исполнения обработчика со стороны БД для сообщения очереди (${path})`
        }
    }
});
