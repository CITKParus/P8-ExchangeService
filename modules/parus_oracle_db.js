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

// Состояния исполнения записей очереди сервиса
const NQUEUE_EXEC_STATE_INQUEUE = 0; //Поставлено в очередь
const NQUEUE_EXEC_STATE_APP = 1; //Обрабатывается сервером приложений
const NQUEUE_EXEC_STATE_APP_OK = 2; //Успешно обработано сервером приложений
const NQUEUE_EXEC_STATE_APP_ERR = 3; //Ошибка обработки сервером приложений
const NQUEUE_EXEC_STATE_DB = 4; //Обрабатывается СУБД
const NQUEUE_EXEC_STATE_DB_OK = 5; //Успешно обработано СУБД
const NQUEUE_EXEC_STATE_DB_ERR = 6; //Ошибка обработки СУБД
const NQUEUE_EXEC_STATE_OK = 7; //Обработано успешно
const NQUEUE_EXEC_STATE_ERR = 8; //Обработано с ошибками
const SQUEUE_EXEC_STATE_INQUEUE = "INQUEUE"; //Поставлено в очередь
const SQUEUE_EXEC_STATE_APP = "APP"; //Обрабатывается сервером приложений
const SQUEUE_EXEC_STATE_APP_OK = "APP_OK"; //Успешно обработано сервером приложений
const SQUEUE_EXEC_STATE_APP_ERR = "APP_ERR"; //Ошибка обработки сервером приложений
const SQUEUE_EXEC_STATE_DB = "DB"; //Обрабатывается СУБД
const SQUEUE_EXEC_STATE_DB_OK = "DB_OK"; //Успешно обработано СУБД
const SQUEUE_EXEC_STATE_DB_ERR = "DB_ERR"; //Ошибка обработки СУБД
const SQUEUE_EXEC_STATE_OK = "OK"; //Обработано успешно
const SQUEUE_EXEC_STATE_ERR = "ERR"; //Обработано с ошибками

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
            "BEGIN PKG_EXS.SERVICEFN_GET(NSERVICE => :NSERVICE, RCSERVICEFNS => :RCSERVICEFNS); END;",
            { NSERVICE: prms.nServiceId, RCSERVICEFNS: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT } },
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
            "BEGIN PKG_EXS.QUEUE_NEXT_GET(NPORTION_SIZE => :NPORTION_SIZE, NSRV_TYPE => :NSRV_TYPE, RCQUEUES => :RCQUEUES); END;",
            {
                NPORTION_SIZE: prms.nPortionSize,
                NSRV_TYPE: NSRV_TYPE_SEND,
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
            "BEGIN PKG_EXS.QUEUE_EXEC_STATE_SET(NEXSQUEUE => :NEXSQUEUE, NEXEC_STATE => :NEXEC_STATE, SEXEC_MSG => :SEXEC_MSG, RCQUEUE => :RCQUEUE); END;",
            {
                NEXSQUEUE: prms.nQueueId,
                NEXEC_STATE: prms.nExecState,
                SEXEC_MSG: prms.sExecMsg,
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
