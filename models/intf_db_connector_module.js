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
            validateAsyncFunctionType:
                "Функция подключения к БД (connect) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция подключения к БД (connect)"
        }
    },
    //Отключение от БД
    disconnect: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция отключения от БД (disconnect) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция отключения от БД (disconnect)"
        }
    },
    //Получение списка сервисов
    getServices: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция получения списка сервисов (getServices) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция получения списка сервисов (getServices)"
        }
    },
    //Получения списка функций сервиса
    getServiceFunctions: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция получения списка функций сервиса (getServiceFunctions) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция получения списка функций сервиса (getServiceFunctions)"
        }
    },
    //Получение контекста сервиса
    getServiceContext: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция получения контекста сервиса (getServiceContext) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция получения контекста сервиса (getServiceContext)"
        }
    },
    //Установка контекста сервиса
    setServiceContext: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция установки контекста сервиса (setServiceContext) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция установки контекста сервиса (setServiceContext)"
        }
    },
    //Очистка контекста сервиса
    clearServiceContext: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция очистки контекста сервиса (clearServiceContext) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция очистки контекста сервиса (clearServiceContext)"
        }
    },
    //Проверка атуентифицированности сервиса
    isServiceAuth: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция проверки атуентифицированности сервиса (isServiceAuth) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция проверки атуентифицированности сервиса (isServiceAuth)"
        }
    },
    //Постановка в очередь задания на аутентификацию сервиса
    putServiceAuthInQueue: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция постановки в очередь задания на аутентификацию сервиса (putServiceAuthInQueue) имеет неверный формат (ожидалось - AsyncFunction)",
            required:
                "Не реализована функция постановки в очередь задания на аутентификацию сервиса (putServiceAuthInQueue)"
        }
    },
    //Протоколирование работы сервиса
    log: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция протоколирования работы сервиса (log) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция протоколирования работы сервиса (log)"
        }
    },
    //Считывание записи очереди обмена
    getQueue: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция считывания записи очереди обмена (getQueue) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция считывания записи очереди обмена (getQueue)"
        }
    },
    //Добавление сообщения очереди
    putQueue: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция добавления сообщения очереди (putQueue) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция добавления сообщения очереди (putQueue)"
        }
    },
    //Считывание записей исходящих сообщений очереди
    getQueueOutgoing: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция считывания записей исходящих сообщений очереди (getQueueOutgoing) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция считывания записей исходящих сообщений очереди (getQueueOutgoing)"
        }
    },
    //Уставновка состояния записи очереди
    setQueueState: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция установки состояния записи очереди (setQueueState) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция установки состояния записи очереди (setQueueState)"
        }
    },
    //Считывание данных сообщения очереди
    getQueueMsg: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция считывания данных сообщения очереди (getQueueMsg) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция считывания данных сообщения очереди (getQueueMsg)"
        }
    },
    //Установка данных сообщения очереди
    setQueueMsg: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция установки данных сообщения очереди (setQueueMsg) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция установки данных сообщения очереди (setQueueMsg)"
        }
    },
    //Считывание результата обработки сообщения очереди
    getQueueResp: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция считывания результата обработки сообщения очереди (getQueueResp) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция считывания результата обработки сообщения очереди (getQueueResp)"
        }
    },
    //Установка результата обработки сообщения очереди
    setQueueResp: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция установки результата обработки сообщения очереди (setQueueResp) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция установки результата обработки сообщения очереди (setQueueResp)"
        }
    },
    //Исполнение обработчика со стороны БД для сообщения очереди
    execQueuePrc: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция исполнения обработчика со стороны БД для сообщения очереди (execQueuePrc) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция исполнения обработчика со стороны БД для сообщения очереди (execQueuePrc)"
        }
    }
});
