/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: работа с БД ПП Парус 8 (Oracle)
*/

//----------------------
// Подключение библиотек
//----------------------

const oracledb = require("oracledb"); //Работа с СУБД Oracle

//----------
// Константы
//----------

//Типы сервисов
const NSRV_TYPE_SEND = 0; //Отправка сообщений
const NSRV_TYPE_RECIVE = 1; //Получение сообщений
const SSRV_TYPE_SEND = "SEND"; //Отправка сообщений (строковый код)
const SSRV_TYPE_RECIVE = "RECIVE"; //Получение сообщений (строковый код)

//Признак оповещения о простое удаленного сервиса
const NUNAVLBL_NTF_SIGN_NO = 0; //Не оповещать о простое
const NUNAVLBL_NTF_SIGN_YES = 1; //Оповещать о простое
const SUNAVLBL_NTF_SIGN_NO = "UNAVLBL_NTF_NO"; //Не оповещать о простое (строковый код)
const SUNAVLBL_NTF_SIGN_YES = "UNAVLBL_NTF_YES"; //Оповещать о простое (строковый код)

//Состояния записей журнала работы сервиса
const NLOG_STATE_INF = 0; //Информация
const NLOG_STATE_WRN = 1; //Предупреждение
const NLOG_STATE_ERR = 2; //Ошибка
const SLOG_STATE_INF = "INF"; //Информация (строковый код)
const SLOG_STATE_WRN = "WRN"; //Предупреждение (строковые коды)
const SLOG_STATE_ERR = "ERR"; //Ошибка (строковый код)

//------------
// Тело модуля
//------------

//Подключение к БД
const connect = async prms => {
    try {
        const conn = await oracledb.getConnection({
            user: prms.user,
            password: prms.password,
            connectString: prms.connectString
        });
        return conn;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Отключение от БД
const disconnect = async connection => {
    if (connection) {
        try {
            const conn = await connection.close();
            return;
        } catch (e) {
            throw new Error(e.message);
        }
    } else {
        throw new Error("Не указано подключение");
    }
};

//Получение списка сервисов
const getServices = async connection => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.execute(
                "BEGIN PKG_EXS.SERVICE_GET(RCSERVICES => :RCSERVICES); END;",
                { RCSERVICES: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
                { outFormat: oracledb.OBJECT },
                (err, result) => {
                    if (err) {
                        reject(new Error(err.message));
                    } else {
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
                }
            );
        } else {
            reject(new Error("Не указано подключение"));
        }
    });
};

//Получение списка функций сервиса
const getServiceFunctions = (connection, serviceID) => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.execute(
                "BEGIN PKG_EXS.SERVICEFN_GET(NSERVICE => :NSERVICE, RCSERVICEFNS => :RCSERVICEFNS); END;",
                { NSERVICE: serviceID, RCSERVICEFNS: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
                { outFormat: oracledb.OBJECT },
                (err, result) => {
                    if (err) {
                        reject(new Error(err.message));
                    } else {
                        let cursor = result.outBinds.RCSERVICEFNS;
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
                }
            );
        } else {
            reject(new Error("Не указано подключение"));
        }
    });
};

//Запись в протокол работы
const log = (connection, logState, msg, queueID) => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.execute(
                "BEGIN PKG_EXS.LOG_PUT(NLOG_STATE => :NLOG_STATE, SMSG => :SMSG, NEXSQUEUE => :NEXSQUEUE, RCLOG => :RCLOG); END;",
                {
                    NLOG_STATE: logState,
                    SMSG: msg,
                    NEXSQUEUE: queueID,
                    RCLOG: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
                },
                { outFormat: oracledb.OBJECT, autoCommit: true },
                (err, result) => {
                    if (err) {
                        reject(new Error(err.message));
                    } else {
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
exports.getServiceFunctions = getServiceFunctions;
exports.log = log;
exports.getQueueOutgoing = getQueueOutgoing;
exports.putQueueIncoming = putQueueIncoming;
exports.setQueueValue = setQueueValue;
