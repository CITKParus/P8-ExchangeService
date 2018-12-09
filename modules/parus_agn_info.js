/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: тестовый модуль для ПМИ - получение сведений о контрагентах на тестовом стенде
*/

//------------
// Тело модуля
//------------

//Формирование запроса к тестовому стенду на получение сведений о контрагенте
const buildAgentQuery = async prms => {
    let sURL = `${prms.service.sSrvRoot}/${prms.function.sFnURL}`;
    let sPayLoad = prms.queue.blMsg.toString();
    return {
        options: { url: sURL.replace("<NRN>", sPayLoad), method: prms.function.sFnPrmsType }
    };
};

//Обработка ответа тестового стенда на запрос сведений о контрагенте
const parseAgentInfo = async prms => {
    let r = JSON.parse(prms.serverResp);
    if (r.STATE === 0) {
        throw Error(r.MSG);
    } else {
        return {
            blResp: new Buffer(r.SAGNABBR + "$#$" + r.SAGNNAME)
        };
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.buildAgentQuery = buildAgentQuery;
exports.parseAgentInfo = parseAgentInfo;
