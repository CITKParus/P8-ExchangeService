/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: Описатель списка функций сервиса
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { ServiceFunction } = require("../models/obj_service_function"); //Схема валидации функции сервиса

//------------
// Тело модуля
//------------

//Описатель схемы валидации списка функций сервиса
const defServiceFunctions = (bRequired, sName) => {
    return {
        type: Array,
        required: bRequired,
        each: ServiceFunction,
        message: {
            required: "Не указан список функций сервиса (" + sName + ")"
        }
    };
};

//------------------
//  Интерфейс модуля
//------------------

//Описатель схемы валидации списка функций сервиса
exports.defServiceFunctions = defServiceFunctions;

//Схема валидации списка функций сервиса
exports.ServiceFunctions = new Schema({ functions: defServiceFunctions(true, "functions") });
