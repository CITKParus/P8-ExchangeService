var oracledb = require("oracledb");
var dbConfig = require("./config.js");

// Get a non-pooled connection
oracledb.getConnection(
    {
        user: dbConfig.user,
        password: dbConfig.password,
        connectString: dbConfig.connectString
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
