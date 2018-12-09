/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: глобавльные константы
*/

//-----------------
// Интерфейс модуля
//-----------------

//Путь к модулям
exports.SMODULES_PATH_CORE = "@core"; //Модули ядра
exports.SMODULES_PATH_MODULES = "@modules"; //Дополнительные пользовательские модули
exports.SMODULES_PATH_MODELS = "@models"; //Модели данных и схемы валидации

//Типовые коды ошибок
exports.SERR_COMMON = "ERR_COMMON"; //Общая ошибка
exports.SERR_UNEXPECTED = "ERR_UNEXPECTED"; //Неожиданная ошибка

//Типовые коды ошибок подключения модулей
exports.SERR_MODULES_NO_MODULE_SPECIFIED = "ERR_MODULES_NO_MODULE_SPECIFIED"; //Не указан подключаемый модуль
exports.SERR_MODULES_BAD_INTERFACE = "ERR_MODULES_BAD_INTERFACE"; //Ошибочный интерфейс подключаемого модуля

//Типовые коды ошибок работы с объектами
exports.SERR_OBJECT_BAD_INTERFACE = "ERR_OBJECT_BAD_INTERFACE"; //Ошибочный интерфейс объекта

//Типовые коды ошибок проверки доступности удалённых сервисов
exports.SERR_SERVICE_UNAVAILABLE = "ERR_SERVICE_UNAVAILABLE"; //Удалённый сервис недоступен

//Типовые коды ошибок отправки e-mail уведомлений
exports.SERR_MAIL_FAILED = "ERR_MAIL_FAILED"; //Ошибка отправки почтового уведомления
