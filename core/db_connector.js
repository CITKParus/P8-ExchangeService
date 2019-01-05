/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: взаимодействие с БД
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const EventEmitter = require("events"); //Обработчик пользовательских событий
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { makeModuleFullPath, validateObject } = require("./utils"); //Вспомогательные функции
const prmsDBConnectorSchema = require("../models/prms_db_connector"); //Схемы валидации параметров функций модуля
const intfDBConnectorModuleSchema = require("../models/intf_db_connector_module"); //Схема валидации интерфейса модуля взаимодействия с БД
const objServiceSchema = require("../models/obj_service"); //Схема валидации сервиса
const objServicesSchema = require("../models/obj_services"); //Схема валидации списка сервисов
const objServiceFunctionsSchema = require("../models/obj_service_functions"); //Схема валидации списка функций сервиса
const objQueueSchema = require("../models/obj_queue"); //Схема валидации сообщения очереди обмена
const objQueuesSchema = require("../models/obj_queues"); //Схема валидации списка сообщений очереди обмена
const objLogSchema = require("../models/obj_log"); //Схема валидации записи журнала
const {
    SERR_MODULES_BAD_INTERFACE,
    SERR_OBJECT_BAD_INTERFACE,
    SERR_MODULES_NO_MODULE_SPECIFIED
} = require("./constants"); //Глобальные константы

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
                        const response = await this.getServiceFunctions({ nServiceId: srv.nId });
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
    //Получить список функций для сервиса
    async getServiceFunctions(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами для считывания функций сервиса
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.getServiceFunctions,
                "Параметры функции считывания функций сервиса"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let getServiceFunctionsData = _.cloneDeep(prms);
                    getServiceFunctionsData.connection = this.connection;
                    //И выполним считывание функций сервиса
                    let res = await this.connector.getServiceFunctions(getServiceFunctionsData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(
                        { functions: res },
                        objServiceFunctionsSchema.ServiceFunctions,
                        "Список функций сервиса"
                    );
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Успешно - отдаём список функций сервиса
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
    //Получить контекст сервиса
    async getServiceContext(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами для получения контекста сервиса
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.getServiceContext,
                "Параметры функции считывания контекста сервиса"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let getServiceContextData = _.cloneDeep(prms);
                    getServiceContextData.connection = this.connection;
                    //И выполним считывание контекста сервиса
                    let res = await this.connector.getServiceContext(getServiceContextData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(res, objServiceSchema.ServiceCtx, "Контекст сервиса");
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Успешно - отдаём контекст считанный сервиса
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
    //Установить контекст сервиса
    async setServiceContext(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами для установки контекста сервиса
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.setServiceContext,
                "Параметры функции установки контекста сервиса"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let setServiceContextData = _.cloneDeep(prms);
                    setServiceContextData.connection = this.connection;
                    //И выполним установку контекста сервиса
                    await this.connector.setServiceContext(setServiceContextData);
                    //Успешно - возвращаем ничего
                    return;
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
    //Очистить контекст сервиса
    async clearServiceContext(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами для очистки контекста сервиса
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.clearServiceContext,
                "Параметры функции очистки контекста сервиса"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let clearServiceContextData = _.cloneDeep(prms);
                    clearServiceContextData.connection = this.connection;
                    //И выполним очистку контекста сервиса
                    await this.connector.clearServiceContext(clearServiceContextData);
                    //Успешно - возвращаем ничего
                    return;
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
    //Проверить аутентифицированность сервиса
    async isServiceAuth(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами для проверки аутентифицированности сервиса
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.isServiceAuth,
                "Параметры функции проверки аутентифицированности сервиса"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let isServiceAuthData = _.cloneDeep(prms);
                    isServiceAuthData.connection = this.connection;
                    //И выполним проверку атентифицированности сервиса
                    let res = await this.connector.isServiceAuth(isServiceAuthData);
                    //Валидируем результат
                    if (![objServiceSchema.NIS_AUTH_NO, objServiceSchema.NIS_AUTH_YES].includes(res))
                        throw new ServerError(
                            SERR_OBJECT_BAD_INTERFACE,
                            "Неожиданный ответ функции проверки аутентифицированности сервиса"
                        );
                    //Успешно - возвращаем то, что вернула функция проверки
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
    //Поставить в очередь задание на аутентификацию сервиса
    async putServiceAuthInQueue(prms) {
        //Работаем только при наличии подключения
        if (this.bConnected) {
            //Проверяем структуру переданного объекта с параметрами постановки в очередь задания на аутентификацию сервиса
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.putServiceAuthInQueue,
                "Параметры функции постановки в очередь задания на аутентификацию сервиса"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                try {
                    //Подготовим параметры для передачи в БД
                    let putServiceAuthInQueueData = _.cloneDeep(prms);
                    putServiceAuthInQueueData.connection = this.connection;
                    //И выполним постановку в очередь задания на аутентификацию сервиса
                    await this.connector.putServiceAuthInQueue(putServiceAuthInQueueData);
                    //Успешно - возвращаем ничего
                    return;
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
    //Считать запись очереди обмена
    async getQueue(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.getQueue,
                "Параметры функции считывания записи очереди обмена"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let getQueueData = _.cloneDeep(prms);
                getQueueData.connection = this.connection;
                try {
                    //Исполняем действие в БД
                    let res = await this.connector.getQueue(getQueueData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(res, objQueueSchema.Queue, "Сообщение очереди обмена");
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём считанную запись
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
    //Добавить запись очереди обмена
    async putQueue(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.putQueue,
                "Параметры функции добавления позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let putQueueData = _.cloneDeep(prms);
                putQueueData.blMsg = prms.blMsg ? prms.blMsg : new Buffer("");
                putQueueData.connection = this.connection;
                //Исполняем действие в БД
                try {
                    let res = await this.connector.putQueue(putQueueData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(res, objQueueSchema.Queue, "Добавленное сообщение очереди обмена");
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём добавленную запись
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
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.setQueueState,
                "Параметры функции установки состояния позиции очереди"
            );
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
    //Считывание данных сообщения из позиции очереди
    async getQueueMsg(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.getQueueMsg,
                "Параметры считывания данных ответа на сообщение позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let getQueueMsgData = _.cloneDeep(prms);
                getQueueMsgData.connection = this.connection;
                //Исполняем действие в БД
                try {
                    let res = await this.connector.getQueueMsg(getQueueMsgData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(res, objQueueSchema.QueueMsg, "Данные сообщения очереди обмена");
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём данные сообщения
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
    //Запись данных сообщения в позицию очереди
    async setQueueMsg(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.setQueueMsg,
                "Параметры функции сохранения данных сообщения позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let setQueueMsgData = _.cloneDeep(prms);
                if (!setQueueMsgData.blMsg) setQueueMsgData.blMsg = new Buffer("");
                setQueueMsgData.connection = this.connection;
                //Исполняем действие в БД
                try {
                    let res = await this.connector.setQueueMsg(setQueueMsgData);
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
    //Считывание ответа на сообщение из позиции очереди
    async getQueueResp(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.getQueueResp,
                "Параметры считывания данных ответа на сообщение позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let getQueueRespData = _.cloneDeep(prms);
                getQueueRespData.connection = this.connection;
                //Исполняем действие в БД
                try {
                    let res = await this.connector.getQueueResp(getQueueRespData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(
                        res,
                        objQueueSchema.QueueResp,
                        "Данные ответа сообщения очереди обмена"
                    );
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём данные ответа на сообщение
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
    //Запись ответа на сообщение в позицию очереди
    async setQueueResp(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.setQueueResp,
                "Параметры функции сохранения данных ответа на сообщение позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Подготовим параметры
                let setQueueRespData = _.cloneDeep(prms);
                if (!setQueueRespData.blResp) setQueueRespData.blResp = new Buffer("");
                setQueueRespData.connection = this.connection;
                //Исполняем действие в БД
                try {
                    let res = await this.connector.setQueueResp(setQueueRespData);
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
    //Установить результат обработки записи сервером приложений
    async setQueueAppSrvResult(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.setQueueAppSrvResult,
                "Параметры функции установки результата обработки позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Исполняем действие в БД
                let res = await this.setQueueMsg(prms);
                res = await this.setQueueResp(prms);
                //Вернём измененную запись
                return res;
            } else {
                throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
            }
        } else {
            throw new ServerError(SERR_DB_EXECUTE, "Нет подключения к БД");
        }
    }
    //Исполнить обработчик со стороны БД
    async execQueueDBPrc(prms) {
        if (this.bConnected) {
            //Проверяем структуру переданных параметров
            let sCheckResult = validateObject(
                prms,
                prmsDBConnectorSchema.execQueueDBPrc,
                "Параметры функции исполнения обработчика со стороны БД для позиции очереди"
            );
            //Если структура объекта в норме
            if (!sCheckResult) {
                //Исполняем действие в БД
                try {
                    //Подготовим параметры для передачи в БД
                    let execQueuePrcData = _.cloneDeep(prms);
                    execQueuePrcData.connection = this.connection;
                    //И выполним обработчик со стороны БД
                    let res = await this.connector.execQueuePrc(execQueuePrcData);
                    //Валидируем полученный ответ
                    sCheckResult = validateObject(
                        res,
                        objQueueSchema.QueuePrcResult,
                        "Результат обработки очереди обмена"
                    );
                    if (sCheckResult) throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
                    //Вернём результат обработки
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
