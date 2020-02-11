/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Parus WEB Service (PWS)
*/

//----------------------
// Подключение библиотек
//----------------------
const xml2js = require("xml2js"); //Конвертация XML в JSON и JSON в XML
const _ = require("lodash"); //Работа с коллекциями и объектами

//---------------------
// Глобальные константы
//---------------------

//Наименования специальных управляющих атрибутов XML
const SJSON_CONTROL_ATTR_ARRAY = "___array___"; //Управляющий атрибут для указания параметров конвертации массива

//Поля заголовка сообщения
const SHEADER_REQ_CONTENT_TYPE_JSON = "application/json"; //Значение "content-type" для JSON
const SHEADER_RESP_CONTENT_TYPE_JSON = "application/json;charset=utf-8"; //Значение "content-type" для JSON

//------------
// Тело модуля
//------------

//Разбор XML
const parseXML = xmlDoc => {
    return new Promise((resolve, reject) => {
        xml2js.parseString(xmlDoc, { explicitArray: false, mergeAttrs: true }, (err, result) => {
            if (err) reject(err);
            else resolve(result);
        });
    });
};

//Дополнительная конвертация выходного JSON - корректное преобразование массивов
const converXMLArraysToJSON = (obj, arrayKey) => {
    for (key in obj) {
        if (obj[key][arrayKey]) {
            let tmp = [];
            let itemKey = obj[key][arrayKey];
            if (obj[key][itemKey]) {
                if (_.isArray(obj[key][itemKey])) {
                    for (let i = 0; i < obj[key][itemKey].length; i++) {
                        let buf = {};
                        buf[itemKey] = _.cloneDeep(obj[key][itemKey][i]);
                        tmp.push(buf);
                    }
                } else {
                    let buf = {};
                    buf[itemKey] = _.cloneDeep(obj[key][itemKey]);
                    tmp.push(buf);
                }
            }
            obj[key] = tmp;
            converXMLArraysToJSON(obj[key], arrayKey);
        } else {
            if (_.isObject(obj[key])) converXMLArraysToJSON(obj[key], arrayKey);
            if (_.isArray(obj[key]))
                for (let i = 0; i < obj[key].length; i++) converXMLArraysToJSON(obj[key][i], arrayKey);
        }
    }
};

//Обработчик "До" для полученного сообщения
const before = async prms => {
    //Если пришел запрос в JSON
    if (
        prms.options.headers["content-type"] &&
        prms.options.headers["content-type"].startsWith(SHEADER_REQ_CONTENT_TYPE_JSON)
    ) {
        //Конвертируем полученный в JSON-запрос в XML, понятный серверной части
        let requestXML = "";
        try {
            let request = JSON.parse(prms.queue.blMsg.toString());
            let builder = new xml2js.Builder();
            requestXML = builder.buildObject(request);
        } catch (e) {
            requestXML = "";
        }
        //Возвращаем отконвертированное в качестве тела запроса
        return {
            blMsg: new Buffer(requestXML)
        };
    }
};

//Обработчик "После" для полученного сообщения
const after = async prms => {
    //Если пришел запрос в JSON
    if (
        prms.options.headers["content-type"] &&
        prms.options.headers["content-type"].startsWith(SHEADER_REQ_CONTENT_TYPE_JSON)
    ) {
        //Конвертируем ответ, подготовленный сервером, в JSON
        parseRes = await parseXML(prms.queue.blResp.toString());
        //Доработаем полученный JSON - корректно конвертируем массивы
        converXMLArraysToJSON(parseRes, SJSON_CONTROL_ATTR_ARRAY);
        //Вернём его клиенту в таком виде
        return {
            optionsResp: {
                headers: {
                    "content-type": SHEADER_RESP_CONTENT_TYPE_JSON
                }
            },
            blResp: new Buffer(JSON.stringify(parseRes))
        };
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.before = before;
exports.after = after;
