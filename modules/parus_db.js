/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: работа с БД ПП Парус 8 (Oracle)
*/

//----------------------
// Подключение библиотек
//----------------------

const oracledb = require("oracledb"); //Работа с СУБД Oracle

//------------
// Тело модуля
//------------

//Подключение к БД
const connect = prms => {
    return new Promise((resolve, reject) => {
        oracledb.getConnection(
            {
                user: prms.user,
                password: prms.password,
                connectString: prms.connectString
            },
            function(err, connection) {
                if (err) {
                    reject(err);
                } else {
                    resolve(connection);
                }
            }
        );
    });
};

//Отключение от БД
const disconnect = connection => {
    return new Promise((resolve, reject) => {
        if (connection) {
            connection.close(function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        } else {
            reject(new Error("No connection specified"));
        }
    });
};

//Исполнение запроса
const execute = prms => {
    console.log("EXECUTE");
};

//-----------------
// Интерфейс модуля
//-----------------

exports.connect = connect;
exports.disconnect = disconnect;
exports.execute = execute;

/*
oracledb.getConnection(
    {
        user: cfg.dbConnect.user,
        password: cfg.dbConnect.password,
        connectString: cfg.dbConnect.connectString
    },
    function(err, connection) {
        if (err) {
            console.error(err.message);
            return;
        }
        connection.execute(
            // The statement to execute
            "SELECT rn, agnabbr FROM agnlist WHERE rn = :id",

            // The "bind value" 180 for the bind variable ":id"
            [1431890],

            // execute() options argument.  Since the query only returns one
            // row, we can optimize memory usage by reducing the default
            // maxRows value.  For the complete list of other options see
            // the documentation.
            {
                maxRows: 1
                //, outFormat: oracledb.OBJECT  // query result format
                //, extendedMetaData: true      // get extra metadata
                //, fetchArraySize: 100         // internal buffer allocation size for tuning
            },

            // The callback function handles the SQL execution results
            function(err, result) {
                if (err) {
                    console.error(err.message);
                    setTimeout(() => {
                        doRelease(connection);
                    }, 2000);
                    return;
                }
                console.log(result.metaData); // [ { name: 'DEPARTMENT_ID' }, { name: 'DEPARTMENT_NAME' } ]
                console.log(result.rows); // [ [ 180, 'Construction' ] ]
                setTimeout(() => {
                    doRelease(connection);
                }, 2000);
            }
        );
    }
);

// Note: connections should always be released when not needed
function doRelease(connection) {
    connection.close(function(err) {
        if (err) {
            console.log("Connection closed with erros: " + err.message);
        } else {
            console.log("Connection closed - no erros");
        }
    });
}
*/
