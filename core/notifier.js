/*
  Сервис интеграции ПП Парус 8 с WEB API    
  Модуль ядра: модуль рассылки уведомлений
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const _ = require("lodash"); //Работа с массивами и коллекциями
const EventEmitter = require("events"); //Обработчик пользовательских событий
const { ServerError } = require("./server_errors"); //Типовая ошибка
const { SERR_OBJECT_BAD_INTERFACE, SERR_MAIL_FAILED } = require("./constants"); //Общесистемные константы
const { makeErrorText, validateObject, sendMail } = require("./utils"); //Вспомогательные функции
const prmsNotifierSchema = require("../models/prms_notifier"); //Схемы валидации параметров функций класса

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Типовые события
const SEVT_NOTIFIER_STARTED = "NOTIFIER_STARTED"; //Модуль рассылки уведомлений запущен
const SEVT_NOTIFIER_STOPPED = "NOTIFIER_STOPPED"; //Модуль рассылки уведомлений остановлен

//Время отложенного старта цикла отправки сообщений (мс)
const NSEND_LOOP_DELAY = 3000;

//Интервал проверки очереди отправки сообщений (мс)
const NSEND_LOOP_INTERVAL = 3000;

//------------
// Тело модуля
//------------

//Класс рассылки уведомлений
class Notifier extends EventEmitter {
    //Конструктор класса
    constructor(prms) {
        //Создадим экземпляр родительского класса
        super();
        //Проверяем структуру переданного набора параметров для конструктора
        let sCheckResult = validateObject(prms, prmsNotifierSchema.Notifier, "Параметры конструктора класса Notifier");
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Очередь отправляемых уведомлений
            this.messages = [];
            //Признак функционирования модуля
            this.bWorking = false;
            //Признак необходимости оповещения об останове
            this.bNotifyStopped = false;
            //Флаг работы цикла проверки
            this.bInSendLoop = false;
            //Идентификатор таймера проверки очереди отправки уведомлений
            this.nSendLoopTimeOut = null;
            //Запомним параметры отправки E-Mail
            this.mail = prms.mail;
            //Запомним логгер
            this.logger = prms.logger;
            //Привяжем методы к указателю на себя для использования в обработчиках событий
            this.notifySendLoop = this.notifySendLoop.bind(this);
        } else {
            throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
        }
    }
    //Добавление уведомления в очередь отправки
    async addMessage(prms) {
        //Проверяем структуру переданного объекта для старта
        let sCheckResult = validateObject(
            prms,
            prmsNotifierSchema.addMessage,
            "Параметры функции добавления уведомления в очередь отправки"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            let tmp = _.cloneDeep(prms);
            tmp.bSent = false;
            this.messages.push(tmp);
        } else {
            await this.logger.error(
                `Ошибка добавления уведомления в очередь: ${makeErrorText(
                    new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult)
                )}`
            );
        }
    }
    //Уведомление о запуске модуля
    notifyStarted() {
        //Оповестим подписчиков о запуске
        this.emit(SEVT_NOTIFIER_STARTED);
    }
    //Уведомление об остановке модуля
    notifyStopped() {
        //Оповестим подписчиков об останове
        this.emit(SEVT_NOTIFIER_STOPPED);
    }
    //Перезапуск отправки очереди уведомлений
    restartSendLoop() {
        //Включаем опрос очереди уведомлений только если установлен флаг работы
        if (this.bWorking) {
            this.nSendLoopTimeOut = setTimeout(this.notifySendLoop, NSEND_LOOP_INTERVAL);
        } else {
            //Если мы не работаем и просили оповестить об останове (видимо была команда на останов) - сделаем это
            if (this.bNotifyStopped) this.notifyStopped();
        }
    }
    //Отправка уведомлений из очереди
    async notifySendLoop() {
        //Выставим флаг - цикл опроса активен
        this.bInSendLoop = true;
        //Обходим уведомления для отправки
        for (let message of this.messages) {
            //Работаем только по неотправленным уведомлениям
            if (!message.bSent) {
                try {
                    //Если всё в порядке с настройками
                    if (this.mail.sHost && this.mail.nPort && this.mail.sUser && this.mail.sPass && this.mail.sFrom) {
                        //Отправляем
                        await sendMail({
                            mail: this.mail,
                            sTo: message.sTo,
                            sSubject: message.sSubject,
                            sMessage: message.sMessage
                        });
                        //Говорим, что отправлено
                        message.bSent = true;
                        //Протоколируем отправку
                        await this.logger.info(`Сообщение с темой "${message.sSubject}" отпрвлено ${message.sTo}`);
                    } else {
                        //Пометим, что сообщение отправлено (да, это не так, но эта ошибка не решается повторной отправкой, а если не пометить - попытки отправки будут вечными)
                        message.bSent = true;
                        //Показываем ошибку
                        throw new ServerError(
                            SERR_MAIL_FAILED,
                            'Не указаны параметры подключения к SMTP-сервереру (проверьте секцию "mail" в файле конфигурации)'
                        );
                    }
                } catch (e) {
                    await this.logger.error(
                        `Ошибка отправки сообщения с темой "${message.sSubject}" для ${message.sTo}: ${makeErrorText(
                            e
                        )}`
                    );
                }
            }
        }
        //Подчищаем очередь - удалим уже отправленные
        _.remove(this.messages, { bSent: true });
        //Выставим флаг - цикл опроса неактивен
        this.bInSendLoop = false;
        //Перезапускаем опрос
        this.restartSendLoop();
    }
    //Запуск модуля
    startNotifier() {
        //Выставляем флаг работы
        this.bWorking = true;
        //Выставляем флаг необходимости оповещения об останове
        this.bNotifyStopped = false;
        //Выставляем флаг неактивности (пока) цикла опроса
        this.bInSendLoop = false;
        //Начинаем слушать очередь исходящих
        setTimeout(this.notifySendLoop, NSEND_LOOP_DELAY);
        //И оповещаем всех что запустились
        this.notifyStarted();
    }
    //Остановка модуля
    stopNotifier() {
        //Выставляем флаг неработы
        this.bWorking = false;
        //Если сейчас мы не в цикле проверки
        if (!this.bInSendLoop) {
            //Сбросим его таймер, чтобы он не запустился снова
            if (this.nSendLoopTimeOut) {
                clearTimeout(this.nSendLoopTimeOut);
                this.nSendLoopTimeOut = null;
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

exports.SEVT_NOTIFIER_STARTED = SEVT_NOTIFIER_STARTED;
exports.SEVT_NOTIFIER_STOPPED = SEVT_NOTIFIER_STOPPED;
exports.Notifier = Notifier;
