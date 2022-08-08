/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Рассылка E-Mail (MAIL)
*/

//------------------------------
// Подключение внешних библиотек
//------------------------------

const xml2js = require("xml2js"); //Конвертация XML в JSON и JSON в XML
const cfg = require("./../config"); //Настройки сервера приложений
const { makeErrorText, sendMail } = require("./../core/utils"); //Вспомогательные функции
const oracledb = require("oracledb"); //Работа с СУБД Oracle

//---------------------
// Глобальные константы
//---------------------

//Статусы отправки
const NSTATUS_ERR = 2;
const NSTATUS_DONE = 3;

//------------
// Тело модуля
//------------

//Чтение данных из курсора
const readCursorData = cursor => {
    return new Promise((resolve, reject) => {
        let queryStream = cursor.toQueryStream();
        let rows = [];
        queryStream.on("data", row => {
            rows.push(row);
        });
        queryStream.on("error", err => {
            reject(new Error(err.message));
        });
        queryStream.on("close", () => {
            resolve(rows);
        });
    });
};

//Установка статуса отправки
const setSendMsg = async prms => {
    let pooledConnection;
    try {
        pooledConnection = await prms.connection.getConnection();
        await pooledConnection.execute(
            "begin PKG_EXS_EXT_MAIL.EXSEXTMAIL_SET_STATUS(NRN => :NRN, SERR_TEXT => :SERR_TEXT, NSTATUS => :NSTATUS); end;",
            { NRN: prms.nRn, SERR_TEXT: prms.sErrMsg, NSTATUS: prms.nStatus },
            { autoCommit: true }
        );
    } catch (e) {
        throw new Error(e.message);
    } finally {
        if (pooledConnection) {
            try {
                await pooledConnection.close();
            } catch (e) {
                throw new Error(e.message);
            }
        }
    }
};

//Считывание записей прикладываемых документов
const getMailAttach = async prms => {
    let pooledConnection;
    try {
        pooledConnection = await prms.connection.getConnection();
        let res = await pooledConnection.execute(
            "begin PKG_EXS_EXT_MAIL.GET_ATTACH(NIDENT => :NIDENT, RCDOCUMENTS => :RCDOCUMENTS); end;",
            {
                NIDENT: prms.nIdent,
                RCDOCUMENTS: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            },
            { outFormat: oracledb.OBJECT, autoCommit: true }
        );
        let rows = await readCursorData(res.outBinds.RCDOCUMENTS);
        let rowsRes = [];
        //Если результат запроса не пустой
        if (rows.length !== 0) {
            //Переводим BLOB в BUFFER и формируем формат аттача
            for (let i = 0; i < rows.length; i++) {
                let rowContent = await rows[i].BDATA.getData();
                rowsRes.push({
                    filename: rows[i].FILENAME,
                    content: rowContent
                });
            }
        }
        return rowsRes;
    } catch (e) {
        throw new Error(e.message);
    } finally {
        if (pooledConnection) {
            try {
                await pooledConnection.close();
            } catch (e) {
                throw new Error(e.message);
            }
        }
    }
};

//Разбор XML
const parseXML = xmlDoc => {
    return new Promise((resolve, reject) => {
        xml2js.parseString(xmlDoc, { explicitArray: false, mergeAttrs: true }, (err, result) => {
            if (err) reject(err);
            else resolve(result);
        });
    });
};

//Обработчик "До" для исходящего сообщения
const before = async prms => {
    //Инициализируем переменные
    let res = "OK";
    let parseRes = null;
    //Разбираем параметры отправки
    try {
        //Формируем объект на основании XML
        parseRes = await parseXML(prms.queue.blMsg.toString());
        //Если есть присоединенные файлы - добавляем их
        if (parseRes.mail.ident) {
            parseRes.mail.attachments = await getMailAttach({ connection: prms.dbConn.connection, nIdent: parseRes.mail.ident });
        }
        //Если указан текст в обычном формате
        if (parseRes.mail.text) {
            parseRes.mail.text = Buffer.from(parseRes.mail.text, "base64").toString("utf-8");
        }
        //Если указан текст в формате HTML
        if (parseRes.mail.html) {
            parseRes.mail.html = Buffer.from(parseRes.mail.html, "base64").toString("utf-8");
        }
    } catch (e) {
        parseRes = prms.queue.blMsg.toString();
        res = `Ошибка разбора параметров отправки: ${makeErrorText(e)}`;
    }
    if (res === "OK") {
        try {
            await sendMail({
                mail: cfg.mail,
                sTo: parseRes.mail.to,
                sSubject: parseRes.mail.title,
                sMessage: parseRes.mail.text,
                sHTML: parseRes.mail.html,
                attachments: parseRes.mail.attachments
            });
        } catch (e) {
            res = `Ошибка отправки E-Mail сообщения: ${makeErrorText(e)}`;
        }
    }
    //Если сообщение отправилось
    if (res === "OK") {
        //Если имеется рег. номер записи очереди отправки E-mail - обновляем информацию о текущем сообщении
        if (parseRes.mail.nExsextmailId) {
            await setSendMsg({
                connection: prms.dbConn.connection,
                nRn: parseRes.mail.nExsextmailId,
                sErrMsg: "",
                nStatus: NSTATUS_DONE
            });
        }
    } else {
        //Если количество попыток не указано или это последняя попытка
        if (prms.queue.nRetryAttempts === 0 || (prms.queue.nRetryAttempts !== 0 && prms.queue.nExecCnt + 1 === prms.queue.nRetryAttempts)) {
            //Если имеется рег. номер записи очереди отправки E-mail - обновляем информацию о текущем сообщении
            if (parseRes.mail.nExsextmailId) {
                await setSendMsg({
                    connection: prms.dbConn.connection,
                    nRn: parseRes.mail.nExsextmailId,
                    sErrMsg: res,
                    nStatus: NSTATUS_ERR
                });
            }
        }
        //Выдаем ошибку
        throw new Error(res);
    }
    //Возвращаем результат и флаг того, что дальше отрабатывать это сообщение не надо
    return {
        blMsg: Buffer.from(JSON.stringify({ message: parseRes, state: res })),
        bStopPropagation: true
    };
};

//-----------------
// Интерфейс модуля
//-----------------

exports.before = before;
