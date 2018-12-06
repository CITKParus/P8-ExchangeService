/*
  Сервис интеграции ПП Парус 8 с WEB API
  Конфигурация сервера приложений
*/

//------------
// Тело модуля
//------------

//Параметры подключения к БД
let dbConnect = {
    //Пользователь БД
    sUser: "parus",
    //Пароль пользователя БД
    sPassword: "parus",
    //Строка подключения к БД
    sConnectString: "DEMOP_CITKSERV",
    //Наименование сервера приложений в сессии БД
    sSessionAppName: "PARUS$ExchangeServer",
    //Подключаемый модуль обслуживания БД (низкоуровневые функции работы с СУБД)
    sConnectorModule: "parus_oracle_db.js"
};

//Параметры обработки очереди исходящих сообщений
let outGoing = {
    //Количество одновременно обрабатываемых исходящих сообщений
    nMaxWorkers: 2,
    //Интервал проверки наличия исходящих сообщений (мс)
    nCheckTimeout: 1
};

//-----------------
// Интерфейс модуля
//-----------------

module.exports = {
    dbConnect,
    outGoing
};
