/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Parus WEB Service (PWS)
*/

//----------------------
// Подключение библиотек
//----------------------
const xmlParser = require("xml2js").parseString; //Конвертация XML в JSON
const js2xmlparser = require("js2xmlparser"); //Конвертация JSON в XML

//---------------------
// Глобальные константы
//---------------------

//Наименования XML-элементов
const SREQUEST_ROOT = "XREQUEST"; //Корневой элемент XML-представления входящего запроса

//Поля заголовка сообщения
const SHEADER_CONTENT_TYPE_JSON = "application/json"; //Значение "content-type" для JSON

//------------
// Тело модуля
//------------

//Разбор XML
const parseXML = xmlDoc => {
    return new Promise((resolve, reject) => {
        xmlParser(xmlDoc, { explicitArray: false, mergeAttrs: true }, (err, result) => {
            if (err) reject(err);
            else resolve(result);
        });
    });
};

//Обработчик "До" для полученного сообщения
const before = async prms => {
    //Если пришел запрос в JSON
    if (prms.options.headers["content-type"] == SHEADER_CONTENT_TYPE_JSON) {
        //Конвертируем полученный в JSON-запрос в XML, понятный серверной части
        let request = {};
        let requestXML = "";
        try {
            request = JSON.parse(prms.queue.blMsg.toString());
            requestXML = js2xmlparser.parse(SREQUEST_ROOT, request[SREQUEST_ROOT]);
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
    if (prms.options.headers["content-type"] == SHEADER_CONTENT_TYPE_JSON) {
        //Конвертируем ответ, подготовленный сервером, в JSON
        parseRes = await parseXML(prms.queue.blResp.toString());
        //Вернём его клиенту в таком виде
        return {
            optionsResp: {
                headers: {
                    "content-type": SHEADER_CONTENT_TYPE_JSON
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
