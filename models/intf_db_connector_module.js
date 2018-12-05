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
    //Добавление входящего сообщения очереди
    putQueueIncoming: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция добавления входящего сообщения очереди (putQueueIncoming) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция добавления входящего сообщения очереди (putQueueIncoming)"
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
    //Установка данных сообщения записи очереди
    setQueueMsg: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция установки данных сообщения записи очереди (setQueueMsg) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция установки данных сообщения записи очереди (setQueueMsg)"
        }
    },
    //Установка результата обработки записи очереди
    setQueueResp: {
        use: { validateAsyncFunctionType },
        required: true,
        message: {
            validateAsyncFunctionType:
                "Функция установки результата обработки записи очереди (setQueueResp) имеет неверный формат (ожидалось - AsyncFunction)",
            required: "Не реализована функция установки результата обработки записи очереди (setQueueResp)"
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
