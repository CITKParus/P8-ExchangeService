/*
  Сервис интеграции ПП Парус 8 с WEB API
  Песочница для тестов
*/

require("module-alias/register");
const srvModel = require("./models/obj_service"); //Модель данных сервиса
const dbConnectorModel = require("./models/prms_db_connector"); //Модель данных сервиса
const dbConnectorInterfaceModel = require("./models/interface_db_connector_module"); //Интерфейс модуля взаимодействия с БД
const utl = require("./core/utils"); //Вспомогательные функции
const db = require("./core/db_connector"); //Взаимодействие с БД
const cfg = require("./config"); //Настройки сервера приложений

const pDB = require("./modules/parus_oracle_db");

let a = utl.validateObject(
    { nQueueId: 123, nExecState: 123, sExecMsg: "" },
    dbConnectorModel.getQueueStatePrmsSchema,
    "Тестовый"
);
console.log(a);

let b = utl.validateObject(pDB, dbConnectorInterfaceModel.dbConnectorModule);
console.log(b);
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
