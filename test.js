/*
  Сервис интеграции ПП Парус 8 с WEB API
  Песочница для тестов
*/

require("module-alias/register");
const db = require("./core/db_connector"); //Взаимодействие с БД
const cfg = require("./config"); //Настройки сервера приложений
const childProcess = require("child_process"); //Работа с дочерними процессами
const objOutQueueProcessorSchema = require("./models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const { makeModuleFullPath, validateObject } = require("./core/utils"); //Вспомогательные функции

/*
let proc = childProcess.fork("core/out_queue_processor", { silent: true });
*/
const getServices = async () => {
    let d = new db.DBConnector({ connectSettings: cfg.dbConnect });
    try {
        await d.connect();
        //let r = await d.getServices();
        //let q = await d.getOutgoing({ nPortionSize: 1 });
        await d.setQueueState({ nQueueId: 2, nExecState: 1, nIncExecCnt: 0 });
        await d.disconnect();
    } catch (e) {
        await d.disconnect();
        console.log(e.sCode + " " + e.sMessage);
    }
};
/*
proc.on("message", m => {
    console.log("SUBPROCESS MESSAGE: " + m);
    if (m == "ready") {
        console.log("DONE!!!");
        proc.kill();
    } else {
        console.log("ERROR!!!");
        proc.kill();
    }
});

proc.on("error", e => {
    console.log("SUBPROCESS ERROR: " + e.message);
    proc.kill();
});
proc.on("uncaughtException", e => {
    console.log("SUBPROCESS EXCEPTION: " + e.message);
    proc.kill();
});

proc.on("exit", code => {
    console.log("SUBPROCESS EXIT: " + code);
});
*/
//proc.send({ nId: "12345" });

getServices();

//let sCheckResult = validateObject(
//    { nExecState: null, sExecMsg: null, blResp: null },
//objOutQueueProcessorSchema.OutQueueProcessorTaskResult,
//"Задача обработчика очереди исходящих сообщений"
//);

//console.log(sCheckResult);
