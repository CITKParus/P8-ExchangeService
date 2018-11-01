/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: глобавльные константы
*/

//-----------------
// Интерфейс модуля
//-----------------

//Путь к модулям
exports.MODULES_PATH_CORE = "@core"; //Модули ядра
exports.MODULES_PATH_EX = "@modules"; //Дополнительные пользовательские модули

//Типовые коды ошибок подключения модулей
exports.ERR_MODULES_NO_MODULE_SPECIFIED = "ERR_MODULES_NO_MODULE_SPECIFIED"; //Не указан подключаемый модуль
exports.ERR_MODULES_BAD_INTERFACE = "ERR_MODULES_BAD_INTERFACE"; //Ошибочный интерфейс подключаемого модуля

//Типовые коды ошибок работы с БД
exports.ERR_DB_CONNECT = "ERR_DB_CONNECT"; //Ошибка подключения к БД
exports.ERR_DB_DISCONNECT = "ERR_DB_DISCONNECT"; //Ошибка отключения от БД
