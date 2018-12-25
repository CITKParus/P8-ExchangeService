/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с "АТОЛ-Онлайн" (v4) в формате ФФД 1.05
*/

//------------
// Тело модуля
//------------

//Обработчик "До" отправки чека серверу "АТОЛ-Онлайн"
const beforeRegBillSIR = async prms => {
    console.log(`Начал обработку отправки чека ДО - ${prms.queue.nId}`);
    //throw Error("AAAAAAAAAAAAA");
    let res = {
        blMsg: new Buffer("NEW SOME DATA")
    };
    if (!prms.service.context.token) {
        console.log("NO TOKEN!!!");
        res.context = { token: `NEW TOKEN FOR${prms.queue.nId}` };
    } else {
        console.log(prms.service.context);
    }
    console.log(prms.queue.blMsg.toString());
    await promiceTimer(2500);
    console.log(`Закончил обработку отправки чека ДО - ${prms.queue.nId}`);
    return res;
};

//Обработчик "После" отправки чека серверу "АТОЛ-Онлайн"
const afterRegBillSIR = async prms => {
    console.log(`Начал обработку отправки чека ПОСЛЕ - ${prms.queue.nId}`);
    console.log(prms.service.context);
    console.log(prms.queue.blMsg.toString());
    //await promiceTimer(2500);
    console.log(`Закончил обработку отправки чека ПОСЛЕ - ${prms.queue.nId}`);
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeRegBillSIR = beforeRegBillSIR;
exports.afterRegBillSIR = afterRegBillSIR;
