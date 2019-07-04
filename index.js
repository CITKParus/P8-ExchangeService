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
const { makeErrorText, getNowString } = require("./core/utils"); //Вспомогательные функции
const { SCONSOLE_LOG_COLOR_PATTERN_ERR, SCONSOLE_LOG_COLOR_PATTERN_WRN } = require("./core/constants"); //Общие константы

//--------------------------
// Глобальные идентификаторы
//--------------------------

let appSrv = new app.ParusAppServer(); //Экземпляр сервера приложений

//----------------------------------------
// Управление процессом сервера приложений
//----------------------------------------

//Разрешение на TLS (Transport Layer Security) без авторизации
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

//Обработка события "выход" жизненного цикла процесса
process.on("exit", code => {
    //Сообщим о завершении процесса
    console.log(
        SCONSOLE_LOG_COLOR_PATTERN_WRN,
        `${getNowString()} ПРЕДУПРЕЖДЕНИЕ: `,
        `Сервер приложений остановлен (код: ${code})`
    );
});

["SIGINT", "SIGQUIT", "SIGTERM"].forEach(sSig => {
    process.on(sSig, async () => {
        await appSrv.logger.warn(`Получен сигнал на останов сервера приложений: ${sSig}`);
        const terminateTimeout = setTimeout(() => {
            console.log(
                SCONSOLE_LOG_COLOR_PATTERN_ERR,
                `${getNowString()} ОШИБКА: `,
                `Истекло время ожидания останова сервера приложений. Инициирован аварийный выход из процесса.`
            );
            process.exit(1);
        }, cfg.common.nTerminateTimeout);
        try {
            await appSrv.stop(terminateTimeout);
        } catch (e) {
            console.log(e);
            await appSrv.logger.error(`При останове сервера приложений: ${makeErrorText(e)}`);
            clearTimeout(terminateTimeout);
            process.exit(1);
        }
    });
});

//Перехват всех неохваченных ошибок
process.on("uncaughtException", e => {
    //Протоколируем ошибку
    console.log(SCONSOLE_LOG_COLOR_PATTERN_ERR, `${getNowString()} НЕПРЕДВИДЕННАЯ ОШИБКА: `, makeErrorText(e));
    //Останов с ошибкой
    process.exit(1);
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
        await appSrv.logger.error(makeErrorText(e));
        //...и пытаемся остановить сервер нормально
        try {
            await appSrv.stop();
        } catch (e) {
            //Могут быть ошибки и при остановке - это аварийный выход
            await appSrv.logger.error(makeErrorText(e));
            process.exit(1);
        }
    }
};

//------------
// Точка входа
//------------

//Старутем
start();
