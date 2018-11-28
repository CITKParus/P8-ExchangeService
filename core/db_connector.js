/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: взаимодействие с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const EventEmitter = require("events"); //Обработчик пользовательских событий
const { ServerError } = require("../core/server_errors"); //Типовая ошибка
const { makeModuleFullPath, validateObject } = require("../core/utils"); //Вспомогательные функции
const prmsDBConnectorSchema = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля
const intfDBConnectorModuleSchema = require("../models/intf_db_connector_module"); //Схема валидации интерфейса модуля взаимодействия с БД
const objServicesSchema = require("../models/obj_services"); //Схема валидации списка сервисов
const objQueueSchema = require("../models/obj_queue"); //Схема валидации сообщения очереди обмена
const objQueuesSchema = require("../models/obj_queues"); //Схема валидации списка сообщений очереди обмена
const objLogSchema = require("../models/obj_log"); //Схема валидации записи журнала
const {
    SERR_MODULES_BAD_INTERFACE,
    SERR_OBJECT_BAD_INTERFACE,
    SERR_MODULES_NO_MODULE_SPECIFIED
} = require("../core/constants"); //Глобальные константы

//----------
// Константы
//----------

//Типовые коды ошибок работы с БД
const SERR_DB_CONNECT = "ERR_DB_CONNECT"; //Ошибка подключения к БД
const SERR_DB_DISCONNECT = "ERR_DB_DISCONNECT"; //Ошибка отключения от БД
const SERR_DB_EXECUTE = "ERR_DB_EXECUTE"; //Ошибка исполнения функции в БД

//События модуля
const SEVT_DB_CONNECTOR_CONNECTED = "DB_CONNECTOR_CONNECTED"; //Подключено к БД
const SEVT_DB_CONNECTOR_DISCONNECTED = "DB_CONNECTOR_DISCONNECTED"; //Отключено от БД

//------------
// Тело модуля
//------------

//Класс для взаимодействия с БД
class DBConnector extends EventEmitter {
    //Конструктор
    constructor(prms) {
        //создадим экземпляр родительского класса
        super();
        //Проверяем структуру переданного объекта для подключения
        let sCheckResult = validateObject(
            prms,
            prmsDBConnectorSchema.DBConnector,
            "Параметры конструктора класса DBConnector"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Проверяем наличие модуля для работы с БД в настройках подключения
            if (prms.connectSettings.sConnectorModule) {
                //Подключим модуль
                try {
                    this.connector = require(makeModuleFullPath(prms.connectSettings.sConnectorModule));
                } catch (e) {
                    throw new ServerError(
                        SERR_MODULES_BAD_INTERFACE,
                        "Ошибка подключения пользовательского модуля: " +
                            e.message +
                            ". Проверьте модуль на отсутствие синтаксических ошибок."
                    );
                }
                //Проверим его интерфейс
                let sCheckResult = validateObject(
                    this.connector,
                    intfDBConnectorModuleSchema.dbConnectorModule,
                    "Модуль " + prms.connectSettings.sConnectorModule
                );
                if (sCheckResult) {
                    throw new ServerError(SERR_MODULES_BAD_INTERFACE, sCheckResult);
                }
                //Всё успешно - сохраним настройки подключения
                this.connectSettings = _.cloneDeep(prms.connectSettings);
                //Инициализируем остальные свойства
                this.connection = null;
                this.bConnected = false;
            } else {
                throw new ServerError(
                    SERR_MODULES_NO_MODULE_SPECIFIED,
                    "Не указано имя подключаемого модуля-коннектора!"
                );
            }
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Подключиться к БД
    async connect() {
        //Подключаемся только если ещё не подключены
        if (!this.bConnected) {
            try {
                //Подключаемся
                this.connection = await this.connector.connect(this.connectSettings);
                //Выставим внутренний флаг подключения
                this.bConnected = true;
                //Расскажем всем, что подключились
                this.emit(SEVT_DB_CONNECTOR_CONNECTED, this.connection);
                //Возвращаем подключение
                return this.connection;
            } catch (e) {
                throw new ServerError(SERR_DB_CONNECT, e.message);
            }
        }
    }
    //Отключиться от БД
    async disconnect() {
        //Смысл отключаться есть только когда мы подключены, в противном случае - зачем тратить время
        if (this.bConnected) {
            try {
                //Отключаемся
                await this.connector.disconnect({ connection: this.connection });
                //Забываем подключение и удаляем флаги подключенности
                this.connection = null;
                this.bConnected = false;
                //Расскажем всем, что отключились
                this.emit(SEVT_DB_CONNECTOR_DISCONNECTED);
                //Вернём ничего
                return;
            } catch (e) {
                throw new ServerError(SERR_DB_DISCONNECT, e.message);
            }
        }
    }
    //Получить список сервисов
    async getServices() {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            try {
                //Забираем список сервисов и декорируем его заготовками под список функций
                let srvs = await this.connector.getServices({ connection: this.connection });
                srvs.forEach(s => {
                    s.functions = [];
                });
                //Валидируем его
                let sCheckResult = validateObject({ services: srvs }, objServicesSchema.Services, "Список сервисов");
                //Если в списке сервисов всё в порядке
                if (!sCheckResult) {
                    //Забираем для каждого из сервисов список его функций
                    let srvsFuncs = srvs.map(async srv => {
                        const response = await this.connector.getServiceFunctions({
                            connection: this.connection,
                            nServiceId: srv.nId
                        });
                        let tmp = _.cloneDeep(srv);
                        response.forEach(f => {
                            tmp.functions.push(f);
                        });
                        return tmp;
                    });
                    //Ждём пока все функции вернутся
                    let res = await Promise.all(srvsFuncs);
                    //Валидируем финальный объект
                    sCheckResult = validateObject({ services: res }, objServicesSchema.Services, "Список сервисов");
                    //Если валидация не прошла
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Успешно - отдаём список сервисов
                    return res;
                } else {
                    throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                }
            } catch (e) {
                if (e instanceof ServerError) throw e;
                else throw new ServerError(SERR_DB_EXECUTE, e.message);
            }
        } else {
            throw new ServerError(SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
    //Запись в журнал работы
    async putLog(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами для записи в журнал
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.putLog,
                "Параметры функции записи в журнал работы"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let logData = _.cloneDeep(prms);
                    logData.connection = this.connection;
                    //И выполним запись в журнал
                    let res = await this.connector.log(logData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(res, objLogSchema.Log, "Добавленная запись журнала работы");
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём добавленную запись
                    return res;
                } catch (e) {
                    throw new ServerError(SERR_DB_EXECUTE, e.message);
                }
            } else {
                throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
            }
        } else {
            throw new ServerError(SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
    //Запись информации в журнал работы
    async putLogInf(sMsg, prms) {
        //Подготовим параметры для передачи в БД
        let logData = _.cloneDeep(prms);
        //Выставим сообщение и тип записи журнала
        logData.nLogState = objLogSchema.NLOG_STATE_INF;
        logData.sMsg = sMsg;
        try {
            //Выполним запись в журнал
            let res = await this.putLog(logData);
            //Вернём добавленную запись
            return res;
        } catch (e) {
            throw new ServerError(SERR_DB_EXECUTE, e.message);
        }
    }
    //Запись предупреждения в журнал работы
    async putLogWrn(sMsg, prms) {
        //Подготовим параметры для передачи в БД
        let logData = _.cloneDeep(prms);
        //Выставим сообщение и тип записи журнала
        logData.nLogState = objLogSchema.NLOG_STATE_WRN;
        logData.sMsg = sMsg;
        try {
            //Выполним запись в журнал
            let res = await this.putLog(logData);
            //Вернём добавленную запись
            return res;
        } catch (e) {
            throw new ServerError(SERR_DB_EXECUTE, e.message);
        }
    }
    //Запись ошибки в журнал работы
    async putLogErr(sMsg, prms) {
        //Подготовим параметры для передачи в БД
        let logData = _.cloneDeep(prms);
        //Выставим сообщение и тип записи журнала
        logData.nLogState = objLogSchema.NLOG_STATE_ERR;
        logData.sMsg = sMsg;
        try {
            //Выполним запись в журнал
            let res = await this.putLog(logData);
            //Вернём добавленную запись
            return res;
        } catch (e) {
            throw new ServerError(SERR_DB_EXECUTE, e.message);
        }
    }
    //Считать очередную порцию исходящих сообщений
    async getOutgoing(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами считывания очереди
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.getOutgoing,
                "Параметры функции считывания очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let getQueueOutgoingData = _.cloneDeep(prms);
                    getQueueOutgoingData.connection = this.connection;
                    //Выполняем считывание из БД
                    let res = await this.connector.getQueueOutgoing(getQueueOutgoingData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(
                        { queues: res },
                        objQueuesSchema.Queues,
                        "Список сообщений очереди обмена"
                    );
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём сообщения очереди обмена
                    return res;
                } catch (e) {
                    throw new ServerError(SERR_DB_EXECUTE, e.message);
                }
            } else {
                throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
            }
        } else {
            throw new ServerError(SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
    //Установить состояние позиции очереди
    async setQueueState(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(prms, prmsDBConnectorSchema.setQueueState);
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let setStateData = _.cloneDeep(prms);
                setStateData.connection = this.connection;
                try {
                    //Исполняем действие в БД
                    let res = await this.connector.setQueueState(setStateData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(res, objQueueSchema.Queue, "Изменённое сообщение очереди обмена");
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём измененную запись
                    return res;
                } catch (e) {
                    if (e instanceof ServerError) throw e;
                    else throw new ServerError(SERR_DB_EXECUTE, e.message);
                }
            } else {
                throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
            }
        } else {
            throw new ServerError(SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.SERR_DB_CONNECT = SERR_DB_CONNECT;
exports.SERR_DB_DISCONNECT = SERR_DB_DISCONNECT;
exports.SERR_DB_EXECUTE = SERR_DB_EXECUTE;
exports.SEVT_DB_CONNECTOR_CONNECTED = SEVT_DB_CONNECTOR_CONNECTED;
exports.SEVT_DB_CONNECTOR_DISCONNECTED = SEVT_DB_CONNECTOR_DISCONNECTED;
exports.DBConnector = DBConnector;
