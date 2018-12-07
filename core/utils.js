/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const Schema = require("validate"); //Схемы валидации
const {
    SERR_UNEXPECTED,
    SMODULES_PATH_MODULES,
    SERR_MODULES_NO_MODULE_SPECIFIED,
    SERR_MODULES_BAD_INTERFACE
} = require("./constants"); //Глобавльные константы системы
const { ServerError } = require("./server_errors"); //Ошибка сервера

//------------
// Тело модуля
//------------

//Валидация объекта
const validateObject = (obj, schema, sObjName) => {
    //Объявим результат
    let sRes = "";
    if (schema instanceof Schema) {
        if (obj) {
            const objTmp = _.cloneDeep(obj);
            const errors = schema.validate(objTmp, { strip: false });
            if (errors && Array.isArray(errors)) {
                if (errors.length > 0) {
                    let a = errors.map(e => {
                        return e.message;
                    });
                    sRes =
                        "Объект" +
                        (sObjName ? " '" + sObjName + "' " : " ") +
                        "имеет некорректный формат: " +
                        _.uniq(a).join("; ");
                }
            } else {
                sRes = "Неожиданный ответ валидатора";
            }
        } else {
            sRes = "Объект" + (sObjName ? " '" + sObjName + "' " : " ") + "не указан";
        }
    } else {
        sRes = "Ошибочный формат схемы валидации";
    }
    //Вернем результат
    return sRes;
};

//Формирование полного пути к подключаемому модулю
const makeModuleFullPath = sModuleName => {
    if (sModuleName) {
        return SMODULES_PATH_MODULES + "/" + sModuleName;
    } else {
        return "";
    }
};

//Формирование текста ошибки
const makeErrorText = e => {
    let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
    if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
    return sErr;
};

//Считывание наименования модуля-обработчика сервера приложений (ожидаемый формат - <МОДУЛЬ>/<ФУНКЦИЯ>)
const getAppSrvModuleName = sAppSrv => {
    if (sAppSrv) {
        if (sAppSrv instanceof String || typeof sAppSrv === "string") {
            if (sAppSrv.indexOf("/") === -1) {
                return null;
            } else {
                return sAppSrv.substring(0, sAppSrv.indexOf("/"));
            }
        } else {
            return null;
        }
    } else {
        return null;
    }
};

//Считывание наименования функции модуля-обработчика сервера приложений (ожидаемый формат - <МОДУЛЬ>/<ФУНКЦИЯ>)
const getAppSrvFunctionName = sAppSrv => {
    if (sAppSrv) {
        if (sAppSrv instanceof String || typeof sAppSrv === "string") {
            if (sAppSrv.indexOf("/") === -1) {
                return null;
            } else {
                return sAppSrv.substring(sAppSrv.indexOf("/") + 1, sAppSrv.length);
            }
        } else {
            return null;
        }
    } else {
        return null;
    }
};

//Получение функции обработчика
const getAppSrvFunction = sAppSrv => {
    //Объявим формат (для сообщений об ошибках)
    const sFormat = "(ожидаемый формат: <МОДУЛЬ>/<ФУНКЦИЯ>)";
    //Проверим, что есть что разбирать
    if (!sAppSrv)
        throw new ServerError(SERR_MODULES_NO_MODULE_SPECIFIED, `Не указаны модуль и функция обработчика ${sFormat}`);
    //Разбираем
    try {
        //Разбираем на модуль и функцию
        let moduleName = getAppSrvModuleName(sAppSrv);
        let funcName = getAppSrvFunctionName(sAppSrv);
        //Проверим, что есть и то и другое
        if (!moduleName) throw Error(`Обработчик ${sAppSrv} не указывает на модуль ${sFormat}`);
        if (!funcName) throw Error(`Обработчик ${sAppSrv} не указывает на функцию ${sFormat}`);
        //Подключаем модуль
        let mdl = null;
        try {
            mdl = require(makeModuleFullPath(moduleName));
        } catch (e) {
            throw Error(
                `Не удалось подключить модуль ${moduleName}, проверье что он существует и не имеет синтаксических ошибок. Ошибка подключения: ${
                    e.message
                }`
            );
        }
        //Проверяем, что в нём есть эта функция
        if (!mdl[funcName]) throw Error(`Функция ${funcName} не определена в модуле ${moduleName}`);
        //Проверяем, что функция асинхронна и если это так - возвращаем её
        if ({}.toString.call(mdl[funcName]) === "[object AsyncFunction]") return mdl[funcName];
        else throw Error(`Функция ${funcName} модуля ${moduleName} должна быть асинхронной`);
    } catch (e) {
        throw new ServerError(SERR_MODULES_BAD_INTERFACE, e.message);
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.validateObject = validateObject;
exports.makeModuleFullPath = makeModuleFullPath;
exports.makeErrorText = makeErrorText;
exports.getAppSrvModuleName = getAppSrvModuleName;
exports.getAppSrvFunctionName = getAppSrvFunctionName;
exports.getAppSrvFunction = getAppSrvFunction;
