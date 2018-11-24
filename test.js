/*
  Сервис интеграции ПП Парус 8 с WEB API
  Песочница для тестов
*/

require("module-alias/register");
const srvsModel = require("./models/obj_services"); //Модель данных списка сервисов
const srvModel = require("./models/obj_service"); //Модель данных сервиса
const srvFnModel = require("./models/obj_service_function"); //Модель данных функции сервиса
const srvFnSModel = require("./models/obj_service_functions"); //Модель данных функции сервиса
const queueModel = require("./models/obj_queue"); //Модель данных позиции очереди обмена
const queuesModel = require("./models/obj_queues"); //Модель данных списка позиций очереди обмена
const dbConnectorModel = require("./models/prms_db_connector"); //Описатели параметров функций модуля подключения к БД
const dbConnectorInterfaceModel = require("./models/intf_db_connector_module"); //Интерфейс модуля взаимодействия с БД
const utl = require("./core/utils"); //Вспомогательные функции
const db = require("./core/db_connector"); //Взаимодействие с БД
const cfg = require("./config"); //Настройки сервера приложений

const pDB = require("./modules/parus_oracle_db");

//let a = utl.validateObject(
//   { nQueueId: 123, nExecState: 123, sExecMsg: "" },
//   dbConnectorModel.getQueueStatePrmsSchema,
//   "Тестовый"
//);
//console.log(a);

//let b = utl.validateObject(
//    pDB,
//    dbConnectorInterfaceModel.dbConnectorModule,
//    "Пользовательский модуль подключения к БД"
//);
//if (b) console.log(b);
//else console.log("Нет ошибок в модуле");

const getServices = async () => {
    let d = new db.DBConnector(cfg.dbConnect);
    await d.connect();
    let r = await d.getServices();
    let q = await d.getOutgoing({ nPortionSize: 1 });
    await d.disconnect();
    console.log(q[0].bMsg instanceof Buffer);
    let errs = utl.validateObject(r[1], srvModel.Service, "Сервис");
    let errs2 = utl.validateObject({ functions: r[1].functions }, srvFnSModel.ServiceFunctions, "Функция сервиса");
    let errs3 = utl.validateObject({ services: r }, srvsModel.Services, "Список сервисов");
    let errs4 = utl.validateObject(q[0], queueModel.Queue, "Позиция очереди обмена");
    let errs5 = utl.validateObject({ queues: q }, queuesModel.Queues, "Очередь сообщений обмена");
    if (errs2) console.log(errs2);
    else console.log("Нет ошибок в функции сервиса");
    if (errs) console.log(errs);
    else console.log("Нет ошибок в сервисе");
    if (errs3) console.log(errs3);
    else console.log("Нет ошибок в списке сервисов");
    if (errs4) console.log(errs4);
    else console.log("Нет ошибок в сообщении обмена");
    if (errs5) console.log(errs5);
    else console.log("Нет ошибок в очереди сообщений обмена");
};

getServices();

/*
const errors = srvModel.schema.validate({ nId: 123, sCode: "", nSrvType: "", sSrvType: "" });
console.log(errors);
let a = errors.map(e => {
    return e.message;
});
console.log(a.join("; "));

const dbConn = new db.DBConnector(cfg.dbConnect);

const test = async () => {
    await dbConn.connect();
    let r = await dbConn.getOutgoing({ nPortionSize: 123 });
    console.log(r);
    try {
        let rr = await dbConn.setQueueState({
            nQueueId: 94568140,
            nExecState: 1,
            sExecMsg: "Обработано сервером приложений"
        });
        console.log(rr);
    } catch (e) {
        console.log(e.sMessage);
    }

    await dbConn.disconnect();
};

test();
*/
