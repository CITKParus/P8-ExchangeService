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

//Получение контекста сервиса
const getServiceContext = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.SERVICE_CTX_GET(NFLAG_SMART => 0, NEXSSERVICE => :NEXSSERVICE, RCSERVICE_CTX => :RCSERVICE_CTX); END;",
            { NEXSSERVICE: prms.nServiceId, RCSERVICE_CTX: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
            { outFormat: oracledb.OBJECT }
        );
        let rows = await readCursorData(res.outBinds.RCSERVICE_CTX);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Установка контекста сервиса
const setServiceContext = async prms => {
    try {
        await prms.connection.execute(
            "BEGIN PKG_EXS.SERVICE_CTX_SET(NEXSSERVICE => :NEXSSERVICE, SCTX => :SCTX, DCTX_EXP => :DCTX_EXP); END;",
            { NEXSSERVICE: prms.nServiceId, SCTX: prms.sCtx, DCTX_EXP: prms.dCtxExp },
            { autoCommit: true }
        );
    } catch (e) {
        throw new Error(e.message);
    }
};

//Очистка контекста сервиса
const clearServiceContext = async prms => {
    try {
        await prms.connection.execute(
            "BEGIN PKG_EXS.SERVICE_CTX_CLEAR(NEXSSERVICE => :NEXSSERVICE); END;",
            { NEXSSERVICE: prms.nServiceId },
            { autoCommit: true }
        );
    } catch (e) {
        throw new Error(e.message);
    }
};

//Проверка атуентифицированности сервиса
const isServiceAuth = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN :RET := PKG_EXS.SERVICE_IS_AUTH(NEXSSERVICE => :NEXSSERVICE); END;",
            { NEXSSERVICE: prms.nServiceId, RET: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }
        );
        return res.outBinds.RET;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Постановка в очередь задания на аутентификацию сервиса
const putServiceAuthInQueue = async prms => {
    try {
        await prms.connection.execute(
            "BEGIN PKG_EXS.SERVICE_AUTH_PUT_INQUEUE(NEXSSERVICE => :NEXSSERVICE); END;",
            { NEXSSERVICE: prms.nServiceId },
            { autoCommit: true }
        );
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

//Считывание записи очереди обмена
const getQueue = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => :NEXSQUEUE, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                RCQUEUE: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Помещение сообщения в очередь
const putQueue = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => :NEXSSERVICEFN, BMSG => :BMSG, NEXSQUEUE => :NEXSQUEUE, NLNK_COMPANY => :NLNK_COMPANY, NLNK_DOCUMENT => :NLNK_DOCUMENT, SLNK_UNITCODE => :SLNK_UNITCODE, SOPTIONS => :SOPTIONS, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSSERVICEFN: prms.nServiceFnId,
                BMSG: prms.blMsg,
                NEXSQUEUE: prms.nQueueId,
                NLNK_COMPANY: prms.nLnkCompanyId,
                NLNK_DOCUMENT: prms.nLnkDocumentId,
                SLNK_UNITCODE: prms.sLnkUnitcode,
                SOPTIONS: prms.sOptions,
                RCQUEUE: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE);
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
            { outFormat: oracledb.OBJECT }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUES);
        return rows;
    } catch (e) {
        throw new Error(e.message);
    }
};

//Установка значения состояния в сообщении очереди
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
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Считывание данных сообщения очереди
const getQueueMsg = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_MSG_GET(NEXSQUEUE => :NEXSQUEUE, RCQUEUE_MSG => :RCQUEUE_MSG); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                RCQUEUE_MSG: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            {
                outFormat: oracledb.OBJECT,
                autoCommit: true,
                fetchInfo: { blMsg: { type: oracledb.BUFFER } }
            }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE_MSG);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Установка данных сообщения очереди
const setQueueMsg = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => :NEXSQUEUE, BMSG => :BMSG, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                BMSG: prms.blMsg,
                RCQUEUE: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Считывание результата обработки сообщения очереди
const getQueueResp = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_RESP_GET(NEXSQUEUE => :NEXSQUEUE, RCQUEUE_RESP => :RCQUEUE_RESP); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                RCQUEUE_RESP: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            {
                outFormat: oracledb.OBJECT,
                autoCommit: true,
                fetchInfo: { blResp: { type: oracledb.BUFFER } }
            }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE_RESP);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Установка результата обработки сообщения очереди
const setQueueResp = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_RESP_SET(NEXSQUEUE => :NEXSQUEUE, BRESP => :BRESP, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                BRESP: prms.blResp,
                RCQUEUE: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCQUEUE);
        return rows[0];
    } catch (e) {
        throw new Error(e.message);
    }
};

//Исполнение обработчика со стороны БД для сообщения очереди
const execQueuePrc = async prms => {
    try {
        let res = await prms.connection.execute(
            "BEGIN PKG_EXS.QUEUE_PRC(NEXSQUEUE => :NEXSQUEUE, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                RCQUEUE: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
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
exports.getServiceContext = getServiceContext;
exports.setServiceContext = setServiceContext;
exports.clearServiceContext = clearServiceContext;
exports.isServiceAuth = isServiceAuth;
exports.putServiceAuthInQueue = putServiceAuthInQueue;
exports.log = log;
exports.getQueue = getQueue;
exports.putQueue = putQueue;
exports.getQueueOutgoing = getQueueOutgoing;
exports.setQueueState = setQueueState;
exports.getQueueMsg = getQueueMsg;
exports.setQueueMsg = setQueueMsg;
exports.getQueueResp = getQueueResp;
exports.setQueueResp = setQueueResp;
exports.execQueuePrc = execQueuePrc;
