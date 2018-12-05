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
const objOutQueueProcessorSchema = require("../models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const prmsOutQueueProcessorSchema = require("../models/prms_out_queue_processor"); //Схема валидации параметров функций модуля
const objQueueSchema = require("../models/obj_queue"); //Схемы валидации сообщения очереди
const {
    SERR_UNEXPECTED,
    SERR_MODULES_BAD_INTERFACE,
    SERR_OBJECT_BAD_INTERFACE,
    SERR_MODULES_NO_MODULE_SPECIFIED
} = require("./constants"); //Глобальные константы
//!!!!!!!!!!!!!!!!!!!!!!! УБРАТЬ!!!!!!!!!!!!!!!!!!!!!!
const fs = require("fs");

//------------
// Тело модуля
//------------

//Отправка родительскому процессу ошибки обработки сообщения сервером приложений
const sendErrorResult = prms => {
    //Проверяем параметры
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.sendErrorResult,
        "Параметры функции отправки ошибки обработки"
    );
    //Если параметры в норме
    if (!sCheckResult) {
        //Отправляем родительскому процессу ошибку
        process.send({
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR,
            sExecMsg: prms.sMessage,
            blMsg: null,
            blResp: null
        });
    } else {
        //Отправляем родительскому процессу сведения об ошибочных параметрах
        process.send({
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR,
            sExecMsg: sCheckResult,
            blMsg: null,
            blResp: null
        });
    }
};

//Отправка родительскому процессу успеха обработки сообщения сервером приложений
const sendOKResult = prms => {
    //Проверяем параметры
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.sendOKResult,
        "Параметры функции отправки ответа об успехе обработки"
    );
    //Если параметры в норме
    if (!sCheckResult) {
        //Отправляем родительскому процессу успех
        process.send({
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_OK,
            sExecMsg: null,
            blMsg: prms.blMsg,
            blResp: prms.blResp
        });
    } else {
        //Отправляем родительскому процессу сведения об ошибочных параметрах
        process.send({
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR,
            sExecMsg: sCheckResult,
            blMsg: null,
            blResp: null
        });
    }
};

//Отправка родительскому процессу сообщения без обработки
const sendUnChange = prms => {
    //Проверяем параметры
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.sendUnChange,
        "Параметры функции отправки сообщения без обработки"
    );
    //Если параметры в норме
    if (!sCheckResult) {
        process.send({
            nExecState: prms.task.nExecState,
            sExecMsg: null,
            blMsg: prms.task.blMsg ? new Buffer(prms.task.blMsg) : null,
            blResp: prms.task.blResp ? new Buffer(prms.task.blResp) : null
        });
    } else {
        //Отправляем родительскому процессу сведения об ошибочных параметрах
        process.send({
            nExecState: objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR,
            sExecMsg: sCheckResult,
            blMsg: null,
            blResp: null
        });
    }
};

//Обработка задачи
const processTask = async prms => {
    //Проверяем параметры
    let sCheckResult = validateObject(
        prms,
        prmsOutQueueProcessorSchema.processTask,
        "Параметры функции обработки задачи"
    );
    //Если параметры в норме
    if (!sCheckResult) {
        //Обработке подлежат только необработанные сервером приложений сообщения
        if (
            prms.task.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_INQUEUE ||
            prms.task.nExecState == objQueueSchema.NQUEUE_EXEC_STATE_APP_ERR
        ) {
            setTimeout(() => {
                //if (prms.task.nQueueId == 2) {
                //    sendErrorResult({ sMessage: "Ошибка отработки сообщения " + prms.task.nQueueId });
                //} else {
                if (prms.task.blMsg) {
                    let b = new Buffer(prms.task.blMsg);
                    fs.writeFile("c:/repos/temp/" + prms.task.nQueueId, b, err => {
                        if (err) {
                            sendErrorResult({ sMessage: err.message });
                        } else {
                            let sMsg = b.toString() + " MODIFICATION FOR " + prms.task.nQueueId;
                            sendOKResult({
                                blMsg: new Buffer(sMsg),
                                blResp: new Buffer("REPLAY ON " + prms.task.nQueueId)
                            });
                        }
                    });
                } else {
                    sendErrorResult({
                        sMessage: "Ошибка отработки сообщения " + prms.task.nQueueId + ": нет данных для обработки"
                    });
                }
                //}
            }, 3000);
        } else {
            //Остальные возвращаем без изменения и отработки, с сохранением статусов и сообщений
            sendUnChange(prms);
        }
    } else {
        sendErrorResult({ sMessage: sCheckResult });
    }
};

//---------------------------------
// Управление процессом обработчика
//---------------------------------

//Перехват CTRL + C (останов процесса)
process.on("SIGINT", () => {});

//Перехват CTRL + \ (останов процесса)
process.on("SIGQUIT", () => {});

//Перехват мягкого останова процесса
process.on("SIGTERM", () => {});

//Перехват ошибок
process.on("uncaughtException", e => {
    //Отправляем ошибку родительскому процессу
    sendErrorResult({ sMessage: e.message });
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
        processTask({ task });
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
});
