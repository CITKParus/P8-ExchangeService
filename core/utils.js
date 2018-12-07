/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const Schema = require("validate"); //Схемы валидации
const { SERR_UNEXPECTED, SMODULES_PATH_MODULES } = require("./constants"); //Глобавльные константы системы
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

//-----------------
// Интерфейс модуля
//-----------------

exports.validateObject = validateObject;
exports.makeModuleFullPath = makeModuleFullPath;
exports.makeErrorText = makeErrorText;
