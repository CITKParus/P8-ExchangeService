/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: ошибки системы
*/

//------------
// Тело модуля
//------------

//Общая ошибка системы
class ServerError extends Error {
    //Конструктор
    constructor(code, message) {
        super(message);
        this.code = code;
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.ServerError = ServerError;
