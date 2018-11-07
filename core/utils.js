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

//Проверка корректности полей объекта
const checkObject = (obj, interface) => {
    //Объявим результат
    let res = "";
    //Если есть что проверять
    if (obj && interface) {
        //Eсли есть список полей для проверки
        if (interface.fields) {
            if (Array.isArray(interface.fields)) {
                let noFields = [];
                let noValues = [];
                //Обходим проверяемые поля
                interface.fields.forEach(fld => {
                    //Проверим наличие поля в объекте
                    if (!(fld.name in obj)) {
                        //Поля нет
                        noFields.push(fld.name);
                    } else {
                        //Поле есть, проверим наличие значения
                        if (fld.required && !obj[fld.name])
                            //Обязательное поле не содержит значения
                            noValues.push(fld.name);
                    }
                });
                //Сформируем итоговое сообщение
                if (noFields.length > 0) res = "Объект не содержит полей: " + noFields.join(", ");
                if (noValues.length > 0)
                    res +=
                        (res == "" ? "" : "; ") + "Обязательные поля объекта не имеют значений: " + noValues.join(", ");
            } else {
                res = "Список проверяемых полей объекта не является массивом";
            }
        } else {
            res = "Не указан список проверяемых полей объекта";
        }
    } else {
        res = "Не указан проверяемый объект и/или его интерфейс";
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
exports.checkObject = checkObject;
exports.makeModuleFullPath = makeModuleFullPath;
