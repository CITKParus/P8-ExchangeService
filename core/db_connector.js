/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: взаимодействие с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const glConst = require("@core/constants.js"); //Глобальные константы
const { checkModuleInterface, makeModuleFullPath } = require("@core/utils.js"); //Вспомогательные функции
const { ServerError } = require("@core/server_errors.js"); //Типовая ошибка

//------------
// Тело модуля
//------------

class DBConnector {
    //Конструктор
    constructor(dbConnect) {
        //Проверяем наличие модуля для работы с БД в настройках подключения
        if (dbConnect.module) {
            //Подключим модуль
            this.connector = require(makeModuleFullPath(dbConnect.module));
            //Проверим его интерфейс
            if (!checkModuleInterface(this.connector, { functions: ["connect", "disconnect", "execute"] })) {
                throw new ServerError(
                    glConst.ERR_MODULES_BAD_INTERFACE,
                    "Модуль " + dbConnect.module + " реализует неверный интерфейс!"
                );
            }
            //Всё успешно - сохраним настройки подключения
            this.connectSettings = {};
            _.extend(this.connectSettings, dbConnect);
            //Инициализируем остальные свойства
            this.connection = {};
        } else {
            throw new ServerError(
                glConst.ERR_MODULES_NO_MODULE_SPECIFIED,
                "Не указано имя подключаемого модуля-коннектора!"
            );
        }
    }
    //Подключиться к БД
    async connect() {
        try {
            this.connection = await this.connector.connect(this.connectSettings);
            return this.connection;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_CONNECT, e.message);
        }
    }
    //Отключиться от БД
    async disconnect() {
        try {
            await this.connector.disconnect(this.connection);
            this.connection = {};
            return;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_DISCONNECT, e.message);
        }
    }
    //Исполнить запрос
    async execute() {}
}

//-----------------
// Интерфейс модуля
//-----------------

exports.DBConnector = DBConnector;
