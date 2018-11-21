/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: Описатель интерфейса подключаемого модуля взаимодействия с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//------------------
//  Интерфейс модуля
//------------------

/*
                            "getServiceFunctions",
                            "log",
                            "getQueueOutgoing",
                            "putQueueIncoming",
                            "setQueueState"

*/

const validateFunctionType = val => {
    let sFn = {}.toString.call(val);
    console.log(sFn);
    return sFn === "[object Function]" || sFn === "[object AsyncFunction]";
};

//Схема валидации подключаемого модуля взаимодействия с БД
exports.dbConnectorModule = new Schema({
    //Функция подключения к БД
    connect: {
        use: { validateFunctionType },
        required: true,
        message: {
            validateFunctionType: "Функция подключения к БД (connect) имеет неверный формат",
            required: "Не реализована функция подключения к БД (connect)"
        }
    },
    //Функция отключения от БД
    disconnect: {
        type: Function,
        required: true,
        message: {
            type: "Функция отключения от БД (disconnect) имеет неверный формат",
            required: "Не реализована функция отключения от БД (disconnect)"
        }
    },
    //Функция получения данных о сервисах
    getServices: {
        type: Function,
        required: true,
        message: {
            type: "Функция получения данных сервисов (getServices) имеет неверный формат",
            required: "Не реализована функция получения данных сервисов (getServices)"
        }
    }
});
