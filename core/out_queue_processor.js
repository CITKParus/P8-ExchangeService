/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: обработчик исходящего сообщения
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и коллекциями
const { makeModuleFullPath, validateObject } = require("./utils"); //Вспомогательные функции
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { NQUEUE_EXEC_STATE_APP_OK, NQUEUE_EXEC_STATE_APP_ERR } = require("../models/obj_queue"); //Схема валидации сообщения очереди обмена
const objOutQueueProcessorSchema = require("../models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const {
    SERR_MODULES_BAD_INTERFACE,
    SERR_OBJECT_BAD_INTERFACE,
    SERR_MODULES_NO_MODULE_SPECIFIED
} = require("./constants"); //Глобальные константы

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Сообщени для родительского процесса
let result = {
    nExecState: null,
    sExecMsg: null,
    blResp: null
};

//------------
// Тело модуля
//------------

//Установка состояния ошибки в ответном сообщении
const setErrorResult = e => {
    //Выставим код состояния - ошибка обработки сервером приложений
    result.nExecState = NQUEUE_EXEC_STATE_APP_ERR;
    //Выставим сообщение об ошибке
    result.sExecMsg = e.message;
};

//Установка состояния успеха в ответном сообщении
const setOKResult = () => {
    //Выставим код состояния - ошибка обработки сервером приложений
    result.nExecState = NQUEUE_EXEC_STATE_APP_OK;
    //Выставим сообщение об ошибке
    result.sExecMsg = null;
};

//Обработка задачи
const processTask = async task => {
    setTimeout(() => {
        setOKResult();
        process.send(result);
    }, 3000);
};

//---------------------------------
// Управление процессом обработчика
//---------------------------------

//Перехват CTRL + C (останов процесса)
process.on("SIGINT", async () => {});

//Перехват CTRL + \ (останов процесса)
process.on("SIGQUIT", () => {});

//Перехват мягкого останова процесса
process.on("SIGTERM", () => {});

//Перехват ошибок
process.on("uncaughtException", e => {
    //Выставляем ошибку в сообщении
    setErrorResult(e);
    //Отправляем ответ родительскому процессу
    process.send(result);
});

//Приём сообщений
process.on("message", task => {
    //Проверяем структуру переданного сообщения
    let sCheckResult = validateObject(
        task,
        objOutQueueProcessorSchema.OutQueueProcessorTask,
        "Задача обработчика очереди исходящих сообщений"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        //Запускаем обработку
        processTask(task);
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
});
