/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: тестовый модуль для ПМИ - получение сведений о контрагентах на тестовом стенде
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const js2xmlparser = require("js2xmlparser"); //Конвертация JSON в XML

//------------
// Тело модуля
//------------

//Формирование запроса к тестовому стенду на получение сведений о контрагенте
const buildAgentQuery = async prms => {};

//Обработка ответа тестового стенда на запрос сведений о контрагенте
const parseAgentInfo = async prms => {
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

exports.buildAgentQuery = buildAgentQuery;
exports.parseAgentInfo = parseAgentInfo;
