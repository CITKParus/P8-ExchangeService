/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с "АТОЛ-Онлайн"
*/

//------------
// Тело модуля
//------------

const promiceTimer = timeOut => {
    return new Promise((res, rej) => {
        setTimeout(() => {
            res();
        }, timeOut);
    });
};

//Обработчик "До" отправки чека серверу "АТОЛ-Онлайн"
const beforeBillSend = async prms => {
    console.log(`Начал обработку отправки чека ДО - ${prms.queue.nId}`);
    await promiceTimer(2500);
    console.log(`Закончил обработку отправки чека ДО - ${prms.queue.nId}`);
};

//Обработчик "После" отправки чека серверу "АТОЛ-Онлайн"
const afterBillSend = async prms => {
    console.log(`Начал обработку отправки чека ПОСЛЕ - ${prms.queue.nId}`);
    await promiceTimer(2500);
    console.log(`Закончил обработку отправки чека ПОСЛЕ - ${prms.queue.nId}`);
};

//Обработчик "До" отправки запроса на печатную версию чека серверу "АТОЛ-Онлайн"
const beforeBillPrintSend = async prms => {
    console.log(`Начал обработку запроса на печатную версию чека ДО - ${prms.queue.nId}`);
    await promiceTimer(2500);
    console.log(`Закончил обработку запроса на печатную версию чека ДО - ${prms.queue.nId}`);
};

//Обработчик "После" отправки запроса на печатную версию чека серверу "АТОЛ-Онлайн"
const afterBillPrintSend = async prms => {
    console.log(`Начал обработку запроса на печатную версию чека ПОСЛЕ - ${prms.queue.nId}`);
    await promiceTimer(2500);
    console.log(`Закончил обработку запроса на печатную версию чека ПОСЛЕ - ${prms.queue.nId}`);
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeBillSend = beforeBillSend;
exports.afterBillSend = afterBillSend;
exports.beforeBillPrintSend = beforeBillPrintSend;
exports.afterBillPrintSend = afterBillPrintSend;
