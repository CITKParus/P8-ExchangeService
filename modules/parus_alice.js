/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с Яндекс-Диалогами (голосовым помошником "Алиса")
*/

//------------
// Тело модуля
//------------

//ДО функции "Алиса/Начало сеанса"
const beforeLogin = async prms => {
    const d = `${prms.queue.blMsg.toString()} BEFORE LOGIN`;
    return {
        blMsg: new Buffer(d)
    };
};

//ПОСЛЕ функции "Алиса/Начало сеанса"
const afterLogin = async prms => {
    let d = "";
    if (prms.queue.blResp) d = `${prms.queue.blResp.toString()} AFTER LOGIN`;
    else d = `${prms.queue.blMsg.toString()} AFTER LOGIN`;
    return {
        blResp: new Buffer(d)
    };
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeLogin = beforeLogin;
exports.afterLogin = afterLogin;
