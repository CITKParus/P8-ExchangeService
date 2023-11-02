/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ГАР (GAR) - парсеры
*/

//------------------------------
// Подключаем внешние библиотеки
//------------------------------

const oracledb = require("oracledb"); //Работа с СУБД Oracle

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Модели (привязка парсера к файлу данных)
const MODELS = [
    { fileNameMask: /AS_ADDR_OBJ_PARAMS_(\d{8})_(.*)/i, parser: "PARAMS" },
    { fileNameMask: /AS_ADDR_OBJ_(\d{8})_(.*)/i, parser: "ADDR_OBJ" },
    { fileNameMask: /AS_ADM_HIERARCHY_(\d{8})_(.*)/i, parser: "ADM_HIERARCHY" },
    { fileNameMask: /AS_CHANGE_HISTORY_(\d{8})_(.*)/i, parser: "CHANGE_HISTORY" },
    { fileNameMask: /AS_HOUSES_PARAMS_(\d{8})_(.*)/i, parser: "PARAMS", insertProcedureName: "PKG_EXS_EXT_GAR.HOUSES_PARAMS_INSERT" },
    { fileNameMask: /AS_HOUSES_(\d{8})_(.*)/i, parser: "HOUSES" },
    { fileNameMask: /AS_MUN_HIERARCHY_(\d{8})_(.*)/i, parser: "MUN_HIERARCHY" },
    { fileNameMask: /AS_REESTR_OBJECTS_(\d{8})_(.*)/i, parser: "REESTR_OBJECTS" },
    { fileNameMask: /AS_STEADS_PARAMS_(\d{8})_(.*)/i, parser: "PARAMS", insertProcedureName: "PKG_EXS_EXT_GAR.STEADS_PARAMS_INSERT" },
    { fileNameMask: /AS_STEADS_(\d{8})_(.*)/i, parser: "STEADS" },
    { fileNameMask: /AS_HOUSE_TYPES_(\d{8})_(.*)/i, parser: "HOUSE_TYPES" },
    { fileNameMask: /AS_ADDHOUSE_TYPES_(\d{8})_(.*)/i, parser: "HOUSE_TYPES", insertProcedureName: "PKG_EXS_EXT_GAR.ADDHOUSE_TYPES_INSERT" },
    { fileNameMask: /AS_ADDR_OBJ_TYPES_(\d{8})_(.*)/i, parser: "ADDR_OBJ_TYPES" }
];

//Парсеры
const PARSERS = {
    ADDR_OBJ_TYPES: {
        element: "ADDRESSOBJECTTYPE",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NTYPE_ID: Number(item.attributes.ID),
                STYPE_LEVEL: item.attributes.LEVEL,
                SSHORTNAME: item.attributes.SHORTNAME,
                STYPE_NAME: item.attributes.NAME,
                STYPE_DESC: item.attributes.DESC,
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTIVE: item.attributes.ISACTIVE == "true" ? 1 : 0
            }));
            const sql = `begin PKG_EXS_EXT_GAR.ADDR_OBJ_TYPES_INSERT(:NIDENT, :NTYPE_ID, :STYPE_LEVEL, :SSHORTNAME, :STYPE_NAME, :STYPE_DESC, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NTYPE_ID: { type: oracledb.NUMBER },
                    STYPE_LEVEL: { type: oracledb.STRING, maxSize: 10 },
                    SSHORTNAME: { type: oracledb.STRING, maxSize: 50 },
                    STYPE_NAME: { type: oracledb.STRING, maxSize: 250 },
                    STYPE_DESC: { type: oracledb.STRING, maxSize: 250 },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    },
    HOUSE_TYPES: {
        element: "HOUSETYPE",
        async save(connection, ident, items, insertProcedureName) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NTYPE_ID: Number(item.attributes.ID),
                STYPE_NAME: item.attributes.NAME,
                SSHORTNAME: item.attributes.SHORTNAME,
                STYPE_DESC: item.attributes.DESC,
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTIVE: item.attributes.ISACTIVE == "true" ? 1 : 0
            }));
            const sql = `begin ${
                insertProcedureName ? insertProcedureName : "PKG_EXS_EXT_GAR.HOUSE_TYPES_INSERT"
            }(:NIDENT, :NTYPE_ID, :STYPE_NAME, :SSHORTNAME, :STYPE_DESC, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NTYPE_ID: { type: oracledb.NUMBER },
                    STYPE_NAME: { type: oracledb.STRING, maxSize: 250 },
                    SSHORTNAME: { type: oracledb.STRING, maxSize: 50 },
                    STYPE_DESC: { type: oracledb.STRING, maxSize: 250 },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    },
    PARAMS: {
        element: "PARAM",
        async save(connection, ident, items, insertProcedureName) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NPARAM_ID: Number(item.attributes.ID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                NCHANGEID: item.attributes.CHANGEID == undefined || item.attributes.CHANGEID == null ? null : Number(item.attributes.CHANGEID),
                NCHANGEIDEND:
                    item.attributes.CHANGEIDEND == undefined || item.attributes.CHANGEIDEND == null ? null : Number(item.attributes.CHANGEIDEND),
                NPARAM_TYPEID: Number(item.attributes.TYPEID),
                SPARAM_VALUE: item.attributes.VALUE.substring(0, 4000),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE)
            }));
            const sql = `begin ${
                insertProcedureName ? insertProcedureName : "PKG_EXS_EXT_GAR.ADDR_OBJ_PARAMS_INSERT"
            }(:NIDENT, :NPARAM_ID, :NOBJECTID, :NCHANGEID, :NCHANGEIDEND, :NPARAM_TYPEID, :SPARAM_VALUE, :DUPDATEDATE, :DSTARTDATE, :DENDDATE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NPARAM_ID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    NCHANGEID: { type: oracledb.NUMBER },
                    NCHANGEIDEND: { type: oracledb.NUMBER },
                    NPARAM_TYPEID: { type: oracledb.NUMBER },
                    SPARAM_VALUE: { type: oracledb.STRING, maxSize: 4000 },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE }
                }
            });
        }
    },
    MUN_HIERARCHY: {
        element: "ITEM",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NMUN_ID: Number(item.attributes.ID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                NPARENTOBJID:
                    item.attributes.PARENTOBJID == undefined || item.attributes.PARENTOBJID == null ? null : Number(item.attributes.PARENTOBJID),
                NCHANGEID: Number(item.attributes.CHANGEID),
                SOKTMO: item.attributes.OKTMO,
                NPREVID: item.attributes.PREVID == undefined || item.attributes.PREVID == null ? null : Number(item.attributes.PREVID),
                NNEXTID: item.attributes.NEXTID == undefined || item.attributes.NEXTID == null ? null : Number(item.attributes.NEXTID),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTIVE: Number(item.attributes.ISACTIVE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.MUN_HIERARCHY_INSERT(:NIDENT, :NMUN_ID, :NOBJECTID, :NPARENTOBJID, :NCHANGEID, :SOKTMO, :NPREVID, :NNEXTID, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NMUN_ID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    NPARENTOBJID: { type: oracledb.NUMBER },
                    NCHANGEID: { type: oracledb.NUMBER },
                    SOKTMO: { type: oracledb.STRING, maxSize: 11 },
                    NPREVID: { type: oracledb.NUMBER },
                    NNEXTID: { type: oracledb.NUMBER },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    },
    ADM_HIERARCHY: {
        element: "ITEM",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NADM_ID: Number(item.attributes.ID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                NPARENTOBJID:
                    item.attributes.PARENTOBJID == undefined || item.attributes.PARENTOBJID == null ? null : Number(item.attributes.PARENTOBJID),
                NCHANGEID: Number(item.attributes.CHANGEID),
                SREGIONCODE: item.attributes.REGIONCODE,
                SAREACODE: item.attributes.AREACODE,
                SCITYCODE: item.attributes.CITYCODE,
                SPLACECODE: item.attributes.PLACECODE,
                SPLANCODE: item.attributes.PLANCODE,
                SSTREETCODE: item.attributes.STREETCODE,
                NPREVID: item.attributes.PREVID == undefined || item.attributes.PREVID == null ? null : Number(item.attributes.PREVID),
                NNEXTID: item.attributes.NEXTID == undefined || item.attributes.NEXTID == null ? null : Number(item.attributes.NEXTID),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTIVE: Number(item.attributes.ISACTIVE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.ADM_HIERARCHY_INSERT(:NIDENT, :NADM_ID, :NOBJECTID, :NPARENTOBJID, :NCHANGEID, :SREGIONCODE, :SAREACODE, :SCITYCODE, :SPLACECODE, :SPLANCODE, :SSTREETCODE, :NPREVID, :NNEXTID, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NADM_ID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    NPARENTOBJID: { type: oracledb.NUMBER },
                    NCHANGEID: { type: oracledb.NUMBER },
                    SREGIONCODE: { type: oracledb.STRING, maxSize: 4 },
                    SAREACODE: { type: oracledb.STRING, maxSize: 4 },
                    SCITYCODE: { type: oracledb.STRING, maxSize: 4 },
                    SPLACECODE: { type: oracledb.STRING, maxSize: 4 },
                    SPLANCODE: { type: oracledb.STRING, maxSize: 4 },
                    SSTREETCODE: { type: oracledb.STRING, maxSize: 4 },
                    NPREVID: { type: oracledb.NUMBER },
                    NNEXTID: { type: oracledb.NUMBER },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    },
    CHANGE_HISTORY: {
        element: "ITEM",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NCHANGEID: Number(item.attributes.CHANGEID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                SADROBJECTID: item.attributes.ADROBJECTID,
                NOPERTYPEID: Number(item.attributes.OPERTYPEID),
                NNDOCID: item.attributes.NDOCID == undefined || item.attributes.NDOCID == null ? null : Number(item.attributes.NDOCID),
                DCHANGEDATE: new Date(item.attributes.CHANGEDATE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.CHANGE_HISTORY_INSERT(:NIDENT, :NCHANGEID, :NOBJECTID, :SADROBJECTID, :NOPERTYPEID, :NNDOCID, :DCHANGEDATE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NCHANGEID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    SADROBJECTID: { type: oracledb.STRING, maxSize: 36 },
                    NOPERTYPEID: { type: oracledb.NUMBER },
                    NNDOCID: { type: oracledb.NUMBER },
                    DCHANGEDATE: { type: oracledb.DATE }
                }
            });
        }
    },
    REESTR_OBJECTS: {
        element: "OBJECT",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NOBJECTID: Number(item.attributes.OBJECTID),
                SOBJECTGUID: item.attributes.OBJECTGUID,
                NCHANGEID: Number(item.attributes.CHANGEID),
                NISACTIVE: Number(item.attributes.ISACTIVE),
                NLEVELID: Number(item.attributes.LEVELID),
                DCREATEDATE: new Date(item.attributes.CREATEDATE),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.REESTR_OBJECTS_INSERT(:NIDENT, :NOBJECTID, :SOBJECTGUID, :NCHANGEID, :NISACTIVE, :NLEVELID, :DCREATEDATE, :DUPDATEDATE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    SOBJECTGUID: { type: oracledb.STRING, maxSize: 36 },
                    NCHANGEID: { type: oracledb.NUMBER },
                    NISACTIVE: { type: oracledb.NUMBER },
                    NLEVELID: { type: oracledb.NUMBER },
                    DCREATEDATE: { type: oracledb.DATE },
                    DUPDATEDATE: { type: oracledb.DATE }
                }
            });
        }
    },
    ADDR_OBJ: {
        element: "OBJECT",
        async save(connection, ident, items, insertProcedureName, region) {
            const binds = items.map(item => ({
                NIDENT: ident,
                SREGIONCODE: region,
                NADDR_OBJ_ID: Number(item.attributes.ID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                SOBJECTGUID: item.attributes.OBJECTGUID,
                NCHANGEID: Number(item.attributes.CHANGEID),
                SADDR_OBJ_NAME: item.attributes.NAME,
                STYPENAME: item.attributes.TYPENAME,
                NADDR_OBJ_LEVEL: Number(item.attributes.LEVEL),
                SOPERTYPEID: item.attributes.OPERTYPEID,
                NPREVID: item.attributes.PREVID == undefined || item.attributes.PREVID == null ? null : Number(item.attributes.PREVID),
                NNEXTID: item.attributes.NEXTID == undefined || item.attributes.NEXTID == null ? null : Number(item.attributes.NEXTID),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTUAL: Number(item.attributes.ISACTUAL),
                NISACTIVE: Number(item.attributes.ISACTIVE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.ADDR_OBJ_INSERT(:NIDENT, :SREGIONCODE, :NADDR_OBJ_ID, :NOBJECTID, :SOBJECTGUID, :NCHANGEID, :SADDR_OBJ_NAME, :STYPENAME, :NADDR_OBJ_LEVEL, :SOPERTYPEID, :NPREVID, :NNEXTID, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTUAL, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    SREGIONCODE: { type: oracledb.STRING, maxSize: 2 },
                    NADDR_OBJ_ID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    SOBJECTGUID: { type: oracledb.STRING, maxSize: 36 },
                    NCHANGEID: { type: oracledb.NUMBER },
                    SADDR_OBJ_NAME: { type: oracledb.STRING, maxSize: 250 },
                    STYPENAME: { type: oracledb.STRING, maxSize: 50 },
                    NADDR_OBJ_LEVEL: { type: oracledb.NUMBER },
                    SOPERTYPEID: { type: oracledb.STRING, maxSize: 2 },
                    NPREVID: { type: oracledb.NUMBER },
                    NNEXTID: { type: oracledb.NUMBER },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTUAL: { type: oracledb.NUMBER },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    },
    HOUSES: {
        element: "HOUSE",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NHOUSES_ID: Number(item.attributes.ID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                SOBJECTGUID: item.attributes.OBJECTGUID,
                NCHANGEID: Number(item.attributes.CHANGEID),
                SHOUSENUM: item.attributes.HOUSENUM,
                SADDNUM1: item.attributes.ADDNUM1,
                SADDNUM2: item.attributes.ADDNUM2,
                NHOUSETYPE: item.attributes.HOUSETYPE == undefined || item.attributes.HOUSETYPE == null ? null : Number(item.attributes.HOUSETYPE),
                NADDTYPE1: item.attributes.ADDTYPE1 == undefined || item.attributes.ADDTYPE1 == null ? null : Number(item.attributes.ADDTYPE1),
                NADDTYPE2: item.attributes.ADDTYPE2 == undefined || item.attributes.ADDTYPE2 == null ? null : Number(item.attributes.ADDTYPE2),
                NOPERTYPEID: Number(item.attributes.OPERTYPEID),
                NPREVID: item.attributes.PREVID == undefined || item.attributes.PREVID == null ? null : Number(item.attributes.PREVID),
                NNEXTID: item.attributes.NEXTID == undefined || item.attributes.NEXTID == null ? null : Number(item.attributes.NEXTID),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTUAL: Number(item.attributes.ISACTUAL),
                NISACTIVE: Number(item.attributes.ISACTIVE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.HOUSES_INSERT(:NIDENT, :NHOUSES_ID, :NOBJECTID, :SOBJECTGUID, :NCHANGEID, :SHOUSENUM, :SADDNUM1, :SADDNUM2, :NHOUSETYPE, :NADDTYPE1, :NADDTYPE2, :NOPERTYPEID, :NPREVID, :NNEXTID, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTUAL, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NHOUSES_ID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    SOBJECTGUID: { type: oracledb.STRING, maxSize: 36 },
                    NCHANGEID: { type: oracledb.NUMBER },
                    SHOUSENUM: { type: oracledb.STRING, maxSize: 50 },
                    SADDNUM1: { type: oracledb.STRING, maxSize: 50 },
                    SADDNUM2: { type: oracledb.STRING, maxSize: 50 },
                    NHOUSETYPE: { type: oracledb.NUMBER },
                    NADDTYPE1: { type: oracledb.NUMBER },
                    NADDTYPE2: { type: oracledb.NUMBER },
                    NOPERTYPEID: { type: oracledb.NUMBER },
                    NPREVID: { type: oracledb.NUMBER },
                    NNEXTID: { type: oracledb.NUMBER },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTUAL: { type: oracledb.NUMBER },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    },
    STEADS: {
        element: "STEAD",
        async save(connection, ident, items) {
            const binds = items.map(item => ({
                NIDENT: ident,
                NSTEADS_ID: Number(item.attributes.ID),
                NOBJECTID: Number(item.attributes.OBJECTID),
                SOBJECTGUID: item.attributes.OBJECTGUID,
                NCHANGEID: Number(item.attributes.CHANGEID),
                SSTEADS_NUMBER: item.attributes.NUMBER,
                NOPERTYPEID: Number(item.attributes.OPERTYPEID),
                NPREVID: item.attributes.PREVID == undefined || item.attributes.PREVID == null ? null : Number(item.attributes.PREVID),
                NNEXTID: item.attributes.NEXTID == undefined || item.attributes.NEXTID == null ? null : Number(item.attributes.NEXTID),
                DUPDATEDATE: new Date(item.attributes.UPDATEDATE),
                DSTARTDATE: new Date(item.attributes.STARTDATE),
                DENDDATE: new Date(item.attributes.ENDDATE),
                NISACTUAL: Number(item.attributes.ISACTUAL),
                NISACTIVE: Number(item.attributes.ISACTIVE)
            }));
            const sql = `begin PKG_EXS_EXT_GAR.STEADS_INSERT(:NIDENT, :NSTEADS_ID, :NOBJECTID, :SOBJECTGUID, :NCHANGEID, :SSTEADS_NUMBER, :NOPERTYPEID, :NPREVID, :NNEXTID, :DUPDATEDATE, :DSTARTDATE, :DENDDATE, :NISACTUAL, :NISACTIVE); end;`;
            await connection.executeMany(sql, binds, {
                autoCommit: true,
                bindDefs: {
                    NIDENT: { type: oracledb.NUMBER },
                    NSTEADS_ID: { type: oracledb.NUMBER },
                    NOBJECTID: { type: oracledb.NUMBER },
                    SOBJECTGUID: { type: oracledb.STRING, maxSize: 36 },
                    NCHANGEID: { type: oracledb.NUMBER },
                    SSTEADS_NUMBER: { type: oracledb.STRING, maxSize: 250 },
                    NOPERTYPEID: { type: oracledb.NUMBER },
                    NPREVID: { type: oracledb.NUMBER },
                    NNEXTID: { type: oracledb.NUMBER },
                    DUPDATEDATE: { type: oracledb.DATE },
                    DSTARTDATE: { type: oracledb.DATE },
                    DENDDATE: { type: oracledb.DATE },
                    NISACTUAL: { type: oracledb.NUMBER },
                    NISACTIVE: { type: oracledb.NUMBER }
                }
            });
        }
    }
};

//------------
// Тело модуля
//------------

//Поиск модели по имени файла
const findModelByFileName = fileName => MODELS.find(item => (fileName.match(item.fileNameMask) ? true : false));

//-----------------
// Интерфейс модуля
//-----------------

exports.MODELS = MODELS;
exports.PARSERS = PARSERS;
exports.findModelByFileName = findModelByFileName;
