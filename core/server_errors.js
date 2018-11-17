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
    constructor(sCode, sMessage) {
        super(sMessage);
        this.sMessage = sMessage;
        this.sCode = sCode;
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.ServerError = ServerError;
