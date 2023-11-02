/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ГАР (GAR) - вспомогательные функции
*/

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Типы сообщений
const LOG_ERR = "LOG_ERR"; //Ошибка
const LOG_WRN = "LOG_WRN"; //Предупреждение
const LOG_INF = "LOG_INF"; //Информация

//Типы сообщений обработчиков
const WRK_MSG_TYPE = {
    TASK: "TASK",
    RESULT: "RESULT",
    STOP: "STOP"
};

//------------
// Тело модуля
//------------

//Протоколирование
const log = (type, message, module, stream) => {
    let d = new Date();
    if (stream)
        stream.write(
            `${d.toLocaleString("ru-RU")}${module ? ` (${module})` : ""}${
                type === LOG_ERR ? " ОШИБКА" : type === LOG_WRN ? " ПРЕДУПРЕЖДЕНИЕ" : " ИНФОРМАЦИЯ"
            }: ${message}\n`
        );
};

//Протоколирование - ошибка
const logErr = (message, module, stream) => log(LOG_ERR, message, module, stream);

//Протоколирование - предупреждение
const logWrn = (message, module, stream) => log(LOG_WRN, message, module, stream);

//Протоколирование - информация
const logInf = (message, module, stream) => log(LOG_INF, message, module, stream);

//Формирование сообщения для останова
const makeStopMessage = () => ({ type: WRK_MSG_TYPE.STOP });

//Формирование сообщения с задачей
const makeTaskMessage = ({ payload }) => ({ type: WRK_MSG_TYPE.TASK, payload });

//Формирование ответа на задачу
const makeTaskResult = ({ err, payload }) => ({ type: WRK_MSG_TYPE.RESULT, err, payload });

//Формирование ответа на задачу (с успехом)
const makeTaskOKResult = payload => makeTaskResult({ err: null, payload });

//Формирование ответа на задачу (с ошибкой)
const makeTaskErrResult = err => makeTaskResult({ err, payload: null });

// Преобразование строки в дату в формате DD.MM.YYYY
const stringToDate = dateString => {
    const dateStringSplit = dateString.split(".");
    if (dateStringSplit.length == 3) {
        try {
            return new Date(+dateStringSplit[2], +dateStringSplit[1] - 1, +dateStringSplit[0] + 1);
        } catch (e) {
            return null;
        }
    } else {
        return null;
    }
};

// Преобразование даты в ISO строку в формате YYYY.MM.DD
const dateToISOString = date => {
    return date.toISOString().substr(0, 10);
};

//-----------------
// Интерфейс модуля
//-----------------

exports.WRK_MSG_TYPE = WRK_MSG_TYPE;
exports.logErr = logErr;
exports.logWrn = logWrn;
exports.logInf = logInf;
exports.makeStopMessage = makeStopMessage;
exports.makeTaskMessage = makeTaskMessage;
exports.makeTaskOKResult = makeTaskOKResult;
exports.makeTaskErrResult = makeTaskErrResult;
exports.stringToDate = stringToDate;
exports.dateToISOString = dateToISOString;
