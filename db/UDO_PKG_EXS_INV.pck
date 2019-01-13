create or replace package UDO_PKG_EXS_INV as

  /* Считывание значения структурного элемента из иерархии адреса географического понятия */
  function UTL_GEOGRAFY_GET_HIER_ITEM
  (
    NGEOGRAFY               in number,  -- Регистрационный номер географического понятия
    NGEOGRTYPE              in number   -- Тип искомого структурного элемента адреса (1 - страна, 2 - регион, 3 - район, 4 - населенный пункт, 5 - улица, 6 - административный округ, 7 - муниципальный округ, 8 - город, 9 - уровень внутригородской территории, 10 - уровень дополнительных территорий, 11 - уровень подчиненных дополнительным территориям объектов)
  ) return                  varchar2;   -- Наименование найденного стуктурного элемента адреса
  
  /* Электронная инвентаризация - аутентификация */
  procedure CHECKAUTH
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Электронная инвентаризация - считывание пользователей */
  procedure GETUSERS
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Электронная инвентаризация - считывание типов ведомостей */
  procedure GETSHEETTYPES
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Электронная инвентаризация - считывание заголовков ведомостей инвентаризации */
  procedure GETSHEETS
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Электронная инвентаризация - считывание состава ведомостей инвентаризации */
  procedure GETSHEETITEMS
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Электронная инвентаризация - считывание мест хранения */
  procedure GETSTORAGES
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );  
  
  /* Электронная инвентаризация - сохранение результатов инвентаризации */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Электронная инвентаризация - сохранение результатов инвентаризации (ДЕМО, убрать!!!!) */
  procedure SAVESHEETITEM_TMP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
end;
/
create or replace package body UDO_PKG_EXS_INV as

  /* Константы - тэги */
  STSD                      constant varchar2(40) := 'tsd';
  SCHECKAUTHRESPONSE        constant varchar2(40) := 'CheckAuthResponse';
  SGETUSERSRESPONSE         constant varchar2(40) := 'GetUsersResponse';
  SGETSHEETTYPESRESPONSE    constant varchar2(40) := 'GetSheetTypesResponse';
  SGETSHEETSRESPONSE        constant varchar2(40) := 'GetSheetsResponse';
  SGETSTORAGESRESPONSE      constant varchar2(40) := 'GetStoragesResponse';
  SGETSHEETITEMSRESPONSE    constant varchar2(40) := 'GetSheetItemsResponse';
  SSAVESHEETITEMRESPONSE    constant varchar2(40) := 'SaveSheetItemResponse';
  SDEVICEID                 constant varchar2(40) := 'DeviceID';
  SRESULT                   constant varchar2(40) := 'Result';
  SSOAPENV                  constant varchar2(40) := 'soapenv';
  SENVELOPE                 constant varchar2(40) := 'Envelope';
  SHEADER                   constant varchar2(40) := 'Header';
  SBODY                     constant varchar2(40) := 'Body';
  SITEM                     constant varchar2(40) := 'Item';
  SCODE                     constant varchar2(40) := 'Code'; 
  SNAME                     constant varchar2(40) := 'Name';
  STYPECODE                 constant varchar2(40) := 'TypeCode';
  SPREFIX                   constant varchar2(40) := 'Prefix';
  SNUMBER                   constant varchar2(40) := 'Number';
  SDATE                     constant varchar2(40) := 'Date';
  SSHEETCODE                constant varchar2(40) := 'SheetCode';
  SMNEMOCODE                constant varchar2(40) := 'MnemoCode';
  SLATITUDE                 constant varchar2(40) := 'Latitude';
  SLONGITUDE                constant varchar2(40) := 'Longitude';
  SPOSTCODE                 constant varchar2(40) := 'Postcode';
  SCOUNTRY                  constant varchar2(40) := 'Country';
  SREGION                   constant varchar2(40) := 'Region';
  SLOCALITY                 constant varchar2(40) := 'Locality';
  SSTREET                   constant varchar2(40) := 'Street';
  SHOUSENUMBER              constant varchar2(40) := 'HouseNumber';
  SSTORAGEMNEMOCODE         constant varchar2(40) := 'StorageMnemoCode';
  SUSERCODE                 constant varchar2(40) := 'UserCode';
  SITEMCODE                 constant varchar2(40) := 'ItemCode';
  SITEMNAME                 constant varchar2(40) := 'ItemName';
  SITEMMNEMOCODE            constant varchar2(40) := 'ItemMnemoCode';
  SITEMNUMBER               constant varchar2(40) := 'ItemNumber';
  SQUANTITY                 constant varchar2(40) := 'Quantity';
  SSTORAGEISNEW             constant varchar2(40) := 'StorageIsNew';
  SSTORAGECODE              constant varchar2(40) := 'StorageCode';
  SSTORAGENAME              constant varchar2(40) := 'StorageName';
  SSTORAGEPOSTCODE          constant varchar2(40) := 'StoragePostcode';
  SSTORAGECOUNTRY           constant varchar2(40) := 'StorageCountry';
  SSTORAGEREGION            constant varchar2(40) := 'StorageRegion';
  SSTORAGELOCALITY          constant varchar2(40) := 'StorageLocality';
  SSTORAGESTREET            constant varchar2(40) := 'StorageStreet';
  SSTORAGEHOUSENUMBER       constant varchar2(40) := 'StorageHouseNumber';
  SSTORAGELATITUDE          constant varchar2(40) := 'StorageLatitude';
  SSTORAGELONGITUDE         constant varchar2(40) := 'StorageLongitude';
  SCHECKDATE                constant varchar2(40) := 'CheckDate';
  SCOMMENT                  constant varchar2(40) := 'Comment';
  SDISTANCETOSTORAGE        constant varchar2(40) := 'DistanceToStorage';
  SFLOOR                    constant varchar2(40) := 'Floor';
  SROOM                     constant varchar2(40) := 'Room';
  SRACK                     constant varchar2(40) := 'Rack'; 
  SFAULT                    constant varchar2(40) := 'Fault';
  SDETAIL                   constant varchar2(40) := 'detail';
  SMESSAGE                  constant varchar2(40) := 'Message';
  SERRORMESSAGE             constant varchar2(40) := 'ErrorMessage';
   
  /* Создание ветки XML */    
  function UTL_CREATENODE
  (
    XDOC                    in DBMS_XMLDOM.DOMDOCUMENT, -- Документ
    STAG                    in varchar2,                -- Наименование тэга
    SNS                     in varchar2 default null,   -- Пространство имён
    SVAL                    in varchar2 default null    -- Значение тэга
  ) 
  return                    DBMS_XMLDOM.DOMNODE         -- Ссылка на сформированный тэг документа
  is
    XEL                     DBMS_XMLDOM.DOMELEMENT;     -- Элемент пространства имён
    XNODE                   DBMS_XMLDOM.DOMNODE;        -- Формируемая ветка
    XTEXT                   DBMS_XMLDOM.DOMNODE;        -- Текст (значение) формируемой ветки
  begin
    /* Если задано пространство имён */
    if (SNS is not null) then
      /* Создаём элемент с его использованием */
      XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG, NS => SNS);
      XNODE := DBMS_XMLDOM.MAKENODE(ELEM => XEL);
      DBMS_XMLDOM.SETPREFIX(N => XNODE, PREFIX => SNS);
    else
      /* Или без него */
      XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG);
      XNODE := DBMS_XMLDOM.MAKENODE(ELEM => XEL);
    end if;
    /* Значение размещаем в текстовой части ветки */
    if (SVAL is not null) then
      XTEXT := DBMS_XMLDOM.APPENDCHILD(N        => XNODE,
                                       NEWCHILD => DBMS_XMLDOM.MAKENODE(T => DBMS_XMLDOM.CREATETEXTNODE(DOC  => XDOC,
                                                                                                        DATA => SVAL)));
    end if;
    /* Вернем результат */
    return XNODE;
  end UTL_CREATENODE;
      
  /* Считывание значения ветки XML */
  function UTL_GETNODEVAL
  (
    XROOTNODE               in DBMS_XMLDOM.DOMNODE, -- Корневая ветка для считывания значения
    SPATTERN                in varchar2             -- Шаблон для считывания данных
  ) 
  return                    varchar2                -- Считанное значение
  is
    XNODE                   DBMS_XMLDOM.DOMNODE;    -- Искомая ветка со значением (подходящая под шаблон)
    SVAL                    PKG_STD.TSTRING;        -- Результат работы
  begin
    /* Найдем нужную ветку по шаблону */
    XNODE := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XROOTNODE, PATTERN => SPATTERN);
    /* Если там нет ничего */
    if (DBMS_XMLDOM.ISNULL(N => XNODE)) then
      /* Его и вернём */
      return null;
    end if;
    /* Что-то есть - читаем данные */
    SVAL := DBMS_XMLDOM.GETNODEVALUE(DBMS_XMLDOM.GETFIRSTCHILD(N => XNODE));
    /* Отдаём результат */
    return SVAL;
  end UTL_GETNODEVAL;
      
  /* Создание документа для ответа */
  procedure UTL_CREATERESPONSEDOC
  (
    XDOC                    out DBMS_XMLDOM.DOMDOCUMENT -- Буфер для документа
  )
  is
  begin
    /* Создаём новый документ */
    XDOC := DBMS_XMLDOM.NEWDOMDOCUMENT();
    /* Выставляем параметры заголовка */
    DBMS_XMLDOM.SETVERSION(DOC => XDOC, VERSION => '1.0" encoding="UTF-8');
    /* Выставляем кодировку */
    DBMS_XMLDOM.SETCHARSET(DOC => XDOC, CHARSET => 'UTF-8');
  end UTL_CREATERESPONSEDOC;
      
  /* Формировние ответа на запрос из XML-документа (обёртывание в конверт подготовленных данных) */
  function UTL_CREATERESPONSE
  (
    XDOC                    in DBMS_XMLDOM.DOMDOCUMENT, -- Документ
    XCONTENT                in DBMS_XMLDOM.DOMNODE      -- Наименование тэга с отправляемым контентом
  ) return                  clob                        -- Результат работы
  is
    XMAIN_NODE              DBMS_XMLDOM.DOMNODE;        -- Корневой элемент документа
    XENVELOPE_EL            DBMS_XMLDOM.DOMELEMENT;     -- Элемент для обёртки ответа
    XENVELOPE               DBMS_XMLDOM.DOMNODE;        -- Обёртка ответа
    XHEADER                 DBMS_XMLDOM.DOMNODE;        -- Элемент для заголовока ответа
    XBODY                   DBMS_XMLDOM.DOMNODE;        -- Элемент для тела ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;        -- Текущий элемент документа
    CDATA                   clob;                       -- Буфер для результата
  begin
    /* Подготовим документ */
    XMAIN_NODE := DBMS_XMLDOM.MAKENODE(DOC => XDOC);
    /* Обернём его в конверт */
    XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => SENVELOPE, NS => SSOAPENV);
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:soapenv',
                             NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:tsd',
                             NEWVALUE => 'http://www.example.org/TSDService/');
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => XENVELOPE_EL);
    DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SSOAPENV);
    XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
    /* Сформируем заголовок */
    XHEADER := UTL_CREATENODE(XDOC => XDOC, STAG => SHEADER, SNS => SSOAPENV);
    XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
    /* Сформируем тело */
    XBODY := UTL_CREATENODE(XDOC => XDOC, STAG => SBODY, SNS => SSOAPENV);
    XBODY := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XBODY);
    XNODE := DBMS_XMLDOM.APPENDCHILD(N => XBODY, NEWCHILD => XCONTENT);
    /* Конвертируем в CLOB */
    DBMS_LOB.CREATETEMPORARY(LOB_LOC => CDATA, CACHE => true, DUR => DBMS_LOB.SESSION);
    DBMS_XMLDOM.WRITETOCLOB(DOC => XDOC, CL => CDATA, CHARSET => 'UTF-8');
    DBMS_XMLDOM.FREEDOCUMENT(DOC => XDOC);
    /* Вернем результат */
    return CDATA;
  end UTL_CREATERESPONSE;
  
  /* Формирование ответа с ошибкой */
  function UTL_CREATEERRORRESPONSE
  (
    XDOC                    in DBMS_XMLDOM.DOMDOCUMENT, -- Документ
    SMSG                    in varchar2                 -- Сообщение об ошибке
  ) return                  clob                        -- Результат работы     
  is
    XFAULT                  DBMS_XMLDOM.DOMNODE;        --
    XDETAIL                 DBMS_XMLDOM.DOMNODE;        -- 
    XERRMSG                 DBMS_XMLDOM.DOMNODE;        --
    XMSG                    DBMS_XMLDOM.DOMNODE;        --
    XNODE                   DBMS_XMLDOM.DOMNODE;        --
    CDATA                   clob;                       -- Буфер для результата
  begin
    /* Собираем ошибку в ответ */
    XFAULT  := UTL_CREATENODE(XDOC => XDOC, STAG => SFAULT, SNS => SSOAPENV);
    XDETAIL := UTL_CREATENODE(XDOC => XDOC, STAG => SDETAIL);
    XERRMSG := UTL_CREATENODE(XDOC => XDOC, STAG => SERRORMESSAGE, SNS => STSD);
    XMSG    := UTL_CREATENODE(XDOC => XDOC, STAG => SMESSAGE, SNS => STSD, SVAL => SMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XDETAIL, NEWCHILD => XERRMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XFAULT, NEWCHILD => XDETAIL);
    CDATA   := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XFAULT);
    /* Возвращаем результат */
    return CDATA;
  end UTL_CREATEERRORRESPONSE;
  
  
  /* Считывание значения структурного элемента из иерархии адреса географического понятия */
  function UTL_GEOGRAFY_GET_HIER_ITEM
  (
    NGEOGRAFY               in number,       -- Регистрационный номер географического понятия
    NGEOGRTYPE              in number        -- Тип искомого структурного элемента адреса (1 - страна, 2 - регион, 3 - район, 4 - населенный пункт, 5 - улица, 6 - административный округ, 7 - муниципальный округ, 8 - город, 9 - уровень внутригородской территории, 10 - уровень дополнительных территорий, 11 - уровень подчиненных дополнительным территориям объектов)
  ) return                  varchar2         -- Наименование найденного стуктурного элемента адреса
  is
    SRES                    PKG_STD.TSTRING; -- Результат работы
  begin
    /* Обходим адрес снизу вверх */
    for REC in (select G.GEOGRNAME,
                       G.GEOGRTYPE
                  from GEOGRAFY G
                connect by prior G.PRN = G.RN
                 start with G.RN = NGEOGRAFY)
    loop
      if (REC.GEOGRTYPE = NGEOGRTYPE) then
        SRES := REC.GEOGRNAME;
        exit;
      end if;
    end loop;
    /* Вернём результат */
    return SRES;
  end UTL_GEOGRAFY_GET_HIER_ITEM;

  /* Электронная инвентаризация - аутентификация */
  procedure CHECKAUTH
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XCHECKAUTHRESPONSE      DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XRESULT                 DBMS_XMLDOM.DOMNODE;     -- Результат аутентификации
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      /* Т.к. пока проверок нет никаких - всегда возвращаем положительный ответ */
      XCHECKAUTHRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SCHECKAUTHRESPONSE, SNS => STSD);
      XRESULT            := UTL_CREATENODE(XDOC => XDOC, STAG => SRESULT, SNS => STSD, SVAL => 'true');
      XNODE              := DBMS_XMLDOM.APPENDCHILD(N => XCHECKAUTHRESPONSE, NEWCHILD => XRESULT);
      /* Оборачиваем его в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XCHECKAUTHRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end CHECKAUTH;

  /* Электронная инвентаризация - считывание пользователей */
  procedure GETUSERS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XGETUSERSRESPONSE       DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- Код элемента ответного списка
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- Нименование элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      /* Создаём пространство имён для ответа */
      XGETUSERSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETUSERSRESPONSE, SNS => STSD);
      /* Обходим сотрудников-инвентаризаторов */
      for REC in (select T.RN,
                         A.AGNABBR
                    from INVPERSONS T,
                         AGNLIST    A
                   where T.COMPANY = 136018
                     and T.AGNLIST = A.RN)
      loop
        /* Собираем информацию по сотруднику в ответ */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => SNAME, SNS => STSD, SVAL => REC.AGNABBR);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETUSERSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETUSERSRESPONSE);
    end if;   
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETUSERS;

  /* Электронная инвентаризация - считывание типов ведомостей */
  procedure GETSHEETTYPES
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XGETSHEETTYPESRESPONSE  DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- Код элемента ответного списка
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- Нименование элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      /* Создаём пространство имён для ответа */
      XGETSHEETTYPESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSHEETTYPESRESPONSE, SNS => STSD);
      /* Обходим типы документов связанные с разделом "Электронные инвентаризации" */
      for REC in (select T.RN,
                         T.DOCCODE
                    from DOCTYPES    T,
                         COMPVERLIST CV
                   where T.VERSION = CV.VERSION
                     and CV.COMPANY = 136018
                     and T.RN in (select DOCRN from DOCPARAMS where DOCPARAMS.UNITCODE = 'ElectronicInventories')
                   order by T.DOCCODE)
      loop
        /* Собираем информацию по типу документа в ответ */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => SNAME, SNS => STSD, SVAL => REC.DOCCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETTYPESRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETTYPESRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETTYPES;
  
  /* Электронная инвентаризация - считывание заголовков ведомостей инвентаризации */
  procedure GETSHEETS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XGETSHEETSRESPONSE      DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- Код элемента ответного списка
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- Нименование элемента ответного списка
    XTYPECODE               DBMS_XMLDOM.DOMNODE;     -- Тип ведомости элемента ответного списка
    XPREFIX                 DBMS_XMLDOM.DOMNODE;     -- Префикс ведомости элемента ответного списка
    XNUMBER                 DBMS_XMLDOM.DOMNODE;     -- Номер ведомости элемента ответного списка
    XDATE                   DBMS_XMLDOM.DOMNODE;     -- Дата ведомости элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQTYPECODE            PKG_STD.TREF;            -- Тип ведомости из запроса (параметр отбора)
    SREQPREFIX              PKG_STD.TSTRING;         -- Префикс ведомости из запроса (параметр отбора)
    SREQNUMBER              PKG_STD.TSTRING;         -- Номер ведомости из запроса (параметр отбора)
    DREQDATE                PKG_STD.TLDATE;          -- Дата ведомости из запроса (параметр отбора)
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);  
    /* Считываем "Тип ведомости" (параметр отбора) */
    NREQTYPECODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STYPECODE));
    /* Считываем "Префикс" (параметр отбора) */
    SREQPREFIX := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SPREFIX);
    /* Считываем "Номер" (параметр отбора) */
    SREQNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SNUMBER);
    /* Считываем "Дату" (параметр отбора) */
    DREQDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDATE), 'yyyy-mm-dd');
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      /* Создаём пространство имён для ответа */
      XGETSHEETSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSHEETSRESPONSE, SNS => STSD);
      /* Обходим записи раздела "Электронные инвентаризации" удовлетворяющие условиям отбора */
      for REC in (select T.RN,
                         T.DOC_TYPE,
                         DT.DOCCODE as DOC_TYPE_CODE,
                         trim(T.DOC_PREF) as DOC_PREF,
                         trim(T.DOC_NUMB) as DOC_NUMB,
                         T.DOC_DATE
                    from ELINVENTORY T,
                         DOCTYPES    DT
                   where T.COMPANY = 136018
                     and T.DOC_TYPE = DT.RN
                     and (NREQTYPECODE is null or (NREQTYPECODE is not null and T.DOC_TYPE = NREQTYPECODE))
                     and (SREQPREFIX is null or (SREQPREFIX is not null and trim(T.DOC_PREF) = SREQPREFIX))
                     and (SREQNUMBER is null or (SREQNUMBER is not null and trim(T.DOC_NUMB) = SREQNUMBER))
                     and (DREQDATE is null or (DREQDATE is not null and T.DOC_DATE = DREQDATE)))
      loop
        /* Собираем информацию по ведомости в ответ */
        XITEM     := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE     := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.RN);
        XNAME     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => SNAME,
                                    SNS  => STSD,
                                    SVAL => REC.DOC_TYPE_CODE || ', ' || REC.DOC_PREF || '-' || REC.DOC_NUMB || ', ' ||
                                            TO_CHAR(REC.DOC_DATE, 'dd.mm.yyyy'));
        XTYPECODE := UTL_CREATENODE(XDOC => XDOC, STAG => STYPECODE, SNS => STSD, SVAL => REC.DOC_TYPE);
        XPREFIX   := UTL_CREATENODE(XDOC => XDOC, STAG => SPREFIX, SNS => STSD, SVAL => REC.DOC_PREF);
        XNUMBER   := UTL_CREATENODE(XDOC => XDOC, STAG => SNUMBER, SNS => STSD, SVAL => REC.DOC_NUMB);
        XDATE     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => SDATE,
                                    SNS  => STSD,
                                    SVAL => TO_CHAR(REC.DOC_DATE, 'yyyy-mm-dd'));
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XTYPECODE);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XPREFIX);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNUMBER);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XDATE);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETSRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETS;
  
  /* Электронная инвентаризация - считывание состава ведомостей инвентаризации */
  procedure GETSHEETITEMS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XGETSHEETITEMSRESPONSE  DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XSTORAGEMNEMOCODE       DBMS_XMLDOM.DOMNODE;     -- Мнемокод местоположения для элемента ответного списка
    XUSERCODE               DBMS_XMLDOM.DOMNODE;     -- МОЛ для элемента ответного списка
    XITEMCODE               DBMS_XMLDOM.DOMNODE;     -- Идентификатор ОС для элемента ответного списка
    XITEMNAME               DBMS_XMLDOM.DOMNODE;     -- Наименование ОС для элемента ответного списка
    XITEMMNEMOCODE          DBMS_XMLDOM.DOMNODE;     -- Код ОС для элемента ответного списка
    XITEMNUMBER             DBMS_XMLDOM.DOMNODE;     -- Номер ОС для элемента ответного списка
    XQUANTITY               DBMS_XMLDOM.DOMNODE;     -- Количество ОС для элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQSHEETCODE           PKG_STD.TREF;            -- Ведомость из запроса (параметр отбора)
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* Считываем "Регистрационный номер ведомости" (параметр отбора) */
    NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSHEETCODE));
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      /* Создаём пространство имён для ответа */
      XGETSHEETITEMSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSHEETITEMSRESPONSE, SNS => STSD);
      /* Обходим типы документов связанные с разделом "Электронные инвентаризации" */
      for REC in (select DECODE(T.INVPACK, null, O.PLACE_MNEMO, OP.PLACE_MNEMO) SSTORAGEMNEMOCODE,
                         DECODE(T.INVPACK, null, O.BARCODE, OP.BARCODE) SOBARCODE,
                         T.INVPERSONS NINVPERSONS,
                         DECODE(PS.RN,
                                null,
                                DECODE(T.INVPACK, null, DECODE(T.INVSUBST, null, I.BARCODE, U.BARCODE), P.BARCODE),
                                PS.BARCODE) SIBARCODE,
                         N1.NOMEN_CODE SNOM_CODE,
                         N1.NOMEN_NAME SNOM_NAME,
                         I.INV_NUMBER SINV_NUMBER,
                         '1' SQUANTITY
                    from ELINVOBJECT T,
                         INVENTORY   I,
                         DICPLACE    O,
                         DICPLACE    OP,
                         INVPACK     P,
                         INVPACKPOS  PS,
                         INVSUBST    U,
                         DICNOMNS    N1
                   where T.COMPANY = 136018
                     and T.PRN = NREQSHEETCODE
                     and T.INVENTORY = I.RN
                     and I.OBJECT_PLACE = O.RN(+)
                     and T.INVPACK = P.RN(+)
                     and P.OBJECT_PLACE = OP.RN(+)
                     and T.INVPACK = PS.PRN(+)
                     and T.INVSUBST = PS.INVSUBST(+)
                     and T.INVSUBST = U.RN(+)
                     and I.NOMENCLATURE = N1.RN)
      loop
        /* Собираем информацию по элементам ведомости в ответ */
        XITEM             := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XSTORAGEMNEMOCODE := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => SSTORAGEMNEMOCODE,
                                            SNS  => STSD,
                                            SVAL => REC.SSTORAGEMNEMOCODE);
        XUSERCODE         := UTL_CREATENODE(XDOC => XDOC, STAG => SUSERCODE, SNS => STSD, SVAL => trim(REC.NINVPERSONS));
        XITEMCODE         := UTL_CREATENODE(XDOC => XDOC, STAG => SITEMCODE, SNS => STSD, SVAL => trim(REC.SIBARCODE));
        XITEMNAME         := UTL_CREATENODE(XDOC => XDOC, STAG => SITEMNAME, SNS => STSD, SVAL => trim(REC.SNOM_NAME));
        XITEMMNEMOCODE    := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => SITEMMNEMOCODE,
                                            SNS  => STSD,
                                            SVAL => trim(REC.SNOM_CODE));
        XITEMNUMBER       := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => SITEMNUMBER,
                                            SNS  => STSD,
                                            SVAL => trim(REC.SINV_NUMBER));
        XQUANTITY         := UTL_CREATENODE(XDOC => XDOC, STAG => SQUANTITY, SNS => STSD, SVAL => REC.SQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XSTORAGEMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XUSERCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNAME);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNUMBER);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETITEMSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETITEMSRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETITEMS;
  
  /* Электронная инвентаризация - считывание мест хранения */
  procedure GETSTORAGES
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XGETSTORAGESRESPONSE    DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- Код элемента ответного списка
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- Нименование элемента ответного списка
    XMNEMOCODE              DBMS_XMLDOM.DOMNODE;     -- Мнемокод местоположения для элемента ответного списка
    XLATITUDE               DBMS_XMLDOM.DOMNODE;     -- Широта местоположения для элемента ответного списка
    XLONGITUDE              DBMS_XMLDOM.DOMNODE;     -- Долгота местоположения для элемента ответного списка
    XPOSTCODE               DBMS_XMLDOM.DOMNODE;     -- Почтовый индекс местоположения для элемента ответного списка
    XCOUNTRY                DBMS_XMLDOM.DOMNODE;     -- Страна местоположения для элемента ответного списка
    XREGION                 DBMS_XMLDOM.DOMNODE;     -- Регион местоположения для элемента ответного списка
    XLOCALITY               DBMS_XMLDOM.DOMNODE;     -- Населённый пункт местоположения для элемента ответного списка
    XSTREET                 DBMS_XMLDOM.DOMNODE;     -- Улица местоположения для элемента ответного списка
    XHOUSENUMBER            DBMS_XMLDOM.DOMNODE;     -- Номер дома местоположения для элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQSHEETCODE           PKG_STD.TREF;            -- Ведомость из запроса (параметр отбора)
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* Считываем "Регистрационный номер ведомости" (параметр отбора) */
    NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSHEETCODE));
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      /* Создаём пространство имён для ответа */
      XGETSTORAGESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSTORAGESRESPONSE, SNS => STSD);
      /* Обходим места хранения */
      for REC in (select T.RN NRN,
                         T.PLACE_MNEMO SMNEMOCODE,
                         T.PLACE_NAME SNAME,
                         UDO_F_GET_DOC_PROP_VAL_STR('LATITUDE', 'ObjPlace', T.RN) SLATITUDE,
                         UDO_F_GET_DOC_PROP_VAL_STR('LONGITUDE', 'ObjPlace', T.RN) SLONGITUDE,
                         nvl(T.ADDR_POST, G.POSTAL_CODE) SPOSTCODE,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 1) SCOUNTRY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2) SREGION,
                         NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 8),
                             NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 4),
                                 NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 3), UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2)))) SLOCALITY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 5) SSTREET,
                         T.ADDR_HOUSE SHOUSENUMBER
                    from DICPLACE T,
                         GEOGRAFY G
                   where T.COMPANY = 136018
                     and T.GEOGRAFY = G.RN(+)
                     and ((NREQSHEETCODE is null) or
                         ((NREQSHEETCODE is not null) and
                         (T.RN in (select DECODE(EO.INVPACK, null, INV.OBJECT_PLACE, P.OBJECT_PLACE)
                                       from ELINVOBJECT EO,
                                            INVENTORY   INV,
                                            INVPACK     P
                                      where EO.PRN = NREQSHEETCODE
                                        and EO.INVENTORY = INV.RN
                                        and EO.INVPACK = P.RN(+))))))
      loop
        /* Собираем информацию по месту хранения в ответ */
        XITEM        := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE        := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.NRN);
        XNAME        := UTL_CREATENODE(XDOC => XDOC, STAG => SNAME, SNS => STSD, SVAL => REC.SNAME);
        XMNEMOCODE   := UTL_CREATENODE(XDOC => XDOC, STAG => SMNEMOCODE, SNS => STSD, SVAL => REC.SMNEMOCODE);
        XLATITUDE    := UTL_CREATENODE(XDOC => XDOC, STAG => SLATITUDE, SNS => STSD, SVAL => REC.SLATITUDE);
        XLONGITUDE   := UTL_CREATENODE(XDOC => XDOC, STAG => SLONGITUDE, SNS => STSD, SVAL => REC.SLONGITUDE);
        XPOSTCODE    := UTL_CREATENODE(XDOC => XDOC, STAG => SPOSTCODE, SNS => STSD, SVAL => REC.SPOSTCODE);
        XCOUNTRY     := UTL_CREATENODE(XDOC => XDOC, STAG => SCOUNTRY, SNS => STSD, SVAL => REC.SCOUNTRY);
        XREGION      := UTL_CREATENODE(XDOC => XDOC, STAG => SREGION, SNS => STSD, SVAL => REC.SREGION);
        XLOCALITY    := UTL_CREATENODE(XDOC => XDOC, STAG => SLOCALITY, SNS => STSD, SVAL => REC.SLOCALITY);
        XSTREET      := UTL_CREATENODE(XDOC => XDOC, STAG => SSTREET, SNS => STSD, SVAL => REC.SSTREET);
        XHOUSENUMBER := UTL_CREATENODE(XDOC => XDOC, STAG => SHOUSENUMBER, SNS => STSD, SVAL => REC.SHOUSENUMBER);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XMNEMOCODE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XLATITUDE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XLONGITUDE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XPOSTCODE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCOUNTRY);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XREGION);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XLOCALITY);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XSTREET);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XHOUSENUMBER);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XGETSTORAGESRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSTORAGESRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSTORAGES;

  /* Электронная инвентаризация - сохранение результатов инвентаризации */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XSAVESHEETITEMRESPONSE  DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    CREQ                    clob;                    -- Буфер для запроса
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQSHEETCODE           PKG_STD.TREF;            -- Ведомость из запроса (параметр сохранения)
    NREQUSERCODE            PKG_STD.TREF;            -- Регистрационный номер МОЛ из запроса (параметр сохранения)
    SREQSTORAGEMNEMOCODE    PKG_STD.TSTRING;         -- Мнемокод места хранения из запроса (параметр сохранения)
    NREQSTORAGEISNEW        PKG_STD.TNUMBER;         -- Признак нового места хранения из запроса (параметр сохранения)    
    SREQSTORAGECODE         PKG_STD.TSTRING;         -- Штрих-код места хранения из запроса (параметр сохранения)
    SREQSTORAGENAME         PKG_STD.TSTRING;         -- Наименование места хранения из запроса (параметр сохранения)
    SREQSTORAGEPOSTCODE     PKG_STD.TSTRING;         -- Почтовый индекс места хранения из запроса (параметр сохранения)    
    SREQSTORAGECOUNTRY      PKG_STD.TSTRING;         -- Страна места хранения из запроса (параметр сохранения)    
    SREQSTORAGEREGION       PKG_STD.TSTRING;         -- Регион места хранения из запроса (параметр сохранения)    
    SREQSTORAGELOCALITY     PKG_STD.TSTRING;         -- Населенный пункт места хранения из запроса (параметр сохранения)    
    SREQSTORAGESTREET       PKG_STD.TSTRING;         -- Улица места хранения из запроса (параметр сохранения)    
    SREQSTORAGEHOUSENUMBER  PKG_STD.TSTRING;         -- Номер дома места хранения из запроса (параметр сохранения)    
    NREQSTORAGELATITUDE     PKG_STD.TLNUMBER;        -- Широта места хранения из запроса (параметр сохранения)    
    NREQSTORAGELONGITUDE    PKG_STD.TLNUMBER;        -- Долгота места хранения из запроса (параметр сохранения) 
    SREQITEMCODE            PKG_STD.TSTRING;         -- Штрих-код ОС из запроса (параметр сохранения)  
    SREQITEMNAME            PKG_STD.TSTRING;         -- Наименование номенклатуры ОС из запроса (параметр сохранения)
    SREQITEMMNEMOCODE       PKG_STD.TSTRING;         -- Мнемокод номенклатуры ОС из запроса (параметр сохранения)
    SREQITEMNUMBER          PKG_STD.TSTRING;         -- Инвентарный номер ОС из запроса (параметр сохранения)
    NREQQUANTITY            PKG_STD.TQUANT;          -- Количество ОС из запроса (параметр сохранения)    
    DREQCHECKDATE           PKG_STD.TLDATE;          -- Дата проведения инвентаризации ОС из запроса (параметр сохранения)  
    SREQCOMMENT             PKG_STD.TLSTRING;        -- Комментарий МОЛ ОС из запроса (параметр сохранения)
    NREQLATITUDE            PKG_STD.TLNUMBER;        -- Широта из запроса (параметр сохранения) 
    NREQLONGITUDE           PKG_STD.TLNUMBER;        -- Долгота из запроса (параметр сохранения)    
    NREQDISTANCETOSTORAGE   PKG_STD.TLNUMBER;        -- Расстояние до места хранения ОС из запроса (параметр сохранения)    
    SREQFLOOR               PKG_STD.TSTRING;         -- Этаж расположения ОС из запроса (параметр сохранения)
    SREQROOM                PKG_STD.TSTRING;         -- Помещение расположения ОС из запроса (параметр сохранения)
    SREQRACK                PKG_STD.TSTRING;         -- Стеллаж расположения ОС из запроса (параметр сохранения)
    NELINVOBJECT            PKG_STD.TREF;            -- Рег. номер позиции ведомости инвентаризации
    NDICPLACE               PKG_STD.TREF;            -- Рег. номер места хранения
    NINVENTORY              PKG_STD.TREF;            -- Рег. номер ОС (карточки "Инвентарной картотеки")
    NCOMPANY                PKG_STD.TREF;            -- Рег. номер организации
    SERR                    PKG_STD.TSTRING;         -- Буфер для ошибок
  begin
    /* Инициализируем организацию */
    NCOMPANY := 136018;
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Возьмем текст запроса */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Создаем инстанс XML парсера */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* Разбираем XML из запроса */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* Берем XML документ из разобранного */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* Считываем корневой элемент */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* Считываем элемент тело */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* Считываем идентификатор устройства */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* Считываем "Регистрационный номер ведомости" (параметр сохранения) */
    NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSHEETCODE));
    /* Считываем "Регистрационный номер МОЛ" (параметр сохранения) */
    NREQUSERCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SUSERCODE));
    /* Считываем "Мнемокод места хранения" (параметр сохранения) */
    SREQSTORAGEMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEMNEMOCODE);
    /* Считываем "Признак нового места хранения" (параметр сохранения) */
    NREQSTORAGEISNEW := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEISNEW));
    /* Считываем "Штрих-код места хранения" (параметр сохранения) */
    SREQSTORAGECODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGECODE);
    /* Считываем "Наименование места хранения" (параметр сохранения) */
    SREQSTORAGENAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGENAME);
    /* Считываем "Почтовый индекс места хранения" (параметр сохранения) */
    SREQSTORAGEPOSTCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEPOSTCODE);
    /* Считываем "Страна места хранения" (параметр сохранения) */
    SREQSTORAGECOUNTRY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGECOUNTRY);
    /* Считываем "Регион места хранения" (параметр сохранения) */
    SREQSTORAGEREGION := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEREGION);
    /* Считываем "Населенный пункт места хранения" (параметр сохранения) */
    SREQSTORAGELOCALITY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGELOCALITY);
    /* Считываем "Улица места хранения" (параметр сохранения) */
    SREQSTORAGESTREET := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGESTREET);
    /* Считываем "Номер дома места хранения" (параметр сохранения) */
    SREQSTORAGEHOUSENUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEHOUSENUMBER);
    /* Считываем "Широта места хранения" (параметр сохранения) */
    NREQSTORAGELATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGELATITUDE));
    /* Считываем "Долгота места хранения" (параметр сохранения) */
    NREQSTORAGELONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGELONGITUDE));
    /* Считываем "Штрих-код ОС" (параметр сохранения) */
    SREQITEMCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMCODE);
    /* Считываем "Наименование номенклатуры ОС" (параметр сохранения) */
    SREQITEMNAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMNAME);
    /* Считываем "Мнемокод номенклатуры ОС" (параметр сохранения) */
    SREQITEMMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMMNEMOCODE);
    /* Считываем "Инвентарный номер ОС" (параметр сохранения) */
    SREQITEMNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMNUMBER);
    /* Считываем "Количество ОС" (параметр сохранения) */
    NREQQUANTITY := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SQUANTITY));
    /* Считываем "Дата проведения инвентаризации ОС" (параметр сохранения) */
    DREQCHECKDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SCHECKDATE), 'yyyy-mm-dd');
    /* Считываем "Комментарий МОЛ ОС" (параметр сохранения) */
    SREQCOMMENT := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SCOMMENT);
    /* Считываем "Широта" (параметр сохранения) */
    NREQLATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SLATITUDE));
    /* Считываем "Долгота" (параметр сохранения) */
    NREQLONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SLONGITUDE));
    /* Считываем "Расстояние до места хранения ОС" (параметр сохранения) */
    NREQDISTANCETOSTORAGE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDISTANCETOSTORAGE));
    /* Считываем "Этаж расположения ОС" (параметр сохранения) */
    SREQFLOOR := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SFLOOR);
    /* Считываем "Помещение расположения ОС" (параметр сохранения) */
    SREQROOM := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SROOM);
    /* Считываем "Стеллаж расположения ОС" (параметр сохранения) */
    SREQRACK := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SRACK);
    /* Контроль индетификатора устройства по лицензии */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* Подготавливаем документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Вместо проверки по лицензии - пока просто проверка на то, что идентификатор устройства был передан */
    if (SREQDEVICEID is not null) then
      if ((NREQSHEETCODE is not null) and (DREQCHECKDATE is not null)) then
        /*
        TODO: owner="root" created="14.01.2019"
        text="Понять зачем мы это делаем (дальше результаты проверки не идут).
              Надо реализовать добавление нового местонахождения + смену текущего"
        */
        /* Если задан штрих-код местанхождения ОС */
        if (SREQSTORAGECODE is not null) then
          /* Проверяем местонахохждение по штрих-коду */
          begin
            select T.RN
              into NDICPLACE
              from DICPLACE T
             where T.COMPANY = NCOMPANY
               and T.BARCODE = SREQSTORAGECODE;
          exception
            when NO_DATA_FOUND then
              SERR := 'Местонахождение инвентарных объектов с штрих-кодом: ' || SREQSTORAGECODE || ' не найдено';
          end;
        end if;
        /* Пробуем найти позицию ведомости инвентаризации по штрих-коду (если передан рег. номер ведомости и пока нет ошибок) */
        if ((NREQSHEETCODE is not null) and (SERR is null)) then
          begin
            select T.NRN
              into NELINVOBJECT
              from V_ELINVOBJECT T
             where T.NCOMPANY = NCOMPANY
               and T.NPRN = NREQSHEETCODE
               and T.SIBARCODE = SREQITEMCODE;
          exception
            when NO_DATA_FOUND then
              /* Ищем рег. номер ИК по штрихкоду, если не нашли позицию ведомости инвентаризации */
              begin
                select T.RN
                  into NINVENTORY
                  from INVENTORY T
                 where T.BARCODE = SREQITEMCODE
                   and T.COMPANY = NCOMPANY;
              exception
                when NO_DATA_FOUND then
                  SERR := 'Инвентарная карточка с штрих-кодом: ' || SREQITEMCODE || ' не найдена';
              end;
          end;
        end if;
        /* Если нет ошибок при проверках */
        if (SERR is null) then
          /* Если позиция ведомости инвентаризации найдена */
          if (NELINVOBJECT is not null) then
            /* Обновим её */
            P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => NCOMPANY,
                                      NRN          => NELINVOBJECT,
                                      DUNLOAD_DATE => null,
                                      DINV_DATE    => DREQCHECKDATE,
                                      NINVPERSONS  => NREQUSERCODE,
                                      SBARCODE     => SREQSTORAGECODE,
                                      NIS_LOADED   => 0);
          else
            /* Или добавим в ведомость найденную ИК если не нашли позицию ведомости по штрих-коду */
            P_ELINVOBJECT_BASE_INSERT(NCOMPANY     => NCOMPANY,
                                      NPRN         => NREQSHEETCODE,
                                      NINVENTORY   => NINVENTORY,
                                      NINVSUBST    => null,
                                      NINVPACK     => null,
                                      DUNLOAD_DATE => null,
                                      DINV_DATE    => DREQCHECKDATE,
                                      NINVPERSONS  => NREQUSERCODE,
                                      SBARCODE     => SREQSTORAGECODE,
                                      NIS_LOADED   => 1,
                                      NRN          => NELINVOBJECT);
          end if;
        end if;
      end if;
      /* Если нет ошибок */
      if (SERR is null) then
        /* Создаём пространство имён для ответа */
        XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SSAVESHEETITEMRESPONSE, SNS => STSD);
        /* Формируем результат */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SRESULT, SNS => STSD, SVAL => 'true');
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
        /* Оборачиваем ответ в конверт */
        CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
      else
        CRESPONSE := UTL_CREATEERRORRESPONSE(XDOC => XDOC, SMSG => SERR);
      end if;
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end SAVESHEETITEM;
  
  /* Электронная инвентаризация - сохранение результатов инвентаризации (ДЕМО, убрать!!!!) */
  procedure SAVESHEETITEM_TMP
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    CRESPONSE               clob;                    -- Буфер для ответа
    XSAVESHEETITEMRESPONSE  DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
  begin
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Создаём пространство имён для ответа */
    XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SSAVESHEETITEMRESPONSE, SNS => STSD);
    /* Формируем результат */
    XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SRESULT, SNS => STSD, SVAL => 'true');
    XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
    /* Оборачиваем ответ в конверт */
    CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end SAVESHEETITEM_TMP;

end;
/
