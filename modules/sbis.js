/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ЭДО "СБИС" (SBIS)
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const xml2js = require("xml2js"); //Конвертация XML в JSON и JSON в XML
const _ = require("lodash"); //Работа с коллекциями и объектами
const rqp = require("request-promise"); //Работа с HTTP/HTTPS запросами

//---------------------
// Глобальные константы
//---------------------

// Список тегов которые должны содержать массив
const tag = ["Вложение", "Редакция", "ДокументОснование", "ДокументСледствие", "Подпись", "Событие", "Этап", "Действие", "Сертификат"];

//------------
// Тело модуля
//------------

//Обернуть содержимое тега в массив
const toArray = (obj, tags) => {
    for (const prop in obj) {
        const value = obj[prop];
        if (tags.indexOf(prop) != -1 && !_.isArray(obj[prop])) {
            obj[prop] = JSON.parse("[" + JSON.stringify(value) + "]");
        }
        if (typeof value === "object") {
            toArray(value, tag);
        }
    }
    return obj;
};

//Конвертация в XML
const toXML = obj => {
    const builder = new xml2js.Builder();
    return builder.buildObject(obj);
};

//Конвертация в JSON
const parseXML = xmlDoc => {
    return new Promise((resolve, reject) => {
        xml2js.parseString(xmlDoc, { explicitArray: false, mergeAttrs: true }, (err, result) => {
            if (err) reject(err);
            else resolve(result);
        });
    });
};

//Конвертация в JSON
const toJSON = async obj => {
    let result = await parseXML(obj);
    result = result.root;
    toArray(result, tag);
    return result;
};

//Добавление определённого количетсва часов к дате
const addHours = (dDate, nHours) => {
    dDate.setTime(dDate.getTime() + nHours * 60 * 60 * 1000);
    return new Date(dDate);
};

//Обработчик "До" подключения к сервису
const beforeConnect = async prms => {
    //Подготовим параметры аутентификации
    const prmAtribute = "Параметр";
    const loginAtribute = "Логин";
    const passAtribute = "Пароль";
    //Сформируем запрос на аутентификацию
    return {
        options: {
            headers: {
                "content-type": "application/json;charset=utf-8"
            },
            body: JSON.stringify({
                jsonrpc: "2.0",
                method: "СБИС.Аутентифицировать",
                params: {
                    [prmAtribute]: {
                        [loginAtribute]: prms.service.sSrvUser,
                        [passAtribute]: prms.service.sSrvPass
                    }
                },
                id: 0
            }),
            simple: false
        }
    };
};

//Обработчик "После" подключения к сервису
const afterConnect = async prms => {
    let resp = null;
    //Разберем ответ
    if (prms.queue.blResp) {
        try {
            resp = JSON.parse(prms.queue.blResp.toString());
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера ЭДО "СБИС". Ошибка интерпретации: ${e.message}`);
        }
    } else {
        throw new Error('Сервер ЭДО "СБИС" не вернул ответ');
    }
    //Если в нём нет ошибок
    if (!resp.error) {
        //Сохраним полученный токен доступа в контекст сервиса
        return {
            blResp: Buffer.from(resp.result),
            sCtx: resp.result,
            dCtxExp: addHours(new Date(), 23)
        };
    } else {
        throw new Error(`Сервер ЭДО "СБИС" вернул ошибку: ${resp.error.message ? resp.error.message : "Неожиданная ошибка"}`);
    }
};

//Обработчик "До" отправки запроса к сервису "СБИС"
const beforeDocParse = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Конвертируем XML из "Парус 8" в понятный "СБИСу" JSON
        let obj = await toJSON(prms.queue.blMsg.toString());
        //Собираем и отдаём общий результат работы
        return {
            options: {
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    "X-SBISSessionID": sToken,
                    srv: 1
                },
                simple: false,
                func: obj.method
            },
            blMsg: Buffer.from(JSON.stringify(obj))
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" запроса к сервису "СБИС"
const afterDocParse = async prms => {
    //Преобразуем JSON ответ сервиса "СБИС" в XML, понятный "Парус 8"
    let resu = null;
    if (prms.queue.blResp) {
        try {
            resu = toXML(JSON.parse(prms.queue.blResp.toString()));
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера ЭДО "СБИС". Ошибка интерпретации: ${e.message}`);
        }
    } else {
        throw new Error('Сервер ЭДО "СБИС" не вернул ответ');
    }
    //Возврат результата
    return {
        blResp: Buffer.from(resu)
    };
};

//Обработчик "До" отправки запроса на загрузку вложения
const beforeAttParse = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Собираем и отдаём общий результат работы
        return {
            options: {
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    "X-SBISSessionID": sToken,
                    srv: 1
                },
                simple: false
            }
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" отправки запроса на загрузку вложения
const afterAttParse = async prms => {
    if (prms.queue.blResp) {
        if (prms.optionsResp.statusCode == 200) {
            return;
        } else {
            let iterable = [1, 2, 3, 4, 5];
            //Если не превышает лимита запросов
            for (let value of iterable) {
                if (prms.optionsResp.statusCode != 200) {
                    //Выполним повторный запрос
                    await new Promise(resolve => setTimeout(resolve, 2000));
                    let serverResp = await rqp(prms.options);
                    //Сохраняем полученный ответ
                    prms.queue.blResp = Buffer.from(serverResp.body || "");
                    prms.optionsResp.statusCode = serverResp.statusCode;
                    //Если пришел ответ
                    if (prms.queue.blResp && serverResp.statusCode == 200) {
                        //Вернем загруженный документ
                        return {
                            blResp: prms.queue.blResp
                        };
                    }
                }
            }
            //Если был ответ от сервера с ошибкой (иначе мы сюда не попадём)
            if (prms.queue.blResp) {
                //Разберем сообщение об ошибке
                let resu = null;
                try {
                    resu = JSON.parse(prms.queue.blResp.toString());
                } catch (e) {
                    throw new Error(`Неожиданный ответ сервера ЭДО "СБИС": ${prms.queue.blResp.toString()}`);
                }
                throw new Error(`Сервер ЭДО "СБИС" вернул ошибку: ${resu?.error?.message}`);
            } else {
                //Возврат результата
                throw new Error('Сервер ЭДО "СБИС" не вернул ответ');
            }
        }
    } else {
        throw new Error('Сервер ЭДО "СБИС" не вернул ответ');
    }
    //Возврат результата
    return;
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeConnect = beforeConnect;
exports.afterConnect = afterConnect;
exports.beforeDocParse = beforeDocParse;
exports.afterDocParse = afterDocParse;
exports.beforeAttParse = beforeAttParse;
exports.afterAttParse = afterAttParse;
