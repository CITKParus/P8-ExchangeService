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

const parseString = require("xml2js").parseString; //Конвертация XML в JSON
const js2xmlparser = require("js2xmlparser"); //Конвертация JSON в XML
const _ = require("lodash"); //Работа с массивами и коллекциями
const { buildURL } = require("@core/utils"); //Вспомогательные функции

//---------------------
// Глобальные константы
//---------------------

//Код круппы ККТ
const SGROUP_CODE = "v4-online-atol-ru_4179";

//Статусы документов АТОЛ-онлайн
const SSTATUS_DONE = "done"; //Готово
const SSTATUS_FAIL = "fail"; //Ошибка
const SSTATUS_WAIT = "wait"; //Ожидание

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

//Словарь - ставка НДС позиции чека
const receiptItemVat = {
    sName: "Ставка НДС позиции чека",
    vals: {
        "1": "vat20",
        "2": "vat10",
        "3": "vat120",
        "4": "vat110",
        "5": "vat0",
        "6": "none"
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

//Добавление определённого количетсва часов к дате
const addHours = (dDate, nHours) => {
    dDate.setTime(dDate.getTime() + nHours * 60 * 60 * 1000);
    return new Date(dDate);
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
            dCtxExp: addHours(new Date(), 23)
        };
    } else {
        throw new Error(`Сервер АТОЛ-Онлайн вернул ошибку: ${resp.error.text}`);
    }
};

//Обработчик "До" отправки запроса на регистрацию чека (приход, расход, возврат) серверу "АТОЛ-Онлайн"
const beforeRegBillSIR = async prms => {
    try {
        //Токен доступа
        let sToken = null;
        if (prms.service.sCtx) {
            sToken = prms.service.sCtx;
        }
        //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Разберем XML-данные фискального документа
        let parseRes = null;
        if (prms.queue.blMsg) {
            try {
                parseRes = await parseXML(prms.queue.blMsg.toString());
            } catch (e) {
                throw new Error("Ошибка рабора XML");
            }
        } else {
            throw new Error("В теле сообщения отсутствуют данные фискального документа");
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
                    email: getPropValueByCode(docProps, "1008"),
                    phone: ""
                },
                company: {
                    email: getPropValueByCode(docProps, "1117"),
                    sno: getPropValueByCode(docProps, "1055"),
                    inn: getPropValueByCode(docProps, "1018"),
                    payment_address: getPropValueByCode(docProps, "1187")
                },
                items: [
                    {
                        name: getPropValueByCode(docProps, "1030"),
                        price: getPropValueByCode(docProps, "1079", "NUM"),
                        quantity: getPropValueByCode(docProps, "1023", "NUM"),
                        sum: getPropValueByCode(docProps, "1043", "NUM"),
                        measurement_unit: getPropValueByCode(docProps, "1197"),
                        payment_method: mapDictionary(paymentMethod, getPropValueByCode(docProps, "1214")),
                        payment_object: mapDictionary(paymentObject, getPropValueByCode(docProps, "1212")),
                        vat: {
                            type: mapDictionary(receiptItemVat, getPropValueByCode(docProps, "1199", "NUM")),
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
        //Сумма НДС чека по ставке 20%;
        if (getPropValueByCode(docProps, "1102", "NUM") !== null) {
            vats.push({
                type: "vat20",
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
        //Сумма НДС чека по расч. ставке 20/120
        if (getPropValueByCode(docProps, "1106", "NUM") !== null) {
            vats.push({
                type: "vat120",
                sum: getPropValueByCode(docProps, "1106", "NUM")
            });
        }
        //Если есть хоть один налог - помещаем массив в запрос
        if (vats.length > 0) reqBody.receipt.vats = vats;
        //Собираем общий результат работы
        let res = {
            options: {
                url: buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL })
                    .replace("<group_code>", SGROUP_CODE)
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
    //Буфер для данных ответа сервера
    let resp = null;
    //Если есть данные от сервера АТОЛ
    if (prms.queue.blResp) {
        //Пытаемся их разбирать
        try {
            resp = JSON.parse(prms.queue.blResp.toString());
        } catch (e) {
            //Пришел не JSON
            throw new Error(`Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: ${e.message}`);
        }
    } else {
        //Данных от сервера нет
        throw new Error(`Сервер АТОЛ-Онлайн не вернул ответ`);
    }
    //Данные есть и нам удалось их разобрать, проверяем на наличие ошибок
    if (resp.error === null) {
        //Ошибок нет - забираем идентификатор документа в системе АТОЛ и кладём в тело ответа - он это то что нам нужно
        return {
            blResp: new Buffer(resp.uuid)
        };
    } else {
        //Есть ошибки, посмотрим что это, может быть аутентификация (кончился токен)
        if (resp.error.code === 10 || resp.error.code === 11) {
            //да, это была она - сигнализируем серверу приложений - надо переподключаться
            return { bUnAuth: true };
        } else {
            //прочие ошибки - фиксируем в журнале
            throw new Error(`Сервер АТОЛ-Онлайн вернул ошибку: ${resp.error.text}`);
        }
    }
};

//Обработчик "До" отправки запроса на получение информации о чеке серверу "АТОЛ-Онлайн"
const beforeGetBillInfo = async prms => {
    //Токен доступа
    let sToken = null;
    if (prms.service.sCtx) {
        sToken = prms.service.sCtx;
    }
    //Если не достали из контекста токен доступа - значит нет аутентификации на сервере
    if (!sToken) return { bUnAuth: true };
    //Забираем идентификатор документа из тела сообщения
    let sUUID = null;
    if (prms.queue.blMsg) sUUID = prms.queue.blMsg.toString();
    if (!sUUID) throw new Error("В теле сообщения не указан идентификатор документа в АТОЛ-Онлайн");
    //Собираем общий результат работы
    let res = {
        options: {
            url: buildURL({ sSrvRoot: prms.service.sSrvRoot, sFnURL: prms.function.sFnURL })
                .replace("<group_code>", SGROUP_CODE)
                .replace("<uuid>", sUUID),
            headers: {
                "Content-type": "application/json; charset=utf-8",
                Token: sToken
            },
            simple: false
        }
    };
    //Возврат резульатата
    return res;
};

//Обработчик "После" отправки запроса на получение информации о чеке серверу "АТОЛ-Онлайн"
const afterGetBillInfo = async prms => {
    //if (prms.queue.blResp) console.log(prms.queue.blResp.toString());
    //else console.log("Сервер не вернул ответ");
    //Буфер для результата работы обработчика
    let res = null;
    //Буфер для данных ответа сервера
    let resp = null;
    //Если есть данные от сервера АТОЛ
    if (prms.queue.blResp) {
        //Пытаемся их разбирать
        try {
            resp = JSON.parse(prms.queue.blResp.toString());
        } catch (e) {
            //Пришел не JSON
            throw new Error(`Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: ${e.message}`);
        }
    } else {
        //Данных от сервера нет
        throw new Error(`Сервер АТОЛ-Онлайн не вернул ответ`);
    }
    //Данные есть и нам удалось их разобрать - проверим, что нет ошибок аутентификации
    //Есть ошибки, посмотрим что это, может быть аутентификация (кончился токен)
    if (resp.error !== null && (resp.error.code === 10 || resp.error.code === 11)) {
        //да, это была она - сигнализируем серверу приложений - надо переподключаться и дальше не работаем
        return { bUnAuth: true };
    }
    //Ошибок атуентификации нет - проверяем состояние документа
    if (resp.status) {
        //Проверям, может быть документ зарегистрирован
        if (resp.status === SSTATUS_DONE) {
            //Документ обработан, проверим наличие данных фискализации
            if (resp.payload) {
                //Ошибок нет - забираем данные фискализации и кладём в тело ответа - это то что нам нужно
                res = {
                    //Статус обработки документа
                    STATUS: resp.status,
                    //Дата и время документа внешней системы
                    TIMESTAMP: resp.timestamp,
                    //Дата и время документа из ФН
                    TAG1012: resp.payload.receipt_datetime,
                    //Фискальный номер документа
                    TAG1040: resp.payload.fiscal_document_number,
                    //Номер ФН
                    TAG1041: resp.payload.fn_number,
                    //Фискальный признак документа
                    TAG1077: resp.payload.fiscal_document_attribute
                };
            } else {
                //В ответе сервера нет ни данных фискализации, при этом документ отработан - это неожиданный ответ
                throw new Error(
                    `Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: документ в статусе "Готов" но в ответе сервера нет данных фискализации`
                );
            }
        } else {
            //Документ не зарегистрирован, может быть ещё обрабатывается
            if (resp.status === SSTATUS_WAIT) {
                //Скажем и об этом
                res = {
                    //Статус обработки документа
                    STATUS: resp.status
                };
            } else {
                //Документ не готов и не обрабатывается - очевидно ошибка при регистрации
                if (resp.status === SSTATUS_FAIL) {
                    if (resp.error) {
                        res = {
                            //Статус обработки документа
                            STATUS: resp.status,
                            //Ошибка
                            ERROR: {
                                //Код ошибки
                                CODE: resp.error.code,
                                //Текст ошибки
                                TEXT: resp.error.text
                            }
                        };
                    } else {
                        //Статус - ошибка, но ошибки нет, это неожиданный ответ
                        throw new Error(
                            `Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: документ в статусе "Ошибка" но в ответе сервера нет об ошибке`
                        );
                    }
                } else {
                    //Других статусов быть не должно - это неожиданный ответ
                    throw new Error(
                        `Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: неизвестный статус документа - ${
                            resp.status
                        }`
                    );
                }
            }
        }
    } else {
        //Нет данных о статусе документа - это неожиданный ответ
        throw new Error(
            `Неожиданный ответ сервера АТОЛ-Онлайн. Ошибка интерпретации: статус документа в ответе не определён`
        );
    }
    //Вернём сформированный ответ
    return {
        blResp: new Buffer(js2xmlparser.parse("RESP", res))
    };
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeConnect = beforeConnect;
exports.afterConnect = afterConnect;
exports.beforeRegBillSIR = beforeRegBillSIR;
exports.afterRegBillSIR = afterRegBillSIR;
exports.beforeGetBillInfo = beforeGetBillInfo;
exports.afterGetBillInfo = afterGetBillInfo;
