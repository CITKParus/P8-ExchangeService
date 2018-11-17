/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const { SMODULES_PATH_EX } = require("../core/constants.js"); //Глобавльные константы системы

//------------
// Тело модуля
//------------

//Проверка на функцию
const isFunction = fnToCheck => {
    let sFn = {}.toString.call(fnToCheck);
    return fnToCheck && (sFn === "[object Function]" || sFn === "[object AsyncFunction]");
};

//Проверка объекта на наличие списка функций
const haveFunctions = (obj, list) => {
    //Объявим результат
    let bRes = true;
    //Если есть что проверять
    if (obj && list) {
        //И если пришел массив наименований функций
        if (Array.isArray(list)) {
            list.forEach(sFnName => {
                if (!isFunction(obj[sFnName])) bRes = false;
            });
        } else {
            bRes = false;
        }
    } else {
        bRes = false;
    }
    //Вернем результат
    return bRes;
};

//Проверка корректности интерфейса модуля
const checkModuleInterface = (module, interface) => {
    //Объявим результат
    let bRes = true;
    //Если есть что проверять
    if (module && interface) {
        //Eсли есть список функций
        if (interface.functions) {
            //Проверим их наличие
            bRes = haveFunctions(module, interface.functions);
        } else {
            bRes = false;
        }
    } else {
        bRes = false;
    }
    //Вернем результат
    return bRes;
};

//Проверка корректности полей объекта
const checkObject = (obj, interface) => {
    //Объявим результат
    let sRes = "";
    //Если есть что проверять
    if (obj && interface) {
        //Eсли есть список полей для проверки
        if (interface.fields) {
            if (Array.isArray(interface.fields)) {
                let noFields = [];
                let noValues = [];
                //Обходим проверяемые поля
                interface.fields.forEach(fld => {
                    //Проверим наличие поля в объекте (только для обязательных)
                    if (fld.bRequired && !(fld.sName in obj)) {
                        //Поля нет
                        noFields.push(fld.sName);
                    } else {
                        //Поле есть, проверим наличие значения
                        if (
                            fld.bRequired &&
                            (obj[fld.sName] === "undefined" || obj[fld.sName] === null || obj[fld.sName] === "")
                        )
                            //Обязательное поле не содержит значения
                            noValues.push(fld.sName);
                    }
                });
                //Сформируем итоговое сообщение
                if (noFields.length > 0) sRes = "Объект не содержит полей: " + noFields.join(", ");
                if (noValues.length > 0)
                    sRes +=
                        (sRes == "" ? "" : "; ") +
                        "Обязательные поля объекта не имеют значений: " +
                        noValues.join(", ");
            } else {
                sRes = "Список проверяемых полей объекта не является массивом";
            }
        } else {
            sRes = "Не указан список проверяемых полей объекта";
        }
    } else {
        sRes = "Не указан проверяемый объект и/или его интерфейс";
    }
    //Вернем результат
    return sRes;
};

//Формирование полного пути к подключаемому модулю
const makeModuleFullPath = sModuleName => {
    if (sModuleName) {
        return SMODULES_PATH_EX + "/" + sModuleName;
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
