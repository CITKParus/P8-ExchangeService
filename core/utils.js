/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const { MODULES_PATH_EX } = require("@core/constants.js"); //Глобавльные константы системы

//------------
// Тело модуля
//------------

//Проверка на функцию
const isFunction = functionToCheck => {
    return functionToCheck && {}.toString.call(functionToCheck) === "[object Function]";
};

//Проверка объекта на наличие списка функций
const haveFunctions = (obj, list) => {
    //Объявим результат
    let res = true;
    //Если есть что проверять
    if (obj && list) {
        //И если пришел массив наименований функций
        if (Array.isArray(list)) {
            list.forEach(fn => {
                if (!isFunction(obj[fn])) res = false;
            });
        } else {
            res = false;
        }
    } else {
        res = false;
    }
    //Вернем результат
    return res;
};

//Проверка корректности интерфейса модуля
const checkModuleInterface = (module, interface) => {
    //Объявим результат
    let res = true;
    //Если есть что проверять
    if (module && interface) {
        //Eсли есть список функций
        if (interface.functions) {
            //Проверим их наличие
            res = haveFunctions(module, interface.functions);
        } else {
            res = false;
        }
    } else {
        res = false;
    }
    //Вернем результат
    return res;
};

//Формирование полного пути к подключаемому модулю
const makeModuleFullPath = moduleName => {
    if (moduleName) {
        return MODULES_PATH_EX + "/" + moduleName;
    } else {
        return "";
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.isFunction = isFunction;
exports.haveFunctions = haveFunctions;
exports.checkModuleInterface = checkModuleInterface;
exports.makeModuleFullPath = makeModuleFullPath;
