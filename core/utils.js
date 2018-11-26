/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const Schema = require("validate"); //Схемы валидации
const { SMODULES_PATH_MODULES } = require("../core/constants"); //Глобавльные константы системы

//------------
// Тело модуля
//------------

//Валидация объекта
const validateObject = (obj, schema, sObjName) => {
    //Объявим результат
    let sRes = "";
    if (schema instanceof Schema) {
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
        sRes = "Ошибочный формат схемы валидации";
    }
    //Вернем результат
    return sRes;
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
        return SMODULES_PATH_MODULES + "/" + sModuleName;
    } else {
        return "";
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.validateObject = validateObject;
exports.checkObject = checkObject;
exports.makeModuleFullPath = makeModuleFullPath;
