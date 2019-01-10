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

const errors = servSchema.ServiceExpiredQueueInfo.validate(
    { nId: 123, nCnt: 0, sInfoList: "dsdfsdf" },
    { strip: false }
);
console.log(errors);
