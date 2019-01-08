/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с "АТОЛ-Онлайн" (v4) в формате ФФД 1.05

  Полный формат формируемой посылки:
    reqBody = {
        timestamp: "",
        external_id: 0,
        service: {
            callback_url: ""
        },
        receipt: {
            client: {
                email: "",
                phone: ""
            },
            company: {
                email: "",
                sno: "",
                inn: "",
                payment_address: ""
            },
            agent_info: {
                type: "",
                paying_agent: {
                    operation: "",
                    phones: [""]
                },
                receive_payments_operator: {
                    phones: [""]
                },
                money_transfer_operator: {
                    phones: [""],
                    name: "",
                    address: "",
                    inn: ""
                }
            },
            supplier_info: {
                phones: [""]
            },
            items: [
                {
                    name: "",
                    price: 0,
                    quantity: 0,
                    sum: 0,
                    measurement_unit: "",
                    payment_method: "",
                    payment_object: "",
                    vat: {
                        type: "",
                        sum: 0
                    },
                    agent_info: {
                        type: "",
                        paying_agent: {
                            operation: "",
                            phones: [""]
                        },
                        receive_payments_operator: {
                            phones: [""]
                        },
                        money_transfer_operator: {
                            phones: [""],
                            name: "",
                            address: "",
                            inn: ""
                        }
                    },
                    supplier_info: {
                        phones: [""],
                        name: "",
                        address: "",
                        inn: ""
                    },
                    user_data: ""
                }
            ],
            payments: [
                {
                    type: 0,
                    sum: 0
                }
            ],
            vats: [
                {
                    type: "",
                    sum: 0
                }
            ],
            total: 0,
            additional_check_props: "",
            cashier: "",
            additional_user_props: {
                name: "",
                value: ""
            }
        }
    };
*/

//----------------------
// Подключение библиотек
//----------------------

const util = require("util"); //Встроенные вспомогательные утилиты
const parseString = require("xml2js").parseString; //Конвертация XML в JSON
const _ = require("lodash"); //Работа с массивами и коллекциями
const rqp = require("request-promise"); //Работа с HTTP/HTTPS запросами
const { buildURL } = require("@core/utils"); //Вспомогательные функции
const { NFN_TYPE_LOGIN } = require("@models/obj_service_function");

//---------------------
// Глобальные константы
//---------------------

//Словарь - Признак способа расчёта
const paymentMethod = {
    sName: "Признак способа расчёта",
    vals: {
        "1": "full_prepayment",
        "2": "prepayment",
        "3": "advance",
        "4": "full_payment",
        "5": "partial_payment",
        "6": "credit",
        "7": "credit_payment"
    }
};

//Словарь - Признак предмета расчёта
const paymentObject = {
    sName: "Признак предмета расчёта",
    vals: {
        "1": "commodity",
        "2": "excise",
        "3": "job",
        "4": "service",
        "5": "gambling_bet",
        "6": "gambling_prize",
        "7": "lottery",
        "8": "lottery_prize",
        "9": "intellectual_activity",
        "10": "payment",
        "11": "agent_commission",
        "12": "composite",
        "13": "another",
        "14": "property_right",
        "15": "non-operating_gain",
        "16": "insurance_premium",
        "17": "sales_tax",
        "18": "resort_fee"
    }
};

//Словарь - Тип операции
const paymensOperation = {
    sName: "Тип операции",
    vals: {
        "1": "sell",
        "2": "sell_refund",
        "3": "buy",
        "4": "buy_refund"
    }
};

//------------
// Тело модуля
//------------

//Разбор XML
const parseXML = xmlDoc => {
    return new Promise((resolve, reject) => {
        parseString(xmlDoc, { explicitArray: false, mergeAttrs: true }, function(err, result) {
            if (err) reject(err);
            else resolve(result);
        });
    });
};

//Конвертация значений в ожидаемые систеой АТОЛ-онлайн
const mapDictionary = (dict, sValue) => {
    if (!dict) throw Error(`Словарь не определен`);
    if (!dict.sName || !dict.vals || !(dict.vals instanceof Object)) throw Error(`Словарь имеет некорректный формат`);
    if (typeof sValue === "undefined" || sValue === null || sValue === "")
        throw Error(`Не указано значение для привязки к словарю "${dict.sName}"`);
    const res = dict.vals[sValue];
    if (typeof res === "undefined") throw Error(`Значение "${sValue}" отсутствует в словаре "${dict.sName}"`);
    return res;
};

//Поиск значения в составе свойств фискального документа по коду свойства
const getPropValueByCode = (props, sCode, sValType = "STR", sValField = "VALUE") => {
    if (!["STR", "NUM", "DATE"].includes(sValType)) throw Error(`Тип данных "${sValType}" не поддерживается`);
    let res = null;
    let prop = _.find(props, { SCODE: sCode });
    if (typeof prop !== "undefined") {
        res = prop[sValField];
        if (typeof res === "undefined") res = null;
        else if (res === "") res = null;
        if (res !== null) {
            switch (sValType) {
                case "STR": {
                    try {
                        res = res.toString();
                    } catch (e) {
                        throw Error(`Ошибка конвертации значения "${res}" в строку: ${e.message}`);
                    }
                    break;
                }
                case "NUM": {
                    if (isNaN(res)) throw Error(`Значение "${res}" не является числом`);
                    try {
                        res = Number(res);
                    } catch (e) {
                        throw Error(`Ошибка конвертации значения "${res}" в число: ${e.message}`);
                    }
                    break;
                }
                case "DATE": {
                    const resTmp = res;
                    try {
                        res = new Date(res);
                    } catch (e) {
                        throw Error(`Ошибка конвертации значения "${resTmp}" в дату: ${e.message}`);
                    }
                    if (res instanceof Date && isNaN(res))
                        throw Error(`Значение "${resTmp}" не является корректной датой`);
                    break;
                }
                default:
                    throw Error(`Тип данных "${sValType}" не поддерживается`);
            }
        }
    }
    return res;
};

//Конвертация строки в формате ДД.ММ.ГГГГ ЧЧ:МИ:СС в JS Date
const strDDMMYYYYHHMISStoDate = sDate => {
    let res = null;
    if (sDate) {
        try {
            const [date, time] = sDate.split(" ");
            const [day, month, year] = date.split(".");
            const [hh, min, ss] = time.split(":");
            res = new Date(year, month - 1, day, hh, min, ss);
            if (isNaN(res.getTime())) {
                res = null;
            } else {
                res.addHours = function(nHours) {
                    this.setTime(this.getTime() + nHours * 60 * 60 * 1000);
                    return this;
                };
            }
        } catch (e) {
            res = null;
        }
    }
    return res;
};

//Обработчик "До" подключения к сервису
const beforeConnect = async prms => {
    return {
        options: {
            headers: {
                "Content-type": "application/json; charset=utf-8"
            },
            body: JSON.stringify({ login: prms.service.sSrvUser, pass: prms.service.sSrvPass }),
            simple: false
        }
    };
};

//Обработчик "После" подключения к сервису
const afterConnect = async prms => {
    let resp = null;
    if (prms.queue.blResp) {
        try {
            resp = JSON.parse(prms.queue.blResp.toString());
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: ${e.message}`);
        }
    } else {
        throw new Error(`Сервер АТОЛ-Онлайн не вернул ответ`);
    }
    if (resp.error === null) {
        return {
            blResp: new Buffer(resp.token),
            sCtx: resp.token,
            dCtxExp: strDDMMYYYYHHMISStoDate(resp.timestamp).addHours(24)
        };
    } else {
        throw new Error(`Сервер АТОЛ-Онлайн вернул ошибку: ${resp.error.text}`);
    }
};

//Обработчик "До" отправки запроса на регистрацию чека (приход, расход, возврат) серверу "АТОЛ-Онлайн"
const beforeRegBillSIR = async prms => {
    try {
        //Код круппы ККТ
        const sGroupCode = "v4-online-atol-ru_4179";
        //Токен доступа
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Разберем XML-данные фискального документа
        let parseRes = null;
        try {
            parseRes = await parseXML(prms.queue.blMsg.toString());
        } catch (e) {
            throw new Error("Ошибка рабора XML");
        }
        //Сохраним короткие ссылки на документ и его свойства
        const doc = parseRes.FISCDOC;
        const docProps = parseRes.FISCDOC.FISCDOC_PROPS.FISCDOC_PROP;
        //Определим тип операции
        const sOperation = mapDictionary(paymensOperation, getPropValueByCode(docProps, "1054"));
        //Собираем тело запроса в JSON из XML-данных документа
        let reqBody = {
            timestamp: doc.SDDOC_DATE,
            external_id: doc.NRN,
            receipt: {
                client: {
                    email: "mim_@mail.ru", //getPropValueByCode(docProps, "1008"),
                    phone: ""
                },
                company: {
                    email: "mim_@mail.ru", //getPropValueByCode(docProps, "1117"),
                    sno: "osn", //getPropValueByCode(docProps, "1055"),
                    inn: getPropValueByCode(docProps, "1018"),
                    payment_address: "г. Казань" //getPropValueByCode(docProps, "1187")
                },
                items: [
                    {
                        name: getPropValueByCode(docProps, "1030"),
                        price: getPropValueByCode(docProps, "1079", "NUM"),
                        quantity: getPropValueByCode(docProps, "1023", "NUM"),
                        sum: getPropValueByCode(docProps, "1043", "NUM"),
                        measurement_unit: getPropValueByCode(docProps, "1197"),
                        //payment_method: "full_prepayment",
                        //payment_object: "service",
                        payment_method: mapDictionary(paymentMethod, getPropValueByCode(docProps, "1214")),
                        payment_object: mapDictionary(paymentObject, getPropValueByCode(docProps, "1212")),
                        vat: {
                            type: "none", //getPropValueByCode(docProps, "1199")
                            sum: getPropValueByCode(docProps, "1200", "NUM")
                        }
                    }
                ],
                total: getPropValueByCode(docProps, "1020", "NUM")
            }
        };
        //Добавим общие платежи
        let payments = [];
        //Сумма по чеку электронными
        if (getPropValueByCode(docProps, "1081", "NUM") !== null) {
            payments.push({
                type: 1,
                sum: getPropValueByCode(docProps, "1081", "NUM")
            });
        }
        //Сумма по чеку предоплатой (зачет аванса и (или) предыдущих платежей)
        if (getPropValueByCode(docProps, "1215", "NUM") !== null) {
            payments.push({
                type: 2,
                sum: getPropValueByCode(docProps, "1215", "NUM")
            });
        }
        //Сумма по чеку постоплатой (кредит)
        if (getPropValueByCode(docProps, "1216", "NUM") !== null) {
            payments.push({
                type: 3,
                sum: getPropValueByCode(docProps, "1216", "NUM")
            });
        }
        //Сумма по чеку встречным представлением
        if (getPropValueByCode(docProps, "1217", "NUM") !== null) {
            payments.push({
                type: 4,
                sum: getPropValueByCode(docProps, "1217", "NUM")
            });
        }
        //Если есть хоть один платёж - помещаем массив в запрос
        if (payments.length > 0) reqBody.receipt.payments = payments;
        //Добавим общие налоги
        let vats = [];
        //Сумма расчета по чеку без НДС;
        if (getPropValueByCode(docProps, "1105", "NUM") !== null) {
            vats.push({
                type: "none",
                sum: getPropValueByCode(docProps, "1105", "NUM")
            });
        }
        //Сумма расчета по чеку с НДС по ставке 0%;
        if (getPropValueByCode(docProps, "1104", "NUM") !== null) {
            vats.push({
                type: "vat0",
                sum: getPropValueByCode(docProps, "1104", "NUM")
            });
        }
        //Сумма НДС чека по ставке 10%;
        if (getPropValueByCode(docProps, "1103", "NUM") !== null) {
            vats.push({
                type: "vat10",
                sum: getPropValueByCode(docProps, "1103", "NUM")
            });
        }
        //Сумма НДС чека по ставке 18%;
        if (getPropValueByCode(docProps, "1102", "NUM") !== null) {
            vats.push({
                type: "vat18",
                sum: getPropValueByCode(docProps, "1102", "NUM")
            });
        }
        //Сумма НДС чека по расч. ставке 10/110;
        if (getPropValueByCode(docProps, "1107", "NUM") !== null) {
            vats.push({
                type: "vat110",
                sum: getPropValueByCode(docProps, "1107", "NUM")
            });
        }
        //Сумма НДС чека по расч. ставке 18/118
        if (getPropValueByCode(docProps, "1106", "NUM") !== null) {
            vats.push({
                type: "vat118",
                sum: getPropValueByCode(docProps, "1106", "NUM")
            });
        }
        //Если есть хоть один налог - помещаем массив в запрос
        if (vats.length > 0) reqBody.receipt.vats = vats;
        //Собираем общий результат работы
        let res = {
            options: {
                url: buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL })
                    .replace("<group_code>", sGroupCode)
                    .replace("<operation>", sOperation),
                headers: {
                    "Content-type": "application/json; charset=utf-8",
                    Token: sToken
                },
                simple: false
            },
            blMsg: new Buffer(JSON.stringify(reqBody))
        };
        //Возврат резульатата
        return res;
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" отправки запроса на регистрацию чека (приход, расход, возврат) серверу "АТОЛ-Онлайн"
const afterRegBillSIR = async prms => {
    let resp = null;
    if (prms.queue.blResp) {
        try {
            resp = JSON.parse(prms.queue.blResp.toString());
        } catch (e) {
            throw new Error(`Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: ${e.message}`);
        }
    } else {
        throw new Error(`Сервер АТОЛ-Онлайн не вернул ответ`);
    }
    if (resp.error === null) {
        return {
            blResp: new Buffer(resp.uuid)
        };
    } else {
        if (resp.error.code === 10 || resp.error.code === 11) {
            return { bUnAuth: true };
        } else {
            throw new Error(`Сервер АТОЛ-Онлайн вернул ошибку: ${resp.error.text}`);
        }
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeConnect = beforeConnect;
exports.afterConnect = afterConnect;
exports.beforeRegBillSIR = beforeRegBillSIR;
exports.afterRegBillSIR = afterRegBillSIR;
