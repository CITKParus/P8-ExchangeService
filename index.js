/*
  Сервис интеграции ПП Парус 8 с WEB API
  Точка входа в сервер приложений
*/

//----------------------
// Подключение библиотек
//----------------------

require("module-alias/register");
const cfg = require("./config.js");
const lg = require("./core/logger.js");
const db = require("./core/db_connector.js");
const oq = require("./core/out_queue.js");

//--------------------------
// Глобальные идентификаторы
//--------------------------

let dbConn = new db.DBConnector(cfg.dbConnect); //Взаимодействие с БД
let logger = new lg.Logger(); //Протоколирование работы
let outQ = new oq.OutQueue(cfg.outgoing, dbConn, logger); //Отслеживание очереди исходящих

//----------------------------------------
// Управление процессом сервера приложений
//----------------------------------------

//При подключении к БД
const onDBConnected = async connection => {
    logger.setDBConnector(dbConn);
    await logger.info("Сервер приложений подключен к БД");
};

//При отключении от БД
const onDBDisconnected = async () => {
    logger.removeDBConnector();
    await logger.info("Сервер приложений отключен от БД");
};

//Запуск сервера
const run = async () => {
    await logger.info("Запуск сервера приложений...");
    dbConn.on(db.SEVT_DB_CONNECTOR_CONNECTED, onDBConnected);
    dbConn.on(db.SEVT_DB_CONNECTOR_DISCONNECTED, onDBDisconnected);
    await logger.info("Подключение сервера приложений к БД...");
    try {
        await dbConn.connect();
    } catch (e) {
        await logger.error("Ошибка подключения к БД: " + e.sCODE + ": " + e.sMessage);
        stop();
        return;
    }
    await outQ.startProcessing();
    await logger.info("Сервер приложений запущен");
};

//Останов сервера
const stop = async () => {
    await logger.warn("Останов сервера приложений...");
    outQ.stopProcessing();
    if (dbConn.bConnected) {
        await logger.warn("Отключение сервера приложений от БД...");
        try {
            await dbConn.disconnect();
            process.exit(0);
        } catch (e) {
            await logger.error("Ошибка отключения от БД: " + e.sCODE + ": " + e.sMessage);
            process.exit(1);
        }
    } else {
        process.exit(0);
    }
};

//Обработка события "выход" жизненного цикла процесса
process.on("exit", code => {
    //Сообщим о завершении процесса
    logger.warn("Сервер приложений остановлен (код: " + code + ") ");
});

//Перехват CTRL + C (останова процесса)
process.on("SIGINT", () => {
    //Инициируем выход из процесса
    stop();
});

//------------
// Точка входа
//------------

//Старутем
run();
