/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: Описатель интерфейса подключаемого модуля взаимодействия с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//------------
// Тело модуля
//------------

const validateFunctionType = val => {
    let sFn = {}.toString.call(val);
    return sFn === "[object Function]" || sFn === "[object AsyncFunction]";
};

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации подключаемого модуля взаимодействия с БД
exports.dbConnectorModule = new Schema({
    //Подключение к БД
    connect: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция подключения к БД (connect) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция подключения к БД (connect)"
        }
    },
    //Отключение от БД
    disconnect: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция отключения от БД (disconnect) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция отключения от БД (disconnect)"
        }
    },
    //Получение списка сервисов
    getServices: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция получения списка сервисов (getServices) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция получения списка сервисов (getServices)"
        }
    },
    //Получения списка функций сервиса
    getServiceFunctions: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция получения списка функций сервиса (getServiceFunctions) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция получения списка функций сервиса (getServiceFunctions)"
        }
    },
    //Протоколирование работы сервиса
    log: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция протоколирования работы сервиса (log) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция протоколирования работы сервиса (log)"
        }
    },
    //Считывание записей исходящих сообщений очереди
    getQueueOutgoing: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция считывания записей исходящих сообщений очереди (getQueueOutgoing) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция считывания записей исходящих сообщений очереди (getQueueOutgoing)"
        }
    },
    //Добавление входящего сообщения очереди
    putQueueIncoming: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция добавления входящего сообщения очереди (putQueueIncoming) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция добавления входящего сообщения очереди (putQueueIncoming)"
        }
    },
    //Уствновка состояния записи очереди
    setQueueState: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType:
                "Функция уствновки состояния записи очереди (setQueueState) имеет неверный формат (ожидалось - Function или AsyncFunction)",
            required: "Не реализована функция уствновки состояния записи очереди (setQueueState)"
        }
    }
});
