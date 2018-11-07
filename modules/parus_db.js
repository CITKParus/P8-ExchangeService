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
            function(err, connection) {
                if (err) {
                    reject(err);
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
            connection.close(function(err) {
                if (err) {
                    reject(err);
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
            connection.execute("select * from EXSSERVICE", [], { outFormat: oracledb.OBJECT }, (err, result) => {
                if (err) {
                    reject(err);
                }
                resolve(result.rows);
            });
        } else {
            reject(new Error("Не указано подключение"));
        }
    });
};

//Запись в протокол работы
const log = prms => {};

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
