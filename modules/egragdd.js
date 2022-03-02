/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ЕГРЮЛ/ЕГРИП (DaData)
*/

//------------
// Тело модуля
//------------

//Обработчик "До" отправки запроса к сервису
const beforeProcess = async prms => {
    try {
        //Считаем токен доступа из контекста сервиса
        let sToken = prms.service.sSrvPass;
        //Если не заполнен токен доступа - значит нет аутентификации на сервере
        if (!sToken) return { bUnAuth: true };
        //Собираем и отдаём общий результат работы - отдаём запрос в XML, и ответ ожидаем (ключ заголовка "Accept") в XML
        return {
            options: {
                headers: {
                    "Content-type": "application/xml; charset=utf-8",
                    Accept: "application/xml; charset=utf-8",
                    Authorization: "Token " + sToken
                },
                simple: false
            }
        };
    } catch (e) {
        throw Error(e);
    }
};

//Обработчик "После" запроса к сервису
const afterProcess = async prms => {
    //Разберем ответ
    if (prms.queue.blResp) {
        //Нормальные данные приходят в XML (мы так просили), но ошибки - всегда в JSON
        try {
            //Поэтому пробуем разобрать ответ как JSON
            resp = JSON.parse(prms.queue.blResp.toString());
            //Если получилось - положим в тело текст ошибки сервера
            return {
                blResp: Buffer.from(resp.message)
            };
        } catch (e) {
            //Разобрать не получилось - видимо пришли обычные данные
            return;
        }
    } else {
        //Вообще нет данных в теле ответа
        return {
            blResp: Buffer.from("Сервер ЕГРЮЛ/ЕГРИП (DaData) не вернул ответ")
        };
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeProcess = beforeProcess;
exports.afterProcess = afterProcess;
