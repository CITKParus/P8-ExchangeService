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

//----------
// Константы
//----------

//Состояния записей журнала работы сервиса
const NLOG_STATE_INF = 0; //Информация
const NLOG_STATE_WRN = 1; //Предупреждение
const NLOG_STATE_ERR = 2; //Ошибка

//------------
// Тело модуля
//------------

class DBConnector {
    //Конструктор
    constructor(prms) {
        //Проверяем структуру переданного объекта для подключения
        let checkResult = checkObject(prms, {
            fields: [
                { name: "sUser", required: true },
                { name: "sPassword", required: true },
                { name: "sConnectString", required: true },
                { name: "sSessionModuleName", required: true },
                { name: "sConnectorModule", required: false }
            ]
        });
        //Если структура объекта в норме
        if (!checkResult) {
            //Проверяем наличие модуля для работы с БД в настройках подключения
            if (prms.sConnectorModule) {
                //Подключим модуль
                this.connector = require(makeModuleFullPath(prms.sConnectorModule));
                //Проверим его интерфейс
                if (
                    !checkModuleInterface(this.connector, {
                        functions: [
                            "connect",
                            "disconnect",
                            "getServices",
                            "getServiceFunctions",
                            "log",
                            "getQueueOutgoing",
                            "putQueueIncoming",
                            "setQueueValue"
                        ]
                    })
                ) {
                    throw new ServerError(
                        glConst.ERR_MODULES_BAD_INTERFACE,
                        "Модуль " + prms.sConnectorModule + " реализует неверный интерфейс!"
                    );
                }
                //Всё успешно - сохраним настройки подключения
                this.connectSettings = {};
                _.extend(this.connectSettings, prms);
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
            this.connection = await this.connector.connect({
                sUser: this.connectSettings.sUser,
                sPassword: this.connectSettings.sPassword,
                sConnectString: this.connectSettings.sConnectString,
                sSessionModuleName: this.connectSettings.sSessionModuleName
            });
            return this.connection;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_CONNECT, e.message);
        }
    }
    //Отключиться от БД
    async disconnect() {
        try {
            await this.connector.disconnect({ connection: this.connection });
            this.connection = {};
            return;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_DISCONNECT, e.message);
        }
    }
    //Получить список сервисов
    async getServices() {
        try {
            let srvs = await this.connector.getServices({ connection: this.connection });
            let srvsFuncs = srvs.map(async srv => {
                const response = await this.connector.getServiceFunctions({
                    connection: this.connection,
                    ddd: srv.NRN
                });
                let tmp = {};
                _.extend(tmp, srv, { FN: [] });
                response.map(f => {
                    tmp.FN.push(f);
                });
                return tmp;
            });
            let res = await Promise.all(srvsFuncs);
            return res;
        } catch (e) {
            throw new ServerError(glConst.ERR_DB_EXECUTE, e.message);
        }
    }
    //Запись в журнал работы
    async putLog(prms) {
        //Проверяем структуру переданного объекта для подключения
        let checkResult = checkObject(prms, {
            fields: [
                { name: "nLogState", required: true },
                { name: "sMsg", required: false },
                { name: "nServiceId", required: false },
                { name: "nServiceFnId", required: false },
                { name: "nQueueId", required: false }
            ]
        });
        //Если структура объекта в норме
        if (!checkResult) {
            try {
                let res = await this.connector.log({
                    connection: this.connection,
                    nLogState: prms.nLogState,
                    sMsg: prms.sMsg,
                    nServiceId: prms.nServiceId,
                    nServiceFnId: prms.nServiceFnId,
                    nQueueId: prms.nQueueId
                });
                return res;
            } catch (e) {
                throw new ServerError(glConst.ERR_DB_EXECUTE, e.message);
            }
        } else {
            throw new ServerError(
                glConst.ERR_OBJECT_BAD_INTERFACE,
                "qqqОбъект имеет недопустимый интерфейс: " + checkResult
            );
        }
    }
    //Считать очередную порцию исходящих сообщений
    async getOutgoing(prms) {
        //Проверяем структуру переданного объекта для подключения
        let checkResult = checkObject(prms, {
            fields: [{ name: "nPortionSize", required: true }]
        });
        //Если структура объекта в норме
        if (!checkResult) {
            try {
                let res = await this.connector.getQueueOutgoing({
                    connection: this.connection,
                    nPortionSize: prms.nPortionSize
                });
                return res;
            } catch (e) {
                throw new ServerError(glConst.ERR_DB_EXECUTE, e.message);
            }
        } else {
            throw new ServerError(
                glConst.ERR_OBJECT_BAD_INTERFACE,
                "Объект имеет недопустимый интерфейс: " + checkResult
            );
        }
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.NLOG_STATE_INF = NLOG_STATE_INF;
exports.NLOG_STATE_WRN = NLOG_STATE_WRN;
exports.NLOG_STATE_ERR = NLOG_STATE_ERR;
exports.DBConnector = DBConnector;
