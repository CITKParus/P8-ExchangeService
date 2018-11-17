/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: взаимодействие с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const glConst = require("../core/constants.js"); //Глобальные константы
const { ServerError } = require("../core/server_errors.js"); //Типовая ошибка
const { checkModuleInterface, makeModuleFullPath, checkObject } = require("../core/utils.js"); //Вспомогательные функции

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
        let sCheckResult = checkObject(prms, {
            fields: [
                { sName: "sUser", bRequired: true },
                { sName: "sPassword", bRequired: true },
                { sName: "sConnectString", bRequired: true },
                { sName: "sSessionModuleName", bRequired: true },
                { sName: "sConnectorModule", bRequired: false }
            ]
        });
        //Если структура объекта в норме
        if (!sCheckResult) {
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
                        glConst.SERR_MODULES_BAD_INTERFACE,
                        "Модуль " + prms.sConnectorModule + " реализует неверный интерфейс!"
                    );
                }
                //Всё успешно - сохраним настройки подключения
                this.connectSettings = {};
                _.extend(this.connectSettings, prms);
                //Инициализируем остальные свойства
                this.connection = {};
                this.bConnected = false;
            } else {
                throw new ServerError(
                    glConst.SERR_MODULES_NO_MODULE_SPECIFIED,
                    "Не указано имя подключаемого модуля-коннектора!"
                );
            }
        } else {
            throw new ServerError(
                glConst.SERR_OBJECT_BAD_INTERFACE,
                "Объект имеет недопустимый интерфейс: " + sCheckResult
            );
        }
    }
    //Подключиться к БД
    async connect() {
        try {
            this.connection = await this.connector.connect(this.connectSettings);
            this.bConnected = true;
            return this.connection;
        } catch (e) {
            throw new ServerError(glConst.SERR_DB_CONNECT, e.message);
        }
    }
    //Отключиться от БД
    async disconnect() {
        if (this.bConnected) {
            try {
                await this.connector.disconnect({ connection: this.connection });
                this.connection = {};
                this.bConnected = false;
                return;
            } catch (e) {
                throw new ServerError(glConst.SERR_DB_DISCONNECT, e.message);
            }
        }
    }
    //Получить список сервисов
    async getServices() {
        if (this.bConnected) {
            try {
                let srvs = await this.connector.getServices({ connection: this.connection });
                let srvsFuncs = srvs.map(async srv => {
                    const response = await this.connector.getServiceFunctions({
                        connection: this.connection,
                        nServiceId: srv.nId
                    });
                    let tmp = {};
                    _.extend(tmp, srv, { functions: [] });
                    response.map(f => {
                        tmp.functions.push(f);
                    });
                    return tmp;
                });
                let res = await Promise.all(srvsFuncs);
                return res;
            } catch (e) {
                throw new ServerError(glConst.SERR_DB_EXECUTE, e.message);
            }
        } else {
            throw new ServerError(glConst.SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
    //Запись в журнал работы
    async putLog(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданного объекта для подключения
            let sCheckResult = checkObject(prms, {
                fields: [
                    { sName: "nLogState", bRequired: true },
                    { sName: "sMsg", bRequired: false },
                    { sName: "nServiceId", bRequired: false },
                    { sName: "nServiceFnId", bRequired: false },
                    { sName: "nQueueId", bRequired: false }
                ]
            });
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    let logData = { connection: this.connection };
                    _.extend(logData, prms);
                    let res = await this.connector.log(logData);
                    return res;
                } catch (e) {
                    throw new ServerError(glConst.SERR_DB_EXECUTE, e.message);
                }
            } else {
                throw new ServerError(
                    glConst.SERR_OBJECT_BAD_INTERFACE,
                    "Объект имеет недопустимый интерфейс: " + sCheckResult
                );
            }
        } else {
            throw new ServerError(glConst.SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
    //Запись информации в журнал работы
    async putLogInf(sMsg, prms) {
        let logData = {};
        _.extend(logData, prms);
        logData.nLogState = NLOG_STATE_INF;
        logData.sMsg = sMsg;
        try {
            let res = await this.putLog(logData);
            return res;
        } catch (e) {
            throw new ServerError(glConst.SERR_DB_EXECUTE, e.message);
        }
    }
    //Запись предупреждения в журнал работы
    async putLogWrn(sMsg, prms) {
        let logData = {};
        _.extend(logData, prms);
        logData.nLogState = NLOG_STATE_WRN;
        logData.sMsg = sMsg;
        try {
            let res = await this.putLog(logData);
            return res;
        } catch (e) {
            throw new ServerError(glConst.SERR_DB_EXECUTE, e.message);
        }
    }
    //Запись ошибки в журнал работы
    async putLogErr(sMsg, prms) {
        let logData = {};
        _.extend(logData, prms);
        logData.nLogState = NLOG_STATE_ERR;
        logData.sMsg = sMsg;
        try {
            let res = await this.putLog(logData);
            return res;
        } catch (e) {
            throw new ServerError(glConst.SERR_DB_EXECUTE, e.message);
        }
    }
    //Считать очередную порцию исходящих сообщений
    async getOutgoing(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданного объекта для подключения
            let sCheckResult = checkObject(prms, {
                fields: [{ sName: "nPortionSize", bRequired: true }]
            });
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    let res = await this.connector.getQueueOutgoing({
                        connection: this.connection,
                        nPortionSize: prms.nPortionSize
                    });
                    return res;
                } catch (e) {
                    throw new ServerError(glConst.SERR_DB_EXECUTE, e.message);
                }
            } else {
                throw new ServerError(
                    glConst.SERR_OBJECT_BAD_INTERFACE,
                    "Объект имеет недопустимый интерфейс: " + sCheckResult
                );
            }
        } else {
            throw new ServerError(glConst.SERR_DB_EXECUTE, "Нет подключения к БД");
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
