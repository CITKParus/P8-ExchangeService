/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: описатель сообщений обмена с обработчиком очереди выходящих сообщений
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

//------------------
//  Интерфейс модуля
//------------------

//Схема валидации результата работы функции "предобработки" сообщения очереди сервером приложений
exports.InQueueProcessorFnBefore = new Schema({
    //Обработанный запрос внешней системы
    blMsg: {
        type: Buffer,
        required: false,
        message: {
            type: path =>
                `Обработанный запрос внешней системы (${path}) имеет некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указан Обработанный запрос внешней системы (${path})`
        }
    },
    //Ответ системы
    blResp: {
        type: Buffer,
        required: false,
        message: {
            type: path => `Ответ системы (${path}) имеет некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указан ответ системы (${path})`
        }
    }
});

//Схема валидации результата работы функции "постобработки" сообщения очереди сервером приложений
exports.InQueueProcessorFnAfter = new Schema({
    //Обработанный ответ системы
    blResp: {
        type: Buffer,
        required: false,
        message: {
            type: path => `Обработанный ответ системы (${path}) имеет некорректный тип данных (ожидалось - Buffer)`,
            required: path => `Не указан обработанный ответ системы (${path})`
        }
    }
});
