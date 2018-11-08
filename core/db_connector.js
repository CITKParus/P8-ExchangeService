/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: взаимодействие с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const glConst = require("@core/constants.js"); //Глобальные константы
const { checkModuleInterface, makeModuleFullPath, checkObject } = require("@core/utils.js"); //Вспомогательные функции
const { ServerError } = require("@core/server_errors.js"); //Типовая ошибка

//------------
// Тело модуля
//------------

class DBConnector {
    //Конструктор
    constructor(dbConnect) {
        //Проверяем структуру переданного объекта для подключения
        let checkResult = checkObject(dbConnect, {
            fields: [
                { name: "user", required: true },
                { name: "password", required: true },
                { name: "connectString", required: true },
                { name: "module", required: false }
            ]
        });
        //Если структура объекта в норме
        if (!checkResult) {
            //Проверяем наличие модуля для работы с БД в настройках подключения
            if (dbConnect.module) {
                //Подключим модуль
                this.connector = require(makeModuleFullPath(dbConnect.module));
                //Проверим его интерфейс
                if (
                    !checkModuleInterface(this.connector, {
                        functions: [
                            "connect",
                            "disconnect",
                            "getServices",
                            "log",
                            "getQueueOutgoing",
                            "putQueueIncoming",
                            "setQueueValue"
                        ]
                    })
                ) {
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
        } else {
            throw new ServerError(
                glConst.ERR_OBJECT_BAD_INTERFACE,
                "Объект имеет недопустимый интерфейс: " + checkResult
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
    //Получить список сервисов
    async getServices() {
        try {
            let res = await this.connector.getServices(this.connection);
            return res;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_EXECUTE, e.message);
        }
    }
    //Запись в журнал работы
    async putLog(msg, queueID) {
        try {
            let res = await this.connector.log(this.connection, msg, queueID);
            return res;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_EXECUTE, e.message);
        }
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.DBConnector = DBConnector;
