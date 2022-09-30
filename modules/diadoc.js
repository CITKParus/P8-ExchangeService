/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ЭДО "ДИАДОК" (DIADOC)
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const xml2js = require("xml2js"); //Конвертация XML в JSON и JSON в XML
const _ = require("lodash"); //Работа с коллекциями и объектами
const rqp = require("request-promise"); //Работа с HTTP/HTTPS запросами
const Ddauth_Api_Client_Id = "citk-5d8e1345-3f33-496b-a878-9309011dd6c9"; //Ключ разработчика

//---------------------
// Глобальные константы
//---------------------

// Список тегов которые должны содержать массив
const tag = [
    "DocumentAttachments",
    "Signatures",
    "CorrectionRequests",
    "Receipts",
    "Resolutions",
    "XmlSignatureRejections",
    "RecipientTitles",
    "Requests"
];

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

//Конвертация в XML
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
    const loginAtribute = "login";
    const passAtribute = "password";
    //Сформируем запрос на аутентификацию
    return {
        options: {
            qs: {
                type: "password"
            },
            headers: {
                "content-type": "application/json;charset=utf-8",
                Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id
            },
            body: JSON.stringify({
                [loginAtribute]: prms.service.sSrvUser,
                [passAtribute]: prms.service.sSrvPass
            }),
            simple: false
        }
    };
};

//Обработчик "После" подключения к сервису
const afterConnect = async prms => {
    //Если пришла ошибка
    if (prms.optionsResp.statusCode != 200) {
        throw new Error(prms.queue.blRes.toString());
    } else {
        //Сохраним полученный токен доступа в контекст сервиса
        return {
            blResp: Buffer.from(prms.queue.blResp),
            sCtx: prms.queue.blResp.toString(),
            dCtxExp: addHours(new Date(), 23)
        };
    }
};

//Обработчик "До" отправки запроса на экспорт документа к сервису "ДИАДОК"
const beforeMessagePost = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Конвертируем XML из "Парус 8" в JSON
        let obj = await toJSON(prms.queue.blMsg.toString());
        //Формируем запрос для получения FromBoxId
        let rqpoptions = {
            uri: "https://diadoc-api.kontur.ru/GetMyOrganizations",
            headers: {
                "Content-type": "application/json; charset=utf-8",
                Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                Accept: "application/json; charset=utf-8"
            },
            json: true
        };
        //Выполним запрос
        let serverResp = await rqp(rqpoptions);
        //Не удалось получить ящик отправителя
        if (!serverResp.Organizations[0].Boxes[0].BoxId) {
            throw new Error("Не удалось получить ящик отправителя");
        }
        //Сохраняем полученный ответ
        obj.FromBoxId = serverResp.Organizations[0].Boxes[0].BoxId;
        //Формируем запрос для получения ToBoxId
        rqpoptions = {
            uri: "https://diadoc-api.kontur.ru/GetOrganizationsByInnKpp",
            qs: {
                inn: prms.options.inn,
                kpp: prms.options.kpp
            },
            headers: {
                "Content-type": "application/json; charset=utf-8",
                Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                Accept: "application/json; charset=utf-8"
            },
            json: true
        };
        //Выполним запрос
        serverResp = await rqp(rqpoptions);
        //Не удалось получить ящик получателя
        if (!serverResp.Organizations[0].Boxes[0].BoxId) {
            throw new Error("Не удалось получить ящик получателя");
        }
        //Сохраняем полученный ответ
        obj.ToBoxId = serverResp.Organizations[0].Boxes[0].BoxId;
        //Если пришел ответ
        if (prms.queue.blResp && serverResp.statusCode == 200) {
            //Вернем загруженный документ
            return {
                blResp: prms.queue.blResp
            };
        }
        //Собираем и отдаём общий результат работы
        return {
            options: {
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                    Accept: "application/json; charset=utf-8"
                },
                simple: false
            },
            blMsg: Buffer.from(JSON.stringify(obj))
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" запроса на экспорт документа к сервису "ДИАДОК"
const afterMessagePost = async prms => {
    //Преобразуем JSON ответ сервиса "ДИАДОК" в XML, понятный "Парус 8"
    let resu = null;
    //Действие выполнено успешно
    if (prms.optionsResp.statusCode == 200) {
        try {
            resu = toXML(JSON.parse(prms.queue.blResp.toString()));
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера ЭДО "ДИАДОК". Ошибка интерпретации: ${e.message}`);
        }
    } else {
        //Если пришел текст ошибки
        if (prms.queue.blResp) {
            throw new Error(`Неожиданный ответ сервера ЭДО "ДИАДОК": ${prms.queue.blResp.toString()}`);
        } else {
            throw new Error('Сервер ЭДО "ДИАДОК" не вернул ответ');
        }
    }
    //Возврат результата
    return {
        blResp: Buffer.from(resu)
    };
};

//Обработчик "До" отправки запроса на экспорт патча документа к сервису "ДИАДОК"
const beforeMessagePatchPost = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Конвертируем XML из "Парус 8" в понятный "ДИАДОК" JSON
        let obj = await toJSON(prms.queue.blMsg.toString());
        //Собираем и отдаём общий результат работы
        return {
            options: {
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                    Accept: "application/json; charset=utf-8"
                },
                simple: false
            },
            blMsg: Buffer.from(JSON.stringify(obj))
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" запроса на экспорт патча документа к сервису "ДИАДОК"
const afterMessagePatchPost = async prms => {
    //Преобразуем JSON ответ сервиса "ДИАДОК" в XML, понятный "Парус 8"
    let resu = null;
    //Действие выполнено успешно
    if (prms.optionsResp.statusCode == 200) {
        try {
            resu = toXML(JSON.parse(prms.queue.blResp.toString()));
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера ЭДО "ДИАДОК". Ошибка интерпретации: ${e.message}`);
        }
    } else {
        //Если пришел текст ошибки
        if (prms.queue.blResp) {
            throw new Error(`Неожиданный ответ сервера ЭДО "ДИАДОК": ${prms.queue.blResp.toString()}`);
        } else {
            throw new Error('Сервер ЭДО "ДИАДОК" не вернул ответ');
        }
    }
    //Возврат результата
    return {
        blResp: Buffer.from(resu)
    };
};

//Обработчик "До" отправки запроса на получение новых событий к сервису "ДИАДОК"
const beforeEvent = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Формируем запрос для получения BoxId
        let rqpoptions = {
            uri: "https://diadoc-api.kontur.ru/GetMyOrganizations",
            headers: {
                "Content-type": "application/json; charset=utf-8",
                Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                Accept: "application/json; charset=utf-8"
            },
            json: true
        };
        //Выполним запрос
        let serverResp = await rqp(rqpoptions);
        //Не удалось получить текущий ящик организации
        if (!serverResp.Organizations[0].Boxes[0].BoxId) {
            throw new Error("Не удалось получить ящик текущей организации");
        }
        let surl = prms.options.url;
        let obj;
        let rblMsg;
        surl = surl + "?" + "boxId=" + serverResp.Organizations[0].Boxes[0].BoxId;
        //Если действие не "Документооборот"
        if (prms.options.saction != "DOCFLOWS") {
            if (prms.options.aftereventid) {
                surl = surl + "&" + "afterEventId=" + prms.options.aftereventid;
            } else {
                surl = surl + "&" + "timestampFromTicks=" + prms.options.timestampfromticks;
            }
        } else {
            if (prms.queue.blMsg) {
                //Конвертируем XML из "Парус 8" в понятный "ДИАДОК" JSON
                obj = await toJSON(prms.queue.blMsg.toString());
                rblMsg = Buffer.from(JSON.stringify(obj));
            }
        }
        //Собираем и отдаём общий результат работы
        return {
            options: {
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                    Accept: "application/json; charset=utf-8"
                },
                simple: false,
                url: surl,
                boxId: serverResp.Organizations[0].Boxes[0].BoxId
            },
            blMsg: rblMsg
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" запроса на получение новых событий к сервису "ДИАДОК"
const afterEvent = async prms => {
    //Преобразуем JSON ответ сервиса "ДИАДОК" в XML, понятный "Парус 8"
    let resu = null;
    if (prms.queue.blResp) {
        try {
            resu = toXML({ root: JSON.parse(prms.queue.blResp.toString()) });
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера ЭДО "ДИАДОК". Ошибка интерпретации: ${e.message}`);
        }
    } else {
        throw new Error('Сервер ЭДО "ДИАДОК" не вернул ответ');
    }
    //Возврат результата
    return {
        blResp: Buffer.from(resu)
    };
};

//Обработчик "До" отправки запроса на загрузку вложения
const beforeDocLoad = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        let surl = prms.options.url;
        let entId;
        let msgId = "messageId=";
        //В зависимости от режима загрузки определим наименование узла
        switch (prms.options.type) {
            //Загрузка файла
            case 0:
                entId = "entityId=";
                break;
            //Загрузка PDF
            case 1:
                entId = "documentId=";
                break;
            //Загрузка Извещения о получении
            case 2:
                entId = "attachmentId=";
                break;
            //Загрузка Уведомления об уточнении
            case 3:
                entId = "attachmentId=";
                break;
            //Загрузка Титул отказа от подписи документа
            case 4:
                entId = "attachmentId=";
                break;
            //Загрузка Титула покупателя документа
            case 5:
                entId = "documentId=";
                msgId = "letterId=";
                break;
            default:
        }
        surl = surl + "?" + msgId + prms.options.smsgid;
        surl = surl + "&" + entId + prms.options.sentid;
        let obj;
        let rblMsg;
        if (prms.queue.blMsg && prms.options.type != 5) {
            //Конвертируем XML из "Парус 8" в понятный "ДИАДОК" JSON
            obj = await toJSON(prms.queue.blMsg.toString());
            rblMsg = Buffer.from(JSON.stringify(obj));
        } else {
            if (prms.queue.blMsg) {
                rblMsg = prms.queue.blMsg;
            }
        }
        //Собираем и отдаём общий результат работы
        return {
            options: {
                qs: {
                    boxId: prms.options.sboxid,
                    documentTypeNamedId: prms.options.documentTypeNamedId,
                    documentFunction: prms.options.documentFunction,
                    documentVersion: prms.options.documentVersion,
                    titleIndex: prms.options.titleIndex
                },
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                    Accept: "application/json; charset=utf-8"
                },
                url: surl,
                simple: false
            },
            blMsg: rblMsg
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" отправки запроса на загрузку вложения
const afterDocLoad = async prms => {
    if (prms.queue.blResp) {
        //Если выполнено без ошибок и не требуется повторный запрос
        if ((prms.optionsResp.statusCode == 200 || prms.optionsResp.statusCode == 404) && !prms.optionsResp.headers["retry-after"]) {
            return;
        } else {
            let iterable = [1, 2, 3, 4, 5];
            let serverResp;
            //Если не превышает лимита запросов
            for (let value of iterable) {
                if (prms.optionsResp.statusCode != 200 || prms.optionsResp.headers["retry-after"]) {
                    //Если загружаем PDF
                    if (prms.options.type == 1 && prms.optionsResp.headers["retry-after"]) {
                        await new Promise(resolve => setTimeout(resolve, (Number(prms.optionsResp.headers["retry-after"]) + 1) * 1000));
                    } else {
                        await new Promise(resolve => setTimeout(resolve, 2000));
                    }
                    //Выполним повторный запрос
                    serverResp = await rqp(prms.options);
                    //Сохраняем полученный ответ
                    prms.queue.blResp = Buffer.from(serverResp.body || "");
                    prms.optionsResp.statusCode = serverResp.statusCode;
                    prms.optionsResp.headers = serverResp.headers;
                    //Если пришел ответ
                    if (prms.queue.blResp && serverResp.statusCode == 200) {
                        //Вернем загруженный документ
                        return {
                            optionsResp: prms.optionsResp,
                            blResp: prms.queue.blResp
                        };
                    }
                }
            }
            //Если был ответ от сервера с ошибкой (иначе мы сюда не попадём)
            if (prms.queue.blResp) {
                //Разберем сообщение об ошибке
                throw new Error(`Неожиданный ответ сервера ЭДО "ДИАДОК": ${prms.queue.blResp.toString()}`);
            }
        }
    } else {
        throw new Error('Сервер ЭДО "ДИАДОК" не вернул ответ');
    }
    //Возврат результата
    return;
};

//Обработчик "До" отправки запроса на удаление документа к сервису "ДИАДОК"
const beforeDocDelete = async prms => {
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
                    Authorization: "DiadocAuth ddauth_api_client_id=" + Ddauth_Api_Client_Id + ",ddauth_token=" + sToken,
                    Accept: "application/json; charset=utf-8"
                },
                simple: false
            }
        };
    } catch (e) {
        throw Error(e);
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeConnect = beforeConnect;
exports.afterConnect = afterConnect;
exports.beforeMessagePost = beforeMessagePost;
exports.afterMessagePost = afterMessagePost;
exports.beforeMessagePatchPost = beforeMessagePatchPost;
exports.afterMessagePatchPost = afterMessagePatchPost;
exports.beforeEvent = beforeEvent;
exports.afterEvent = afterEvent;
exports.beforeDocLoad = beforeDocLoad;
exports.afterDocLoad = afterDocLoad;
exports.beforeDocDelete = beforeDocDelete;
