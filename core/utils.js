/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const Schema = require("validate"); //Схемы валидации
const { SMODULES_PATH_MODULES } = require("./constants"); //Глобавльные константы системы

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
exports.makeModuleFullPath = makeModuleFullPath;
