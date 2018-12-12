/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатели параметров вспомогательных функций  (модуль utils.js)
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации
const { mail } = require("./obj_config"); //Схемы валидации конфигурации сервера приложений
const { validateMailList } = require("./common"); //Общие объекты валидации моделей данных

//-------------
//  Тело модуля
//-------------

//Валидация списка адресов E-Mail для отправки уведомления
const validateTo = val => {
    return validateMailList(val);
};

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации параметров функции отправки E-Mail
exports.sendMail = new Schema({
    //Параметры отправки E-Mail уведомлений
    mail: {
        schema: mail,
        required: true,
        message: {
            required: path => `Не указаны параметры отправки E-Mail уведомлений (${path})`
        }
    },
    //Список адресов E-Mail для отправки уведомления
    sTo: {
        type: String,
        required: true,
        use: { validateTo },
        message: {
            type: path =>
                `Список адресов E-Mail для отправки уведомления (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан cписок адресов E-Mail для отправки уведомления (${path})`,
            validateTo: path =>
                `Неверный формат списка адресов E-Mail для отправки уведомления (${path}), для указания нескольких адресов следует использовать запятую в качестве разделителя (без пробелов)`
        }
    },
    //Заголовок сообщения
    sSubject: {
        type: String,
        required: true,
        message: {
            type: path => `Заголовок сообщения (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан заголовок сообщения (${path})`
        }
    },
    //Текст уведомления
    sMessage: {
        type: String,
        required: true,
        message: {
            type: path => `Текст уведомления (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан текст уведомления (${path})`
        }
    }
});

//Схема валидации параметров функции сборки URL
exports.buildURL = new Schema({
    //Корневой каталог сервиса
    sSrvRoot: {
        type: String,
        required: true,
        message: {
            type: path => `Корневой каталог сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан корневой каталог сервиса (${path})`
        }
    },
    //Адрес функции сервиса
    sFnURL: {
        type: String,
        required: true,
        message: {
            type: path => `Адрес функции сервиса (${path}) имеет некорректный тип данных (ожидалось - String)`,
            required: path => `Не указан адрес функции сервиса (${path})`
        }
    }
});
