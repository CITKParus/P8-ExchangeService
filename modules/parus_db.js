/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: работа с БД ПП Парус 8 (Oracle)
*/

//----------------------
// Подключение библиотек
//----------------------

const oracledb = require("oracledb"); //Работа с СУБД Oracle

//------------
// Тело модуля
//------------

//Подключение к БД
const connect = prms => {
    return new Promise((resolve, reject) => {
        oracledb.getConnection(
            {
                user: prms.user,
                password: prms.password,
                connectString: prms.connectString
            },
            (err, connection) => {
                if (err) {
                    reject(new Error(err.message));
                } else {
                    resolve(connection);
                }
            }
        );
    });
};

//Отключение от БД
const disconnect = connection => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.close(err => {
                if (err) {
                    reject(new Error(err.message));
                } else {
                    resolve();
                }
            });
        } else {
            reject(new Error("Не указано подключение"));
        }
    });
};

//Получение списка сервисов
const getServices = connection => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.execute(
                "BEGIN PKG_EXS.SERVICE_GET(RCSERVICES => :RCSERVICES); END;",
                { RCSERVICES: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
                { outFormat: oracledb.OBJECT },
                (err, result) => {
                    if (err) {
                        reject(new Error(err.message));
                    }
                    let cursor = result.outBinds.RCSERVICES;
                    let queryStream = cursor.toQueryStream();
                    let rows = [];
                    queryStream.on("data", row => {
                        rows.push(row);
                    });
                    queryStream.on("error", err => {
                        reject(new Error(err.message));
                    });
                    queryStream.on("close", () => {
                        resolve(rows);
                    });
                }
            );
        } else {
            reject(new Error("Не указано подключение"));
        }
    });
};

//Запись в протокол работы
const log = (connection, msg, queueID) => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.execute(
                "BEGIN PKG_EXS.LOG_PUT(NLOG_STATE => :NLOG_STATE, SMSG => :SMSG, NEXSQUEUE => :NEXSQUEUE, RCLOG => :RCLOG); END;",
                {
                    NLOG_STATE: 0,
                    SMSG: msg,
                    NEXSQUEUE: queueID,
                    RCLOG: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
                },
                { outFormat: oracledb.OBJECT, autoCommit: true },
                (err, result) => {
                    if (err) {
                        reject(new Error(err.message));
                    }
                    let cursor = result.outBinds.RCLOG;
                    let queryStream = cursor.toQueryStream();
                    let rows = [];
                    queryStream.on("data", row => {
                        rows.push(row);
                    });
                    queryStream.on("error", err => {
                        reject(new Error(err.message));
                    });
                    queryStream.on("close", () => {
                        resolve(rows[0]);
                    });
                }
            );
        } else {
            reject(new Error("Не указано подключение"));
        }
    });
};

//Считывание очередной порции исходящих сообщений из очереди
const getQueueOutgoing = prms => {};

//Помещение очередного входящего сообщения в очередь
const putQueueIncoming = prms => {};

//Установка значения в сообщении очереди
const setQueueValue = prms => {};

//-----------------
// Интерфейс модуля
//-----------------

exports.connect = connect;
exports.disconnect = disconnect;
exports.getServices = getServices;
exports.log = log;
exports.getQueueOutgoing = getQueueOutgoing;
exports.putQueueIncoming = putQueueIncoming;
exports.setQueueValue = setQueueValue;
