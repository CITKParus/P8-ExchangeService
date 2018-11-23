/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: Описатель списка сервисов
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { Service } = require("../models/obj_service");

//------------
// Тело модуля
//------------

//Описатель схемы валидации списка сервисов
const defServices = (bRequired, sName) => {
    return {
        type: Array,
        required: bRequired,
        each: Service,
        message: {
            required: "Не указан список сервисов (" + sName + ")"
        }
    };
};

//------------------
//  Интерфейс модуля
//------------------

//Описатель схемы валидации списка сервисов
exports.defServices = defServices;

//Схема валидации списка сервисов
exports.Services = new Schema({ services: defServices(true, "services") });
