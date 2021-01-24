/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Публикация многомерных отчетов (OLAPP)
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const { ServerError } = require("./../core/server_errors"); //Типовая ошибка
const { SERR_APP_SERVER_BEFORE, SERR_DB_SERVER } = require("./../core/constants"); //Общесистемные константы
const oracledb = require("oracledb"); //Работа с СУБД Oracle

//---------------------
// Глобальные константы
//---------------------

//------------
// Тело модуля
//------------

//Обработчик "До" для полученного сообщения
const before = async prms => {
    //Если передан идентификатор публикации
    if (prms.options.qs && prms.options.qs.STOKEN && prms.options.qs.NPREVIEW && prms.options.qs.NACTUAL_CHECK) {
        //И есть подключение к БД
        if (prms.dbConn.bConnected) {
            let pooledConnection;
            try {
                //Считаем курсор с данными публикации
                pooledConnection = await prms.dbConn.connection.getConnection();
                let res = await pooledConnection.execute(
                    "BEGIN PKG_EXS_EXT_OLAPP_RUN.EXTRACT(STOKEN => :STOKEN, NPREVIEW => :NPREVIEW, NACTUAL_CHECK => :NACTUAL_CHECK, RCDATA => :RCDATA); END;",
                    {
                        STOKEN: prms.options.qs.STOKEN,
                        NPREVIEW: prms.options.qs.NPREVIEW,
                        NACTUAL_CHECK: prms.options.qs.NACTUAL_CHECK,
                        RCDATA: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
                    },
                    { outFormat: oracledb.OBJECT }
                );
                //Установим заголовок ответа и начнём выдачу данных
                prms.res.set({
                    "content-type": "application/json;charset=utf-8"
                });
                prms.res.write("[");
                //Обходим курсор и выдаём порционно ответ
                const rs = res.outBinds.RCDATA;
                let cnt = 1;
                let row;
                while ((row = await rs.getRow())) {
                    prms.res.write(Buffer(`${cnt > 1 ? "," : ""}${JSON.stringify(row)}`));
                    cnt++;
                }
                //Завершаем передачу
                prms.res.write("]");
                prms.res.end();
                await rs.close();
                //Дальше обрабатывать не надо
                return {
                    bStopPropagation: true
                };
            } catch (e) {
                throw new ServerError(SERR_DB_SERVER, e.message);
            } finally {
                if (pooledConnection) {
                    try {
                        await pooledConnection.close();
                    } catch (e) {
                        throw new ServerError(SERR_DB_SERVER, e.message);
                    }
                }
            }
        } else {
            throw new ServerError(SERR_DB_SERVER, "Нет подключения к БД");
        }
    } else {
        throw new ServerError(SERR_APP_SERVER_BEFORE, "Запрос к серверу сформирован не корректно");
    }
};

//-----------------
// Интерфейс модуля
//-----------------

exports.before = before;
