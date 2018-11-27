/*
  Сервис интеграции ПП Парус 8 с WEB API
  Точка входа в сервер приложений
*/

//----------------------
// Подключение библиотек
//----------------------

require("module-alias/register"); //Поддержка псевонимов при подключении модулей
const cfg = require("./config"); //Настройки сервера приложений
const app = require("./core/app"); //Сервер приложений
const { ServerError } = require("./core/server_errors"); //Типовая ошибка
const { SERR_UNEXPECTED } = require("./core/constants"); //Общесистемные константы

//--------------------------
// Глобальные идентификаторы
//--------------------------

let appSrv = new app.ParusAppServer(); //Экземпляр сервера приложений

//----------------------------------------
// Управление процессом сервера приложений
//----------------------------------------

//Обработка события "выход" жизненного цикла процесса
process.on("exit", code => {
    //Сообщим о завершении процесса
    appSrv.logger.warn("Сервер приложений остановлен (код: " + code + ") ");
});

//Перехват CTRL + C (останова процесса)
process.on("SIGINT", () => {
    //Инициируем выход из процесса
    appSrv.stop();
});

//------------
// Точка входа
//------------

//Старутем
appSrv
    .init(cfg)
    .then(r => {
        appSrv
            .run()
            .then(r => {})
            .catch(e => {
                if (e instanceof ServerError) appSrv.logger.error(e.sCode + ": " + e.sMessage);
                else appSrv.logger.error(SERR_UNEXPECTED + ": " + e.message);
                appSrv.stop();
            });
    })
    .catch(e => {
        if (e instanceof ServerError) appSrv.logger.error(e.sCode + ": " + e.sMessage);
        else appSrv.logger.error(SERR_UNEXPECTED + ": " + e.message);
        appSrv.stop();
    });
