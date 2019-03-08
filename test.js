/*
  Сервис интеграции ПП Парус 8 с WEB API
  Песочница для тестов
*/

require("module-alias/register"); //Поддержка псевонимов при подключении модулей
const _ = require("lodash");
const db = require("./core/db_connector");
const cfg = require("./config");
const utl = require("./core/utils");
const servSchema = require("./models/obj_service");
const Schema = require("validate"); //Схемы валидации
const js2xmlparser = require("js2xmlparser"); //Конвертация JSON в XML
//const { xml } = require("./fisc_doc_xml");
const parseString = require("xml2js").parseString; //Конвертация XML в JSON
/*
const NDETECTING_LOOP_INTERVAL = 10;
let nTimeOut = null;

const restartDetectingLoop = () => {
    console.log(`BEGIN restartDetectingLoop`);
    nTimeOut = setTimeout(notifyDetectingLoop, NDETECTING_LOOP_INTERVAL);
    console.log(`END restartDetectingLoop`);
};

const someAsyncAction = i => {
    return new Promise((res, rej) => {
        setTimeout(() => {
            console.log(`Сделал I=${i}`);
            res();
        }, 100);
    });
};

//Опрос очереди уведомлений
const notifyDetectingLoop = async () => {
    console.log(`BEGIN notifyDetectingLoop`);
    for (let i = 0; i <= 5; i++) {
        console.log(`Делаю I=${i}`);
        await someAsyncAction(i);
    }
    restartDetectingLoop();
    console.log(`END notifyDetectingLoop`);
};

notifyDetectingLoop();
*/

//let sObjName = "123";
//console.log(utl.validateObject({}, servSchema.ServiceCtx));
let b;
let a = new Buffer(b || "");
