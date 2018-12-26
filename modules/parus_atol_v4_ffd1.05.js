/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с "АТОЛ-Онлайн" (v4) в формате ФФД 1.05
*/

//----------------------
// Подключение библиотек
//----------------------

const util = require("util"); //Встроенные вспомогательные утилиты
const parseString = require("xml2js").parseString; //Конвертация XML в JSON
const _ = require("lodash"); //Работа с массивами и коллекциями

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

//Обработчик "До" отправки запроса на регистрацию чека (приход, расход, возврат) серверу "АТОЛ-Онлайн"
const beforeRegBillSIR = async prms => {
    try {
        const parseRes = await parseXML(prms.queue.blMsg.toString());
        const doc = parseRes.FISCDOC;
        const docProps = parseRes.FISCDOC.FISCDOC_PROPS.FISCDOC_PROP;
        let reqBody = {
            timestamp: doc.SDDOC_DATE,
            external_id: doc.NRN,
            /*
            service: {
                callback_url: ""
            },
            */
            receipt: {
                client: {
                    email: getPropValueByCode(docProps, "1008"),
                    phone: ""
                },
                company: {
                    email: getPropValueByCode(docProps, "1117"),
                    sno: getPropValueByCode(docProps, "1117"),
                    inn: getPropValueByCode(docProps, "1018"),
                    payment_address: getPropValueByCode(docProps, "1187")
                },
                /*
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
                */
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
                            type: "none",
                            sum: getPropValueByCode(docProps, "1200", "NUM")
                        } /*,
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
                        */
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
                total: 0 /*,
                additional_check_props: "",
                cashier: "",
                additional_user_props: {
                    name: "",
                    value: ""
                }
                */
            }
        };
        console.log(util.inspect(reqBody, false, null));
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" отправки запроса на регистрацию чека (приход, расход, возврат) серверу "АТОЛ-Онлайн"
const afterRegBillSIR = async prms => {};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeRegBillSIR = beforeRegBillSIR;
exports.afterRegBillSIR = afterRegBillSIR;
