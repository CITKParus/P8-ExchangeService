/*
  Сервис интеграции ПП Парус 8 с WEB API
  Модуль ядра: вспомогательные функции
*/

//----------------------
// Подключение библиотек
//----------------------

const _ = require("lodash"); //Работа с массивами и объектами
const os = require("os"); //Средства операционной системы
const xml2js = require("xml2js"); //Конвертация XML в JSON
const Schema = require("validate"); //Схемы валидации
const nodemailer = require("nodemailer"); //Отправка E-Mail сообщений
const {
    SERR_UNEXPECTED,
    SMODULES_PATH_MODULES,
    SERR_OBJECT_BAD_INTERFACE,
    SERR_MODULES_NO_MODULE_SPECIFIED,
    SERR_MODULES_BAD_INTERFACE,
    SERR_MAIL_FAILED
} = require("./constants"); //Глобавльные константы системы
const { ServerError } = require("./server_errors"); //Ошибка сервера
const prmsUtilsSchema = require("../models/prms_utils"); //Схемы валидации параметров функций

//------------
// Тело модуля
//------------

//Валидация объекта
const validateObject = (obj, schema, sObjName) => {
    //Объявим результат
    let sRes = "";
    //Если пришла верная схема
    if (schema instanceof Schema) {
        //И есть что проверять
        if (obj) {
            //Сделаем это
            const objTmp = _.cloneDeep(obj);
            const errors = schema.validate(objTmp, { strip: false });
            //Если есть ошибки
            if (errors && Array.isArray(errors)) {
                if (errors.length > 0) {
                    //Сформируем из них сообщение об ошибке валидации
                    let a = errors.map(e => {
                        return e.message;
                    });
                    sRes = `Объект${sObjName ? ` "${sObjName}" ` : " "}имеет некорректный формат: ${_.uniq(a).join(
                        "; "
                    )}`;
                }
            } else {
                //Валидатор вернул не то, что мы ожидали
                sRes = "Неожиданный ответ валидатора";
            }
        } else {
            //Нам не передали объект на проверку
            sRes = `Объект${sObjName ? ` "${sObjName}" ` : " "}не указан`;
        }
    } else {
        //Пришла не схема валидации а непонятно что
        sRes = "Ошибочный формат схемы валидации";
    }
    //Вернем результат
    return sRes;
};

//Формирование полного пути к подключаемому модулю
const makeModuleFullPath = sModuleName => {
    //Если имя модуля передано
    if (sModuleName) {
        //Объединим его с шаблоном пути до библиотеки модулей
        return `${SMODULES_PATH_MODULES}/${sModuleName}`;
    } else {
        //Нет имени модуля - нет полного пути
        return "";
    }
};

//Формирование текста ошибки
const makeErrorText = e => {
    //Сообщение об ошибке по умолчанию
    let sErr = `${SERR_UNEXPECTED}: ${e.message}`;
    //Если это простая строка
    if (e instanceof String || typeof e === "string") sErr = `${SERR_UNEXPECTED}: ${e}`;
    //Если это наше внутреннее сообщение, с кодом, то сделаем ошибку более информативной
    if (e instanceof ServerError) sErr = `${e.sCode}: ${e.sMessage}`;
    //Вернем ответ
    return sErr;
};

//Считывание наименования модуля-обработчика сервера приложений (ожидаемый формат - <МОДУЛЬ>.js/<ФУНКЦИЯ>)
const getAppSrvModuleName = sAppSrv => {
    //Если есть что разбирать
    if (sAppSrv) {
        //И если это строка
        if (sAppSrv instanceof String || typeof sAppSrv === "string") {
            //Проверим наличие разделителя между именем модуля и функции
            if (sAppSrv.indexOf("/") === -1) {
                //Нет разделителя - нечего вернуть
                return null;
            } else {
                //Вернём всё, что левее разделителя
                return sAppSrv.substring(0, sAppSrv.indexOf("/"));
            }
        } else {
            //Пришла не строка
            return null;
        }
    } else {
        //Ничего не пришло
        return null;
    }
};

//Считывание наименования функции модуля-обработчика сервера приложений (ожидаемый формат - <МОДУЛЬ>.js/<ФУНКЦИЯ>)
const getAppSrvFunctionName = sAppSrv => {
    //Если есть что разбирать
    if (sAppSrv) {
        //И если это строка
        if (sAppSrv instanceof String || typeof sAppSrv === "string") {
            //Проверим наличие разделителя между именем модуля и функции
            if (sAppSrv.indexOf("/") === -1) {
                //Нет разделителя - нечего вернуть
                return null;
            } else {
                //Вернём всё, что правее разделителя
                return sAppSrv.substring(sAppSrv.indexOf("/") + 1, sAppSrv.length);
            }
        } else {
            //Пришла не строка
            return null;
        }
    } else {
        //Ничего не пришло
        return null;
    }
};

//Получение функции обработчика
const getAppSrvFunction = sAppSrv => {
    //Объявим формат (для сообщений об ошибках)
    const sFormat = "(ожидаемый формат: <МОДУЛЬ>/<ФУНКЦИЯ>)";
    //Проверим, что есть что разбирать
    if (!sAppSrv)
        throw new ServerError(SERR_MODULES_NO_MODULE_SPECIFIED, `Не указаны модуль и функция обработчика ${sFormat}`);
    //Разбираем
    try {
        //Разбираем на модуль и функцию
        let moduleName = getAppSrvModuleName(sAppSrv);
        let funcName = getAppSrvFunctionName(sAppSrv);
        //Проверим, что есть и то и другое
        if (!moduleName) throw Error(`Обработчик ${sAppSrv} не указывает на модуль ${sFormat}`);
        if (!funcName) throw Error(`Обработчик ${sAppSrv} не указывает на функцию ${sFormat}`);
        //Подключаем модуль
        let mdl = null;
        try {
            mdl = require(makeModuleFullPath(moduleName));
        } catch (e) {
            throw Error(
                `Не удалось подключить модуль ${moduleName}, проверье что он существует и не имеет синтаксических ошибок. Ошибка подключения: ${e.message}`
            );
        }
        //Проверяем, что в нём есть эта функция
        if (!mdl[funcName]) throw Error(`Функция ${funcName} не определена в модуле ${moduleName}`);
        //Проверяем, что функция асинхронна и если это так - возвращаем её
        if ({}.toString.call(mdl[funcName]) === "[object AsyncFunction]") return mdl[funcName];
        else throw Error(`Функция ${funcName} модуля ${moduleName} должна быть асинхронной`);
    } catch (e) {
        throw new ServerError(SERR_MODULES_BAD_INTERFACE, e.message);
    }
};

//Отправка E-Mail уведомления
const sendMail = prms => {
    return new Promise((resolve, reject) => {
        //Проверяем структуру переданного объекта для отправки E-Mail уведомления
        let sCheckResult = validateObject(
            prms,
            prmsUtilsSchema.sendMail,
            "Параметры функции отправки E-Mail уведомления"
        );
        //Если структура объекта в норме
        if (!sCheckResult) {
            //Формируем параметры для подключения к SMTP
            let transpOptions = {
                host: prms.mail.sHost,
                port: prms.mail.nPort,
                secure: prms.mail.bSecure,
                tls: {
                    rejectUnauthorized: prms.mail.bRejectUnauthorized
                }
            };
            //Если есть информация о пользователе - добавляем
            if (prms.mail.sUser) {
                transpOptions.auth = {
                    user: prms.mail.sUser,
                    pass: prms.mail.sPass
                }
            }
            //Настраиваем подключение к SMTP-серверу
            let transporter = nodemailer.createTransport(transpOptions);
            //Параметры отправляемого сообщения
            let mailOptions = {
                from: prms.mail.sFrom,
                to: prms.sTo,
                subject: prms.sSubject,
                text: prms.sMessage,
                html: prms.sHTML,
                attachments: prms.attachments
            };
            //Отправляем сообщение
            transporter.sendMail(mailOptions, (error, info) => {
                if (error) {
                    reject(new ServerError(SERR_MAIL_FAILED, `${error.code}: ${error}`));
                } else {
                    if (info.rejected && Array.isArray(info.rejected) && info.rejected.length > 0) {
                        reject(
                            new ServerError(
                                SERR_MAIL_FAILED,
                                `Сообщение не доствлено адресатам: ${info.rejected.join(", ")}`
                            )
                        );
                    } else {
                        resolve(info);
                    }
                }
            });
        } else {
            reject(new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult));
        }
    });
};

//Сборка URL по адресу сервиса и функции сервиса
const buildURL = prms => {
    //Проверяем структуру переданного объекта для сборки URL
    let sCheckResult = validateObject(prms, prmsUtilsSchema.buildURL, "Параметры функции формирования URL");
    //Если структура объекта в норме
    if (!sCheckResult) {
        //Формируем URL с учетом лишних "/"
        return `${prms.sSrvRoot.replace(/\/+$/, '')}/${prms.sFnURL.replace(/^\/+/, '')}${prms.sQuery ? `?${prms.sQuery}` : ""}`;
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
};

//Получение списка IP-адресов хоста сервера
const getIPs = () => {
    let ips = [];
    //получим список сетевых интерфейсов
    const ifaces = os.networkInterfaces();
    //обходим сетевые интерфейсы
    Object.keys(ifaces).forEach(ifname => {
        ifaces[ifname].forEach(iface => {
            //пропускаем локальный адрес и не IPv4 адреса
            if ("IPv4" !== iface.family || iface.internal !== false) return;
            //добавим адрес к резульату
            ips.push(iface.address);
        });
    });
    //вернем ответ
    return ips;
};

//Разбор XML (обёртка для async/await)
const parseXML = prms => {
    return new Promise((resolve, reject) => {
        //Проверяем структуру переданного объекта для парсинша
        let sCheckResult = validateObject(prms, prmsUtilsSchema.parseXML, "Параметры функции разбора XML");
        //Если структура объекта в норме
        if (!sCheckResult) {
            xml2js.parseString(prms.sXML, prms.options, (err, result) => {
                if (err) reject(err);
                else resolve(result);
            });
        } else {
            reject(new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult));
        }
    });
};

//Разбор параметров сообщения/ответа (XML > JSON)
const parseOptionsXML = async prms => {
    //Проверяем структуру переданных параметров
    let sCheckResult = validateObject(
        prms,
        prmsUtilsSchema.parseOptionsXML,
        "Параметры функции разбора XML параметров сообщения/ответа"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        try {
            parseRes = await parseXML({
                sXML: prms.sOptions,
                options: {
                    explicitArray: false,
                    mergeAttrs: true,
                    valueProcessors: [xml2js.processors.parseNumbers, xml2js.processors.parseBooleans]
                }
            });
            return parseRes.root;
        } catch (e) {
            throw new Error("Ошибка рабора XML с параметрами сообщения/ответа: " + e);
        }
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
};

//Сборка параметров сообщения/ответа (JSON > XML)
const buildOptionsXML = prms => {
    //Проверяем структуру переданных параметров
    let sCheckResult = validateObject(
        prms,
        prmsUtilsSchema.buildOptionsXML,
        "Параметры функции сборки XML параметров сообщения/ответа"
    );
    //Если структура объекта в норме
    if (!sCheckResult) {
        try {
            let builder = new xml2js.Builder();
            return builder.buildObject({ root: prms.options });
        } catch (e) {
            throw new Error("Ошибка сборки XML с параметрами сообщения/ответа: " + e);
        }
    } else {
        throw new ServerError(SERR_OBJECT_BAD_INTERFACE, sCheckResult);
    }
};

//Получение текущего времени в строковом формате
const getNowString = () => {
    //Создадим объект даты
    const dNow = new Date();
    //Возьмём его строковое представление
    const sNow = dNow.toLocaleString();
    //Вернем результат
    return sNow;
};

//Глубокое слияние объектов
const deepMerge = (...args) => {
    let res = {};
    for (let i = 0; i < args.length; i++) _.merge(res, args[i]);
    return res;
};

//-----------------
// Интерфейс модуля
//-----------------

exports.validateObject = validateObject;
exports.makeModuleFullPath = makeModuleFullPath;
exports.makeErrorText = makeErrorText;
exports.getAppSrvModuleName = getAppSrvModuleName;
exports.getAppSrvFunctionName = getAppSrvFunctionName;
exports.getAppSrvFunction = getAppSrvFunction;
exports.sendMail = sendMail;
exports.buildURL = buildURL;
exports.getIPs = getIPs;
exports.parseXML = parseXML;
exports.parseOptionsXML = parseOptionsXML;
exports.buildOptionsXML = buildOptionsXML;
exports.getNowString = getNowString;
exports.deepMerge = deepMerge;
