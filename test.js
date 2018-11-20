/*
  Сервис интеграции ПП Парус 8 с WEB API
  Песочница для тестов
*/

require("module-alias/register");
const srvModel = require("./models/service");
const db = require("./core/db_connector.js"); //Взаимодействие с БД
const cfg = require("./config.js"); //Настройки сервера приложений

//const errors = srvModel.schema.validate({ nId: 123, sCode: "", nSrvType: "", sSrvType: "" });
//errors.forEach(e => {
//console.log(e.message);
//});

const dbConn = new db.DBConnector(cfg.dbConnect);

const test = async () => {
    await dbConn.connect();
    let r = await dbConn.getOutgoing({ nPortionSize: 123 });
    console.log(r);
    let rr = await dbConn.setQueueState({
        nQueueId: 94568140,
        nExecState: 1,
        sExecMsg: "Обработано сервером приложений"
    });
    console.log(rr);
    await dbConn.disconnect();
};

test();
