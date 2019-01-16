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
  
end;
/
create or replace package body UDO_PKG_EXS_INV as

  /* Константы - пространства имён */
  SNS_TSD                   constant varchar2(40) := 'tsd';
  SNS_SOAPENV               constant varchar2(40) := 'soapenv';
  
  /* Константы - тэги */
  STAG_CHECKAUTHRSPNS       constant varchar2(40) := 'CheckAuthResponse';
  STAG_GETUSERSRSPNS        constant varchar2(40) := 'GetUsersResponse';
  STAG_GETSHEETTYPESRSPNS   constant varchar2(40) := 'GetSheetTypesResponse';
  STAG_GETSHEETSRSPNS       constant varchar2(40) := 'GetSheetsResponse';
  STAG_GETSTORAGESRSPNS     constant varchar2(40) := 'GetStoragesResponse';
  STAG_GETSHEETITEMSRSPNS   constant varchar2(40) := 'GetSheetItemsResponse';
  STAG_SAVESHEETITEMRSPNS   constant varchar2(40) := 'SaveSheetItemResponse';
  STAG_DEVICEID             constant varchar2(40) := 'DeviceID';
  STAG_RESULT               constant varchar2(40) := 'Result';
  STAG_ENVELOPE             constant varchar2(40) := 'Envelope';
  STAG_HEADER               constant varchar2(40) := 'Header';
  STAG_BODY                 constant varchar2(40) := 'Body';
  STAG_ITEM                 constant varchar2(40) := 'Item';
  STAG_CODE                 constant varchar2(40) := 'Code'; 
  STAG_NAME                 constant varchar2(40) := 'Name';
  STAG_TYPECODE             constant varchar2(40) := 'TypeCode';
  STAG_PREFIX               constant varchar2(40) := 'Prefix';
  STAG_NUMBER               constant varchar2(40) := 'Number';
  STAG_DATE                 constant varchar2(40) := 'Date';
  STAG_SHEETCODE            constant varchar2(40) := 'SheetCode';
  STAG_MNEMOCODE            constant varchar2(40) := 'MnemoCode';
  STAG_LATITUDE             constant varchar2(40) := 'Latitude';
  STAG_LONGITUDE            constant varchar2(40) := 'Longitude';
  STAG_POSTCODE             constant varchar2(40) := 'Postcode';
  STAG_COUNTRY              constant varchar2(40) := 'Country';
  STAG_REGION               constant varchar2(40) := 'Region';
  STAG_LOCALITY             constant varchar2(40) := 'Locality';
  STAG_STREET               constant varchar2(40) := 'Street';
  STAG_HOUSENUMBER          constant varchar2(40) := 'HouseNumber';
  STAG_STORAGEMNEMOCODE     constant varchar2(40) := 'StorageMnemoCode';
  STAG_USERCODE             constant varchar2(40) := 'UserCode';
  STAG_ITEMCODE             constant varchar2(40) := 'ItemCode';
  STAG_ITEMNAME             constant varchar2(40) := 'ItemName';
  STAG_ITEMMNEMOCODE        constant varchar2(40) := 'ItemMnemoCode';
  STAG_ITEMNUMBER           constant varchar2(40) := 'ItemNumber';
  STAG_QUANTITY             constant varchar2(40) := 'Quantity';
  STAG_STORAGEISNEW         constant varchar2(40) := 'StorageIsNew';
  STAG_STORAGECODE          constant varchar2(40) := 'StorageCode';
  STAG_STORAGENAME          constant varchar2(40) := 'StorageName';
  STAG_STORAGEPOSTCODE      constant varchar2(40) := 'StoragePostcode';
  STAG_STORAGECOUNTRY       constant varchar2(40) := 'StorageCountry';
  STAG_STORAGEREGION        constant varchar2(40) := 'StorageRegion';
  STAG_STORAGELOCALITY      constant varchar2(40) := 'StorageLocality';
  STAG_STORAGESTREET        constant varchar2(40) := 'StorageStreet';
  STAG_STORAGEHOUSENUMBER   constant varchar2(40) := 'StorageHouseNumber';
  STAG_STORAGELATITUDE      constant varchar2(40) := 'StorageLatitude';
  STAG_STORAGELONGITUDE     constant varchar2(40) := 'StorageLongitude';
  STAG_CHECKDATE            constant varchar2(40) := 'CheckDate';
  STAG_COMMENT              constant varchar2(40) := 'Comment';
  STAG_DISTANCETOSTORAGE    constant varchar2(40) := 'DistanceToStorage';
  STAG_FLOOR                constant varchar2(40) := 'Floor';
  STAG_ROOM                 constant varchar2(40) := 'Room';
  STAG_RACK                 constant varchar2(40) := 'Rack'; 
  STAG_FAULT                constant varchar2(40) := 'Fault';
  STAG_DETAIL               constant varchar2(40) := 'detail';
  STAG_MESSAGE              constant varchar2(40) := 'Message';
  STAG_ERRORMESSAGE         constant varchar2(40) := 'ErrorMessage';
   
  /* Нормализация сообщения об ошибке */
  function UTL_CORRECT_ERR
  (
    SERR                    varchar2          -- Сообщение об ошибке
  ) return                  varchar2          -- Нормализованное сообщение об ошибке
  is
    STMP                    PKG_STD.TSTRING;  -- Буфер для обработки
    SRES                    PKG_STD.TSTRING;  -- Результат работы
    NB                      PKG_STD.TLNUMBER; -- Позиция начала удаляемой подстроки
    NE                      PKG_STD.TLNUMBER; -- Позиция окончания удаляемой подстроки
  begin
    /* Инициализируем буфер */
    STMP := SERR;
    /* Удаляем лишние спецсимволы и техническую информацию из ошибки */
    begin
      while (INSTR(STMP, 'ORA') <> 0)
      loop
        NB   := INSTR(STMP, 'ORA');
        NE   := INSTR(STMP, ':', NB);
        STMP := trim(replace(STMP, trim(SUBSTR(STMP, NB, NE - NB + 1)), ''));
      end loop;
      SRES := STMP;
    exception
      when others then
        SRES := SERR;
    end;
    /* Возвращаем резульат */
    return SRES;
  end UTL_CORRECT_ERR;
  
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
    XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG_ENVELOPE, NS => SNS_SOAPENV);
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:soapenv',
                             NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:tsd',
                             NEWVALUE => 'http://www.example.org/TSDService/');
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => XENVELOPE_EL);
    DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SNS_SOAPENV);
    XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
    /* Сформируем заголовок */
    XHEADER := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_HEADER, SNS => SNS_SOAPENV);
    XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
    /* Сформируем тело */
    XBODY := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_BODY, SNS => SNS_SOAPENV);
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
    SMSG                    in varchar2              -- Сообщение об ошибке
  ) return                  clob                     -- Результат работы     
  is
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XFAULT                  DBMS_XMLDOM.DOMNODE;     -- Корневой узел
    XDETAIL                 DBMS_XMLDOM.DOMNODE;     -- Узел для детализации ошибки
    XERRMSG                 DBMS_XMLDOM.DOMNODE;     -- Узел с сообщением об ошибке
    XMSG                    DBMS_XMLDOM.DOMNODE;     -- Узел текстом сообщения
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для узла
    CDATA                   clob;                    -- Буфер для результата
  begin
    /* Создаём документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Собираем ошибку в ответ */
    XFAULT  := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_FAULT, SNS => SNS_SOAPENV);
    XDETAIL := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_DETAIL);
    XERRMSG := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ERRORMESSAGE, SNS => SNS_TSD);
    XMSG    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_MESSAGE, SNS => SNS_TSD, SVAL => SMSG);
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
  
  /* Проверка идентификатора устройства */
  procedure UTL_CHECK_DEVICEID
  (
    SDEVICEID               in varchar2                 -- Идентификатор устройства
  )
  is
    SLIC_DEVICEIDS          LICCTRLSPEC.SERIAL_NO%type; -- Список идентификаторов устройств в лицензии
  begin
    /* Считаем идентификаторы устройств из лицензии */
    begin
      select LS.SERIAL_NO
        into SLIC_DEVICEIDS
        from LICCTRL     L,
             LICCTRLSPEC LS
       where L.LICENSE_TYPE = 0
         and L.RN = LS.PRN
         and LS.APPLICATION = 'Account'
         and ROWNUM <= 1;
    exception
      when NO_DATA_FOUND then
        SLIC_DEVICEIDS := null;
    end;
    /* Если в составе лицензии нет переданного идентификатора */
    if (SLIC_DEVICEIDS like '%' || SDEVICEID || '%') then
      /*
      TODO: owner="mikha" created="16.01.2019"
      text="Включить при отгрузке в релиз"
      */
      null;
      /* Скажем об этом */
      /*P_EXCEPTION(0,
                  'Идентификатор устровйства "%s" не определён в лицензии.',
                  SDEVICEID);*/
    end if;
  end UTL_CHECK_DEVICEID;
  
  /* Получение корневого элемента тела из сообщения очереди обмена */
  procedure UTL_EXSQUEUE_MSG_GET_BODY_ROOT
  (
    NEXSQUEUE               in number,               -- Регистрационный номер обрабатываемой позиции очереди обмена
    XNODE_ROOT              out DBMS_XMLDOM.DOMNODE  -- Корневой элемент первой ветки тела документа
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- Запись позиции очереди
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- Парсер
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- Конверт
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- Тело документа
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- Ветки тела документа
    CREQ                    clob;                    -- Буфер для запроса
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
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => STAG_BODY);
    /* Считываем дочерние элементы тела */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* Берем первый дочерний элемент */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
  end UTL_EXSQUEUE_MSG_GET_BODY_ROOT;

  /* Электронная инвентаризация - аутентификация */
  procedure CHECKAUTH
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    XCHECKAUTHRESPONSE      DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XRESULT                 DBMS_XMLDOM.DOMNODE;     -- Результат аутентификации
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Т.к. пока проверок нет никаких - всегда возвращаем положительный ответ */
      XCHECKAUTHRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CHECKAUTHRSPNS, SNS => SNS_TSD);
      XRESULT            := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_RESULT, SNS => SNS_TSD, SVAL => 'true');
      XNODE              := DBMS_XMLDOM.APPENDCHILD(N => XCHECKAUTHRESPONSE, NEWCHILD => XRESULT);
      /* Оборачиваем его в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XCHECKAUTHRESPONSE);
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end CHECKAUTH;

  /* Электронная инвентаризация - считывание пользователей */
  procedure GETUSERS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    XGETUSERSRESPONSE       DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- Код элемента ответного списка
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- Нименование элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETUSERSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETUSERSRSPNS, SNS => SNS_TSD);
      /* Обходим сотрудников-инвентаризаторов */
      for REC in (select T.RN,
                         A.AGNABBR
                    from INVPERSONS T,
                         AGNLIST    A
                   where T.COMPANY = 136018
                     and T.AGNLIST = A.RN)
      loop
        /* Собираем информацию по сотруднику в ответ */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NAME, SNS => SNS_TSD, SVAL => REC.AGNABBR);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETUSERSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETUSERSRESPONSE);
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETUSERS;

  /* Электронная инвентаризация - считывание типов ведомостей */
  procedure GETSHEETTYPES
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    XGETSHEETTYPESRESPONSE  DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- Код элемента ответного списка
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- Нименование элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETSHEETTYPESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETTYPESRSPNS, SNS => SNS_TSD);
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
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NAME, SNS => SNS_TSD, SVAL => REC.DOCCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETTYPESRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETTYPESRESPONSE);
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETTYPES;
  
  /* Электронная инвентаризация - считывание заголовков ведомостей инвентаризации */
  procedure GETSHEETS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
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
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQTYPECODE            PKG_STD.TREF;            -- Тип ведомости из запроса (параметр отбора)
    SREQPREFIX              PKG_STD.TSTRING;         -- Префикс ведомости из запроса (параметр отбора)
    SREQNUMBER              PKG_STD.TSTRING;         -- Номер ведомости из запроса (параметр отбора)
    DREQDATE                PKG_STD.TLDATE;          -- Дата ведомости из запроса (параметр отбора)
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Тип ведомости" (параметр отбора) */
      NREQTYPECODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_TYPECODE));
      /* Считываем "Префикс" (параметр отбора) */
      SREQPREFIX := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_PREFIX);
      /* Считываем "Номер" (параметр отбора) */
      SREQNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_NUMBER);
      /* Считываем "Дату" (параметр отбора) */
      DREQDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DATE), 'YYYY-MM-DD');
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETSHEETSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETSRSPNS, SNS => SNS_TSD);
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
        XITEM     := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE     := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.RN);
        XNAME     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => STAG_NAME,
                                    SNS  => SNS_TSD,
                                    SVAL => REC.DOC_TYPE_CODE || ', ' || REC.DOC_PREF || '-' || REC.DOC_NUMB || ', ' ||
                                            TO_CHAR(REC.DOC_DATE, 'dd.mm.yyyy'));
        XTYPECODE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_TYPECODE, SNS => SNS_TSD, SVAL => REC.DOC_TYPE);
        XPREFIX   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_PREFIX, SNS => SNS_TSD, SVAL => REC.DOC_PREF);
        XNUMBER   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NUMBER, SNS => SNS_TSD, SVAL => REC.DOC_NUMB);
        XDATE     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => STAG_DATE,
                                    SNS  => SNS_TSD,
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
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETS;
  
  /* Электронная инвентаризация - считывание состава ведомостей инвентаризации */
  procedure GETSHEETITEMS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
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
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQSHEETCODE           PKG_STD.TREF;            -- Ведомость из запроса (параметр отбора)
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Регистрационный номер ведомости" (параметр отбора) */
      NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETSHEETITEMSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETITEMSRSPNS, SNS => SNS_TSD);
      /* Обходим типы документов связанные с разделом "Электронные инвентаризации" */
      for REC in (select T.RN NRN,
                         T.COMPANY NCOMPANY,
                         T.BARCODE SBARCODE,
                         T.IS_LOADED NIS_LOADED,
                         DECODE(T.INVPACK, null, O.PLACE_MNEMO, OP.PLACE_MNEMO) SSTORAGEMNEMOCODE,
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
        XITEM             := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XSTORAGEMNEMOCODE := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_STORAGEMNEMOCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => REC.SSTORAGEMNEMOCODE);
        XUSERCODE         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_USERCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.NINVPERSONS));
        XITEMCODE         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SIBARCODE));
        XITEMNAME         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMNAME,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SNOM_NAME));
        XITEMMNEMOCODE    := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMMNEMOCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SNOM_CODE));
        XITEMNUMBER       := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMNUMBER,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SINV_NUMBER));
        XQUANTITY         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_QUANTITY,
                                            SNS  => SNS_TSD,
                                            SVAL => REC.SQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XSTORAGEMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XUSERCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNAME);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNUMBER);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETITEMSRESPONSE, NEWCHILD => XITEM);
        /* Выставим дату выгрузки в терминал для позиции ведомости инвентаризации */
        P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => REC.NCOMPANY,
                                  NRN          => REC.NRN,
                                  DUNLOAD_DATE => sysdate,
                                  DINV_DATE    => null,
                                  NINVPERSONS  => REC.NINVPERSONS,
                                  SBARCODE     => REC.SBARCODE,
                                  NIS_LOADED   => REC.NIS_LOADED);
      end loop;
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETITEMSRESPONSE);
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETITEMS;
  
  /* Электронная инвентаризация - считывание мест хранения */
  procedure GETSTORAGES
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
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
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQDEVICEID            PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQSHEETCODE           PKG_STD.TREF;            -- Ведомость из запроса (параметр отбора)
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Регистрационный номер ведомости" (параметр отбора) */
      NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETSTORAGESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSTORAGESRSPNS, SNS => SNS_TSD);
      /* Обходим места хранения */
      for REC in (select T.RN NRN,
                         T.PLACE_MNEMO SMNEMOCODE,
                         T.PLACE_NAME SNAME,
                         UDO_F_GET_DOC_PROP_VAL_STR('LATITUDE', 'ObjPlace', T.RN) SLATITUDE,
                         UDO_F_GET_DOC_PROP_VAL_STR('LONGITUDE', 'ObjPlace', T.RN) SLONGITUDE,
                         NVL(T.ADDR_POST, G.POSTAL_CODE) SPOSTCODE,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 1) SCOUNTRY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2) SREGION,
                         NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 8),
                             NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 4),
                                 NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 3), UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2)))) SLOCALITY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 5) SSTREET,
                         T.ADDR_HOUSE SHOUSENUMBER,
                         T.BARCODE SBARCODE
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
        XITEM        := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE        := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.SBARCODE);
        XNAME        := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NAME, SNS => SNS_TSD, SVAL => REC.SNAME);
        XMNEMOCODE   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_MNEMOCODE, SNS => SNS_TSD, SVAL => REC.SMNEMOCODE);
        XLATITUDE    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_LATITUDE, SNS => SNS_TSD, SVAL => REC.SLATITUDE);
        XLONGITUDE   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_LONGITUDE, SNS => SNS_TSD, SVAL => REC.SLONGITUDE);
        XPOSTCODE    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_POSTCODE, SNS => SNS_TSD, SVAL => REC.SPOSTCODE);
        XCOUNTRY     := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_COUNTRY, SNS => SNS_TSD, SVAL => REC.SCOUNTRY);
        XREGION      := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_REGION, SNS => SNS_TSD, SVAL => REC.SREGION);
        XLOCALITY    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_LOCALITY, SNS => SNS_TSD, SVAL => REC.SLOCALITY);
        XSTREET      := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_STREET, SNS => SNS_TSD, SVAL => REC.SSTREET);
        XHOUSENUMBER := UTL_CREATENODE(XDOC => XDOC,
                                       STAG => STAG_HOUSENUMBER,
                                       SNS  => SNS_TSD,
                                       SVAL => REC.SHOUSENUMBER);
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
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSTORAGES;

  /* Электронная инвентаризация - сохранение результатов инвентаризации */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NEXSQUEUE               in number                -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    XSAVESHEETITEMRESPONSE  DBMS_XMLDOM.DOMNODE;     -- Корневой элемент ответа
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для ветки ответа
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- Элемент ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
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
    NREQLATITUDE            PKG_STD.TLNUMBER;        -- Широта ОС из запроса (параметр сохранения) 
    NREQLONGITUDE           PKG_STD.TLNUMBER;        -- Долгота ОС из запроса (параметр сохранения)    
    NREQDISTANCETOSTORAGE   PKG_STD.TLNUMBER;        -- Расстояние до места хранения ОС из запроса (параметр сохранения)    
    SREQFLOOR               PKG_STD.TSTRING;         -- Этаж расположения ОС из запроса (параметр сохранения)
    SREQROOM                PKG_STD.TSTRING;         -- Помещение расположения ОС из запроса (параметр сохранения)
    SREQRACK                PKG_STD.TSTRING;         -- Стеллаж расположения ОС из запроса (параметр сохранения)
    NELINVOBJECT            PKG_STD.TREF;            -- Рег. номер позиции ведомости инвентаризации
    SDICPLACEBARCODE        PKG_STD.TSTRING;         -- Штрих-код места хранения gсогласно ведомости
    NINVENTORY              PKG_STD.TREF;            -- Рег. номер ОС (карточки "Инвентарной картотеки")
    NCOMPANY                PKG_STD.TREF;            -- Рег. номер организации
    NPROPERTY               PKG_STD.TREF;            -- Рег. номер ДС позиции ведомости инвентаризации для хранения комментария
    NTMP                    PKG_STD.TREF;            -- Буфер для рег. номеров
  begin
    begin
      /* Инициализируем организацию */
      NCOMPANY := 136018;
      /* Инициализируем ДС для хранения примечания */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0, NCOMPANY => NCOMPANY, SCODE => 'COMMENT', NRN => NPROPERTY);
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Регистрационный номер ведомости" (параметр сохранения) */
      NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* Считываем "Регистрационный номер МОЛ" (параметр сохранения) */
      NREQUSERCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_USERCODE));
      /* Считываем "Мнемокод места хранения" (параметр сохранения) */
      SREQSTORAGEMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEMNEMOCODE);
      /* Считываем "Признак нового места хранения" (параметр сохранения) */
      NREQSTORAGEISNEW := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEISNEW));
      /* Считываем "Штрих-код места хранения" (параметр сохранения) */
      SREQSTORAGECODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECODE);
      /* Считываем "Наименование места хранения" (параметр сохранения) */
      SREQSTORAGENAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGENAME);
      /* Считываем "Почтовый индекс места хранения" (параметр сохранения) */
      SREQSTORAGEPOSTCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEPOSTCODE);
      /* Считываем "Страна места хранения" (параметр сохранения) */
      SREQSTORAGECOUNTRY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECOUNTRY);
      /* Считываем "Регион места хранения" (параметр сохранения) */
      SREQSTORAGEREGION := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEREGION);
      /* Считываем "Населенный пункт места хранения" (параметр сохранения) */
      SREQSTORAGELOCALITY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELOCALITY);
      /* Считываем "Улица места хранения" (параметр сохранения) */
      SREQSTORAGESTREET := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGESTREET);
      /* Считываем "Номер дома места хранения" (параметр сохранения) */
      SREQSTORAGEHOUSENUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEHOUSENUMBER);
      /* Считываем "Широта места хранения" (параметр сохранения) */
      NREQSTORAGELATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELATITUDE));
      /* Считываем "Долгота места хранения" (параметр сохранения) */
      NREQSTORAGELONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELONGITUDE));
      /* Считываем "Штрих-код ОС" (параметр сохранения) */
      SREQITEMCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMCODE);
      /* Считываем "Наименование номенклатуры ОС" (параметр сохранения) */
      SREQITEMNAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNAME);
      /* Считываем "Мнемокод номенклатуры ОС" (параметр сохранения) */
      SREQITEMMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMMNEMOCODE);
      /* Считываем "Инвентарный номер ОС" (параметр сохранения) */
      SREQITEMNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNUMBER);
      /* Считываем "Количество ОС" (параметр сохранения) */
      NREQQUANTITY := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_QUANTITY));
      /* Считываем "Дата проведения инвентаризации ОС" (параметр сохранения) */
      DREQCHECKDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_CHECKDATE),
                               'YYYY-MM-DD"T"HH24:MI:SS');
      /* Считываем "Комментарий МОЛ ОС" (параметр сохранения) */
      SREQCOMMENT := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_COMMENT);
      /* Считываем "Широта ОС" (параметр сохранения) */
      NREQLATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LATITUDE));
      /* Считываем "Долгота ОС" (параметр сохранения) */
      NREQLONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LONGITUDE));
      /* Считываем "Расстояние до места хранения ОС" (параметр сохранения) */
      NREQDISTANCETOSTORAGE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DISTANCETOSTORAGE));
      /* Считываем "Этаж расположения ОС" (параметр сохранения) */
      SREQFLOOR := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_FLOOR);
      /* Считываем "Помещение расположения ОС" (параметр сохранения) */
      SREQROOM := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ROOM);
      /* Считываем "Стеллаж расположения ОС" (параметр сохранения) */
      SREQRACK := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_RACK);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Работаем только если указан регистрационный номер ведомости */
      if (NREQSHEETCODE is not null) then
        /*
        TODO: owner="root" created="14.01.2019"
        text="Понять зачем мы это делаем (дальше результаты проверки не идут).
              Надо реализовать добавление нового местонахождения + смену текущего"
        */
        /* Если задан штрих-код местанхождения ОС */
        if (SREQSTORAGECODE is not null) then
          /* Проверяем наличие местонахохждения */
          begin
            select T.BARCODE
              into SDICPLACEBARCODE
              from DICPLACE T
             where T.COMPANY = NCOMPANY
               and T.BARCODE = SREQSTORAGECODE;
          exception
            when NO_DATA_FOUND then
              P_EXCEPTION(0,
                          'Местонахождение инвентарных объектов с штрих-кодом "%s" не найдено',
                          SREQSTORAGECODE);
          end;
        end if;
        /* Пробуем найти позицию ведомости инвентаризации по штрих-коду (если передан рег. номер ведомости и пока нет ошибок) */
        if (NREQSHEETCODE is not null) then
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
                  P_EXCEPTION(0,
                              'Инвентарная карточка с штрих-кодом "%s" не найдена',
                              SREQITEMCODE);
              end;
          end;
        end if;
        /* И у нас есть штрихкод фактического местонахождения */
        if (SDICPLACEBARCODE is not null) then
          /* Если позиция ведомости инвентаризации найдена */
          if (NELINVOBJECT is not null) then
            /* Обновим её */
            for C in (select T.* from ELINVOBJECT T where T.RN = NELINVOBJECT)
            loop
              P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                            SUNITCODE   => 'ElectronicInventoriesObjects',
                                            NPROPERTY   => NPROPERTY,
                                            SSTR_VALUE  => SREQCOMMENT,
                                            NNUM_VALUE  => null,
                                            DDATE_VALUE => null,
                                            NRN         => NTMP);
              P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => C.COMPANY,
                                        NRN          => C.RN,
                                        DUNLOAD_DATE => C.UNLOAD_DATE,
                                        DINV_DATE    => NVL(DREQCHECKDATE, sysdate),
                                        NINVPERSONS  => NREQUSERCODE,
                                        SBARCODE     => SDICPLACEBARCODE,
                                        NIS_LOADED   => C.IS_LOADED);
            end loop;
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
                                      SBARCODE     => SDICPLACEBARCODE,
                                      NIS_LOADED   => 1,
                                      NRN          => NELINVOBJECT);
            P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => NELINVOBJECT,
                                          SUNITCODE   => 'ElectronicInventoriesObjects',
                                          NPROPERTY   => NPROPERTY,
                                          SSTR_VALUE  => SREQCOMMENT,
                                          NNUM_VALUE  => null,
                                          DDATE_VALUE => null,
                                          NRN         => NTMP);
          end if;
        else
          P_EXCEPTION(0,
                      'Не удалось определить фактическое местонахождение');
        end if;
      end if;
      /* Создаём пространство имён для ответа */
      XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_SAVESHEETITEMRSPNS, SNS => SNS_TSD);
      /* Формируем результат */
      XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_RESULT, SNS => SNS_TSD, SVAL => 'true');
      XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
      /* Оборачиваем ответ в конверт */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
    exception
      /* Перехватываем возможные ошибки */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* Вернём ошибку - это фатальная */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end SAVESHEETITEM;
  
end;
/
