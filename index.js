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

//Перехват CTRL + C (останов процесса)
process.on("SIGINT", async () => {
    console.log("SIGINT");
    //Инициируем выход из процесса
    await appSrv.stop();
});

//Перехват CTRL + \ (останов процесса)
process.on("SIGQUIT", () => {
    console.log("SIGQUIT");
    //Инициируем выход из процесса
    appSrv.stop();
});

//Перехват мягкого останова процесса
process.on("SIGTERM", () => {
    console.log("SIGTERM");
    //Инициируем выход из процесса
    appSrv.stop();
});

//Грубый останов процесса (здесь сделать ничего нельзя, но мы пытаемся)
process.on("SIGKILL", () => {
    console.log("SIGKILL");
    //Инициируем выход из процесса
    appSrv.stop();
});

//Запуск сервера приложений
const start = async () => {
    try {
        //Инициализируем сервер приложений
        await appSrv.init({ config: cfg });
        //Включаем его
        await appSrv.run();
    } catch (e) {
        //Если есть ошибки с которыми сервер не справился - ловим их, показываем...
        if (e instanceof ServerError) appSrv.logger.error(e.sCode + ": " + e.sMessage);
        else appSrv.logger.error(SERR_UNEXPECTED + ": " + e.message);
        //...и пытаемся остановить сервер нормально
        try {
            await appSrv.stop();
        } catch (e) {
            //Могут быть ошибки и при остановке - это аварийный выход
            if (e instanceof ServerError) appSrv.logger.error(e.sCode + ": " + e.sMessage);
            else appSrv.logger.error(SERR_UNEXPECTED + ": " + e.message);
            process.exit(1);
        }
    }
};

//------------
// Точка входа
//------------

//Старутем
start();
