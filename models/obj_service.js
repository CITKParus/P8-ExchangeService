/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модели данных: Описатель сервиса
*/

//----------------------
// Подключение библиотек
//----------------------

const Schema = require("validate"); //Схемы валидации

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

//------------------
//  Интерфейс модуля
//------------------

//Константы
exports.NSRV_TYPE_SEND = NSRV_TYPE_SEND;
exports.NSRV_TYPE_RECIVE = NSRV_TYPE_RECIVE;
exports.SSRV_TYPE_SEND = SSRV_TYPE_SEND;
exports.SSRV_TYPE_RECIVE = SSRV_TYPE_RECIVE;
exports.NUNAVLBL_NTF_SIGN_NO = NUNAVLBL_NTF_SIGN_NO;
exports.NUNAVLBL_NTF_SIGN_YES = NUNAVLBL_NTF_SIGN_YES;
exports.SUNAVLBL_NTF_SIGN_NO = SUNAVLBL_NTF_SIGN_NO;
exports.SUNAVLBL_NTF_SIGN_YES = SUNAVLBL_NTF_SIGN_YES;

//Схема валидации
exports.schema = new Schema({
    //Идентификатор сервиса
    nId: {
        type: Number,
        required: true,
        message: {
            type: "Идентификатор сервиса (nId) должен быть числом",
            required: "Не указан идентификатор сервиса (nId)"
        }
    },
    //Код сервиса
    sCode: {
        type: String,
        required: true,
        message: {
            type: "Код сервиса (sCode) должен быть строкой",
            required: "Не указан код сервиса (sCode)"
        }
    },
    //Тип сервиса (числовой код)
    nSrvType: {
        type: Number,
        enum: [NSRV_TYPE_SEND, NSRV_TYPE_RECIVE],
        required: true,
        message: {
            enum: "Значение числового кода типа сервиса (nSrvType) не поддерживается",
            type: "Числовой код типа сервиса (nSrvType) имеет недопустимый тип данных",
            required: "Не указан числовой код типа сервиса (nSrvType)"
        }
    } /*,
    //Тип сервиса (строковый код)
    sSrvType: {
        type: String,
        enum: [SSRV_TYPE_SEND, SSRV_TYPE_RECIVE],
        required: true,
        message: {
            enum: "Значение строкового кода типа сервиса (sSrvType) не поддерживается",
            type: "Строковый код типа сервиса (sSrvType) имеет недопустимый тип данных",
            required: "Не указан строковый код типа сервиса (sSrvType)"
        }
    },
    //Корневой каталог сервиса
    sSrvRoot: {}*/
    //Имя пользователя (для аутентификации на внешнем сервисе при отправке сообщений)
    //sSrvUser: {},
    //Пароль пользователя (для аутентификации на внешнем сервисе при отправке сообщений)
    //sSrvPass: {},
    //Признак необходимости оповещения о простое внешнего сервиса (числовой код)
    //nUnavlblNtfSign: {},
    //Признак необходимости оповещения о простое внешнего сервиса (строковый код)
    //sUnavlblNtfSign: {},
    //Максимальное время простоя (мин) удалённого сервиса для генерации оповещения
    //nUnavlblNtfTime: {},
    //Список адресов E-Mail для оповещения о простое внешнего сервиса
    //sUnavlblNtfMail: {},
    //Список функций сервиса
    //fn: {}
});
