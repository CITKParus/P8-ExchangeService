/*
  Сервис интеграции ПП Парус 8 с WEB API
  Песочница для тестов
*/

require("module-alias/register");
const db = require("./core/db_connector"); //Взаимодействие с БД
const cfg = require("./config"); //Настройки сервера приложений
const rqp = require("request-promise");
const nodemailer = require("nodemailer");
const childProcess = require("child_process"); //Работа с дочерними процессами
const objOutQueueProcessorSchema = require("./models/obj_out_queue_processor"); //Схема валидации сообщений обмена с бработчиком очереди исходящих сообщений
const prmsOutQueueProcessorSchema = require("./models/prms_out_queue_processor"); //Схема валидации параметров функций бработчика очереди исходящих сообщений
const { getAppSrvFunction, makeModuleFullPath, validateObject } = require("./core/utils"); //Вспомогательные функции

/*
let proc = childProcess.fork("core/out_queue_processor", { silent: true });
*/
const getServices = async () => {
    let d = new db.DBConnector({ connectSettings: cfg.dbConnect });
    try {
        await d.connect();
        //let r = await d.getServices();
        //let q = await d.getOutgoing({ nPortionSize: 1 });
        await d.setQueueState({ nQueueId: 2, nExecState: 5, nIncExecCnt: 1 });
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

//getServices();
//let a = {};
//let sCheckResult = validateObject(a, prmsOutQueueProcessorSchema.sendOKResult, "Параметры sendOKResult");
//console.log(sCheckResult);

//let b = new Buffer("");
//console.log(b);

/*
const getSomeData = async () => {
    try {
        res = await rqp({
            //url: "http://123",
            url: "http://212.5.81.211:7778",
            //url:
            //    "http://212.5.81.211:7777/prj/PARUS.UDO_PKG_HTTP_PROC_W.PROCESS2?CPRMS={SACTION:GET_AGENT, NAGENT:184429}",
            method: "GET"
        });
        console.log(res);
    } catch (e) {
        let sError = "Неожиданная ошибка";
        if (e.error) {
            sError = `Ошибка передачи данных: ${e.error.code}`;
        }
        if (e.response) {
            sError = `Ошибка удалённого сервиса: ${e.response.statusCode} - ${e.response.statusMessage}`;
        }
        console.log(`При проверке доступности удалённого сервиса: ${sError}`);
    }
};

getSomeData();


const sendErrorByMail = e => {
    return new Promise((resolve, reject) => {
        //Параметры подключения
        let transporter = nodemailer.createTransport({
            host: "smtp.mail.ru",
            port: 465,
            secure: true,
            auth: {
                user: "chechnev@citk-parus.ru",
                pass: "Rxt67A_"
            }
        });
        //Параметры сообщения
        let mailOptions = {
            from: '"Сервис интеграции с WEB-API" <chechnev@citk-parus.ru>', // sender address
            to: "chechnev2@citk-parus.ru", // list of receivers
            subject: "Сервис недоступен", // Subject line
            text: "Сервис простаивает более 1-й минуты"
        };
        //Отправляем сообщение
        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                reject(`${error.code}: ${error.response}`);
            } else {
                if (info.rejected && Array.isArray(info.rejected) && info.rejected.length > 0) {
                    reject(`Сообщение не доствлено адресатам: ${info.rejected.join("; ")}`);
                } else {
                    resolve(info);
                }
            }
        });
    });
};

sendErrorByMail("Текст")
    .then(i => {
        console.log(i);
    })
    .catch(e => {
        console.log(e);
    });

*/

const chFn = val => {
    if (val) {
        let r = /^[a-z0-9_.-]+(.js)\/[a-z0-9_.-]+$/;
        return r.test(val.toLowerCase());
    }
    return true;
};

console.log(chFn("123sDf@mail.rU,wert@sSs.ru"));
console.log(chFn("parus_ag@n_info.js/buildAgentQuery"));
console.log(chFn("parus_agn_info.jsparseAgentInfo"));
console.log(chFn("parus_atoleforeBillPrintSend"));
console.log(chFn("parus_at/ol.js/afterBillPrintSend"));
console.log(chFn("parus_at\\ol.js/beforeBillSend"));
console.log(chFn("parus_atol.js/"));
