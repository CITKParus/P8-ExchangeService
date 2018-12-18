/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: тестовый модуль для ПМИ
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const js2xmlparser = require("js2xmlparser"); //Конвертация JSON в XML

//------------
// Тело модуля
//------------

//Формирование запроса к тестовому стенду на получение сведений о контрагенте
const beforeAgentInfo = async prms => {
    //Считаем параметры запроса из тела сообщения
    let sPayLoad = prms.queue.blMsg.toString();
    //Вернем конвертированное в XML-сообщение (потребуется для использования при разборе ответа) и параметры для соединения
    return {
        options: {
            url: `${prms.service.sSrvRoot}/${prms.function.sFnURL}?CPRMS=${sPayLoad}`
        },
        blMsg: new Buffer(js2xmlparser.parse("MSG", JSON.parse(sPayLoad)))
    };
};

//Обработка ответа тестового стенда на запрос сведений о контрагенте
const afterAgentInfo = async prms => {
    let r = JSON.parse(prms.serverResp);
    if (r.STATE === 0) {
        throw Error(r.MSG);
    } else {
        return {
            blResp: new Buffer(js2xmlparser.parse("AGENT", r))
        };
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeAgentInfo = beforeAgentInfo;
exports.afterAgentInfo = afterAgentInfo;
