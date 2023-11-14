/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: контроль доступности сервисов
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const _ = require("lodash"); //Работа с массивами и коллекциями
const rqp = require("request-promise"); //Работа с HTTP/HTTPS запросами
const EventEmitter = require("events"); //Обработчик пользовательских событий
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { SERR_SERVICE_UNAVAILABLE, SERR_OBJECT_BAD_INTERFACE } = require("./constants"); //Общесистемные константы
const { makeErrorText, validateObject } = require("./utils"); //Вспомогательные функции
const prmsServiceAvailableControllerSchema = require("../models/prms_service_available_controller"); //Схемы валидации параметров функций класса
const objServiceSchema = require("../models/obj_service"); //Схемы валидации сервисов

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Типовые события
const SEVT_SERVICE_AVAILABLE_CONTROLLER_STARTED = "SERVICE_AVAILABLE_CONTROLLER_STARTED"; //Контроллер доступности сервисов запущен
const SEVT_SERVICE_AVAILABLE_CONTROLLER_STOPPED = "SERVICE_AVAILABLE_CONTROLLER_STOPPED"; //Контроллер доступности сервисов остановлен

//Время отложенного старта цикла контроля (мс)
const NDETECTING_LOOP_DELAY = 3000;

//Интервал проверки доступности сервисов (мс)
const NDETECTING_LOOP_INTERVAL = 60000;

//Таймаут проверки доступности адреса сервиса (мс)
const NNETWORK_CHECK_TIMEOUT = 10000;

//------------
// Тело модуля
//------------

//Класс контроллера доступности сервисов
class ServiceAvailableController extends EventEmitter {
    //Конструктор класса
    constructor(prms) {
        //Создадим экземпляр родительского класса
        super();
        //Проверяем структуру переданного набора параметров для конструктора
        let sCheckResult = validateObject(
            prms,
            prmsServiceAvailableControllerSchema.ServiceAvailableController,
            "Параметры конструктора класса ServiceAvailableController"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Список обслуживаемых сервисов
            this.services = null;
            //Признак функционирования контроллера
            this.bWorking = false;
            //Признак необходимости оповещения об останове
            this.bNotifyStopped = false;
            //Флаг работы цикла проверки
            this.bInDetectingLoop = false;
            //Идентификатор таймера проверки доступности сервисов
            this.nDetectingLoopTimeOut = null;
            //Запомним уведомитель
            this.notifier = prms.notifier;
            //Запомним логгер
            this.logger = prms.logger;
            //Запомним подключение к БД
            this.dbConn = prms.dbConn;
            //Запомним глобальный адрес прокси-сервера
            this.sProxy = prms.sProxy;
            //Привяжем методы к указателю на себя для использования в обработчиках событий
            this.serviceDetectingLoop = this.serviceDetectingLoop.bind(this);
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Уведомление о запуске контроллера
    notifyStarted() {
        //Оповестим подписчиков о запуске
        this.emit(SEVT_SERVICE_AVAILABLE_CONTROLLER_STARTED);
    }
    //Уведомление об остановке контроллера
    notifyStopped() {
        //Оповестим подписчиков об останове
        this.emit(SEVT_SERVICE_AVAILABLE_CONTROLLER_STOPPED);
    }
    //Перезапуск опроса списка сервисов
    async restartDetectingLoop() {
        //Включаем опрос сервисов только если установлен флаг работы
        if (this.bWorking) {
            this.nDetectingLoopTimeOut = await setTimeout(async () => {
                await this.serviceDetectingLoop();
            }, NDETECTING_LOOP_INTERVAL);
        } else {
            //Если мы не работаем и просили оповестить об останове (видимо была команда на останов) - сделаем это
            if (this.bNotifyStopped) this.notifyStopped();
        }
    }
    //Опрос доступности сервисов
    async serviceDetectingLoop() {
        //Если есть сервисы для опроса
        if (this.services && Array.isArray(this.services) && this.services.length > 0) {
            //Выставим флаг - цикл опроса активен
            this.bInDetectingLoop = true;
            try {
                //Обходим список сервисов для проверки
                for (let service of this.services) {
                    //Если сервис надо проверять на доступность и это сервис для отправки исходящих сообщений
                    if (
                        service.nUnavlblNtfSign == objServiceSchema.NUNAVLBL_NTF_SIGN_YES &&
                        service.nSrvType == objServiceSchema.NSRV_TYPE_SEND
                    ) {
                        try {
                            // Инициализируем параметры запроса
                            let options = {};
                            // Устанавливаем параметры запроса
                            options.url = service.sSrvRoot;
                            options.timeout = NNETWORK_CHECK_TIMEOUT;
                            // Если у сервиса указан прокси, либо у приложения установлен глобальный прокси
                            if (service.sProxyURL || this.sProxy) {
                                // Добавляем прокси с приоритетом сервиса
                                options.proxy = service.sProxyURL ?? this.sProxy;
                            }
                            //Отправляем проверочный запрос
                            await rqp(options);
                            //Запрос прошел - фиксируем дату доступности и сбрасываем дату недоступности
                            service.dAvailable = new Date();
                            service.dUnAvailable = null;
                        } catch (e) {
                            //Зафиксируем дату и время недоступности
                            service.dUnAvailable = new Date();
                            //Сформируем текст ошибки в зависимости от того, что случилось
                            let sError = "Неожиданная ошибка удалённого сервиса";
                            if (e.error) {
                                let sSubError = e.error.code || e.error;
                                if (e.error.code === "ESOCKETTIMEDOUT")
                                    sSubError = `сервис не ответил на запрос в течение ${NNETWORK_CHECK_TIMEOUT} мс`;
                                sError = `Ошибка передачи данных: ${sSubError}`;
                            }
                            if (e.response) {
                                //Нам нужны только ошибки сервера
                                if (String(e.response.statusCode).startsWith("5")) {
                                    sError = `Ошибка работы удалённого сервиса: ${e.response.statusCode} - ${e.response.statusMessage}`;
                                } else {
                                    //Остальное - клиентские ошибки, но сервер-то вроде отвечает, поэтому - пропускаем
                                    service.dUnAvailable = null;
                                }
                            }
                            //Фиксируем ошибку проверки в протоколе (только если она действительно была)
                            if (service.dUnAvailable) {
                                await this.logger.warn(
                                    `При проверке доступности сервиса ${service.sCode}: ${makeErrorText(
                                        new ServerError(SERR_SERVICE_UNAVAILABLE, sError)
                                    )} (адрес - ${service.sSrvRoot})`,
                                    { nServiceId: service.nId }
                                );
                            }
                        }
                        //Если есть даты - будем проверять
                        if (service.dUnAvailable && service.dAvailable) {
                            //Выясним как долго он уже недоступен (в минутах)
                            let nDiffMs = service.dUnAvailable - service.dAvailable;
                            let nDiffMins = Math.round(((nDiffMs % 86400000) % 3600000) / 60000);
                            //Если простой больше указанного в настройках - будем оповещать по почте
                            if (nDiffMins >= service.nUnavlblNtfTime) {
                                //Подготовим сообщение для уведомления
                                let sMessage = `Сервис недоступен более ${service.nUnavlblNtfTime} мин. (${nDiffMins} мин. с момента запуска сервера приложений).\nАдрес сервиса: ${service.sSrvRoot}`;
                                //Положим уведомление в протокол работы сервера приложений
                                await this.logger.error(sMessage, { nServiceId: service.nId });
                                //И в очередь уведомлений
                                await this.notifier.addMessage({
                                    sTo: service.sUnavlblNtfMail,
                                    sSubject: `Удалённый сервис ${service.sCode} неотвечает на запросы`,
                                    sMessage
                                });
                            }
                        }
                    }
                    //Если сервис надо проверять на доступность то проверим так же - есть ли у него неотработанные сообщения обмена
                    if (service.nUnavlblNtfSign == objServiceSchema.NUNAVLBL_NTF_SIGN_YES) {
                        try {
                            let res = await this.dbConn.getServiceExpiredQueueInfo({
                                nServiceId: service.nId
                            });
                            //Если у сервиса есть просроченные сообщения - будет отправлять информацию об этом
                            if (res.nCnt > 0) {
                                //Отправляем уведомление
                                await this.notifier.addMessage({
                                    sTo: service.sUnavlblNtfMail,
                                    sSubject: `Для сервиса ${service.sCode} зафиксированы просроченные сообщения обмена (${res.nCnt} ед.)`,
                                    sMessage: res.sInfoList
                                });
                            }
                        } catch (e) {
                            await this.logger.error(
                                `При проверке просроченных сообщений сервиса ${service.sCode}: ${makeErrorText(e)}`,
                                { nServiceId: service.nId }
                            );
                        }
                    }
                }
            } catch (e) {
                //Фиксируем ошибку в протоколе работы сервера приложений
                await this.logger.error(makeErrorText(e));
            }
            //Выставим флаг - цикл опроса неактивен
            this.bInDetectingLoop = false;
            //Перезапускаем опрос
            await this.restartDetectingLoop();
        } else {
            //Выставим флаг - цикл опроса неактивен
            this.bInDetectingLoop = false;
            //Опрашивать нечего - ждём и перезапускаем цикл опроса
            await this.restartDetectingLoop();
        }
    }
    //Запуск контроллера
    startController(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsServiceAvailableControllerSchema.startController,
            "Параметры функции запуска контроллера доступности сервисов"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Выставляем флаг работы
            this.bWorking = true;
            //Выставляем флаг необходимости оповещения об останове
            this.bNotifyStopped = false;
            //Выставляем флаг неактивности (пока) цикла опроса
            this.bInDetectingLoop = false;
            //запоминаем список обслуживаемых сервисов и инициализируем даты доступности и недоступности
            this.services = _.cloneDeep(prms.services);
            this.services.forEach(s => {
                s.dUnAvailable = null;
                s.dAvailable = new Date();
            });
            //Начинаем проверять список сервисов
            setTimeout(this.serviceDetectingLoop, NDETECTING_LOOP_DELAY);
            //И оповещаем всех что запустились
            this.notifyStarted();
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Остановка контроллера
    stopController() {
        //Выставляем флаг неработы
        this.bWorking = false;
        //Если сейчас мы не в цикле проверки
        if (!this.bInDetectingLoop) {
            //Сбросим его таймер, чтобы он не запустился снова
            if (this.nDetectingLoopTimeOut) {
                clearTimeout(this.nDetectingLoopTimeOut);
                this.nDetectingLoopTimeOut = null;
            }
            //Выставляем флаг - не надо оповещать об останове
            this.bNotifyStopped = false;
            //Оповестим об останове
            this.notifyStopped();
        } else {
            //Выставляем флаг необходимости оповещения об останове (это будет сделано автоматически по завершению цикла проверки)
            this.bNotifyStopped = true;
        }
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.SEVT_SERVICE_AVAILABLE_CONTROLLER_STARTED = SEVT_SERVICE_AVAILABLE_CONTROLLER_STARTED;
exports.SEVT_SERVICE_AVAILABLE_CONTROLLER_STOPPED = SEVT_SERVICE_AVAILABLE_CONTROLLER_STOPPED;
exports.ServiceAvailableController = ServiceAvailableController;
