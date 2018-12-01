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

//Чтение данных из курсора
const readCursorData = cursor => {
    return new Promise((resolve, reject) => {
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
    });
};

//Подключение к БД
const connect = async prms => {
    try {
        const conn = await oracledb.getConnection({
            user: prms.sUser,
            password: prms.sPassword,
            connectString: prms.sConnectString
        });
        if (prms.sSessionAppName) conn.module = prms.sSessionAppName;
        return conn;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Отключение от БД
const disconnect = async prms => {
    try {
        await prms.connection.close();
        return;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Получение списка сервисов
const getServices = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.SERVICES_GET(RCSERVICES => :RCSERVICES); END;",
            { RCSERVICES: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
            { outFormat: oracledb.OBJECT }
        );
        let rows = await readCursorData(res.outBinds.RCSERVICES);
        return rows;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Получение списка функций сервиса
const getServiceFunctions = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.SERVICEFNS_GET(NEXSSERVICE => :NEXSSERVICE, RCSERVICEFNS => :RCSERVICEFNS); END;",
            { NEXSSERVICE: prms.nServiceId, RCSERVICEFNS: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
            { outFormat: oracledb.OBJECT }
        );
        let rows = await readCursorData(res.outBinds.RCSERVICEFNS);
        return rows;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Запись в протокол работы
const log = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.LOG_PUT(NLOG_STATE => :NLOG_STATE, SMSG => :SMSG, NEXSSERVICE => :NEXSSERVICE, NEXSSERVICEFN => :NEXSSERVICEFN, NEXSQUEUE => :NEXSQUEUE, RCLOG => :RCLOG); END;",
            {
                NLOG_STATE: prms.nLogState,
                SMSG: prms.sMsg,
                NEXSSERVICE: prms.nServiceId,
                NEXSSERVICEFN: prms.nServiceFnId,
                NEXSQUEUE: prms.nQueueId,
                RCLOG: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCLOG);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Считывание очередной порции исходящих сообщений из очереди
const getQueueOutgoing = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_SRV_TYPE_SEND_GET(NPORTION_SIZE => :NPORTION_SIZE, RCQUEUES => :RCQUEUES); END;",
            {
                NPORTION_SIZE: prms.nPortionSize,
                RCQUEUES: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            {
                outFormat: oracledb.OBJECT,
                fetchInfo: { blMsg: { type: oracledb.BUFFER }, blResp: { type: oracledb.BUFFER } }
            }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUES);
        return rows;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Помещение очередного входящего сообщения в очередь
const putQueueIncoming = async prms => {};

//Установка значения в сообщении очереди
const setQueueState = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_EXEC_STATE_SET(NEXSQUEUE => :NEXSQUEUE, NEXEC_STATE => :NEXEC_STATE, SEXEC_MSG => :SEXEC_MSG, NINC_EXEC_CNT => :NINC_EXEC_CNT, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                NEXEC_STATE: prms.nExecState,
                SEXEC_MSG: prms.sExecMsg,
                NINC_EXEC_CNT: prms.nIncExecCnt,
                RCQUEUE: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            {
                outFormat: oracledb.OBJECT,
                autoCommit: true,
                fetchInfo: { blMsg: { type: oracledb.BUFFER }, blResp: { type: oracledb.BUFFER } }
            }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

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
exports.setQueueState = setQueueState;
