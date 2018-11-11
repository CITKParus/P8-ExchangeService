/*
  Сервис интеграции ПП Парус 8 с WEB API
  Точка входа в сервер приложений
*/

//----------------------
// Подключение библиотек
//----------------------

require("module-alias/register");
const cfg = require("./config.js");
const { Logger } = require("@core/logger.js");
const db = require("@core/db_connector.js");
const { ServerError } = require("@core/server_errors.js");
const utls = require("@core/utils.js");

//------------
// Тело модуля
//------------

try {
    let a = new db.DBConnector(cfg.dbConnect);
    a.connect()
        .then(res => {
            console.log("CONNECTED");
            a.getOutgoing(cfg.outgoing.portionSize)
                .then(res => {
                    if (res.length > 0) {
                        res.map(r => {
                            console.log(r);
                        });
                    } else {
                        console.log("NO MESSAGES IN QUEUE!!!");
                    }
                    a.putLog(db.MSG_TYPE_INF, "Сервер приложений подключен")
                        .then(res => {
                            console.log(res);
                            a.disconnect()
                                .then(res => {
                                    console.log("DISCONNECTED");
                                })
                                .catch(e => {
                                    console.log(e.code + ": " + e.message);
                                });
                        })
                        .catch(e => {
                            console.log(e.code + ": " + e.message);
                            setTimeout(() => {
                                a.disconnect()
                                    .then(res => {
                                        console.log("DISCONNECTED");
                                    })
                                    .catch(e => {
                                        console.log(e.code + ": " + e.message);
                                    });
                            }, 10000);
                        });
                })
                .catch(e => {
                    console.log(e.code + ": " + e.message);
                    a.disconnect()
                        .then(res => {
                            console.log("DISCONNECTED");
                        })
                        .catch(e => {
                            console.log(e.code + ": " + e.message);
                        });
                });
        })
        .catch(e => {
            console.log(e.code + ": " + e.message);
        });
} catch (e) {
    console.log(e.code + ": " + e.message);
}

/*

const log = new Logger();
log.error("Это ошибка");
log.warn("Предупреждение это");
log.info("Просто информация");



const test = async prms => {
    return new Promise((resolve, reject) => {
        if (prms == 0) {
            reject(new ServerError(1234, "Ошибка!"));
        } else {
            setTimeout(() => {
                resolve(prms + 1);
            }, 1000);
        }
    });
};

const callTest = async prms => {
    try {
        console.log("in async before");
        let a = await test(prms);
        console.log("in async after " + a);
        return a;
    } catch (e) {
        console.log("in async I'm here: " + e.code + " - " + e.message);
        throw e;
    }
};

process.on("unhandledRejection", err => {
    console.error("PROCESS ERROR: " + err.code + " - " + err.message);
    process.exit(0);
});

console.log("BEFORE");
callTest(0)
    .then(result => {
        console.log("MAIN RESULT: " + result);
    })
    .catch(err => {
        console.error("MAIN ERROR: " + err.code + " - " + err.message);
    });
console.log("AFTER");
*/
