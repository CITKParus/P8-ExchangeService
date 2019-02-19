create or replace package UDO_PKG_EXS_INV as

  /* Считывание значения структурного элемента из иерархии адреса географического понятия */
  function UTL_GEOGRAFY_GET_HIER_ITEM
  (
    NGEOGRAFY               in number,  -- Регистрационный номер географического понятия
    NGEOGRTYPE              in number   -- Тип искомого структурного элемента адреса (1 - страна, 2 - регион, 3 - район, 4 - населенный пункт, 5 - улица, 6 - административный округ, 7 - муниципальный округ, 8 - город, 9 - уровень внутригородской территории, 10 - уровень дополнительных территорий, 11 - уровень подчиненных дополнительным территориям объектов)
  ) return                  varchar2;   -- Наименование найденного стуктурного элемента адреса
  
  /* Поиск геопонятия по стуктурным элементам */
  function UTL_GEOGRAFY_FIND_BY_HIER_ITEM
  (
    NCOMPANY              in number,    -- Рег. номер организации
    SADDR_COUNTRY         in varchar2,  -- Страна местонахождения
    SADDR_REGION          in varchar2,  -- Регион местонахождения
    SADDR_LOCALITY        in varchar2,  -- Населённый пункт местонахождения
    SADDR_STREET          in varchar2   -- Улица местонахождения
  ) return                number;       -- Географическое понятие
  
  /* Получение данных о местонахождении позиции ведомости инвентаризации */
  function UTL_ELINVOBJECT_DICPLACE_GET
  (
    NELINVOBJECT            in number,  -- Рег. номер записи ведомости инвентаризации
    SRESULT_TYPE            in varchar2 -- Тип результата (см. констнаты SRESULT_TYPE*)
  ) return                  varchar2;   -- Штрих-код ОС
  
  /* Получение штрих-кода позиции ведомости инвентаризации */
  function UTL_ELINVOBJECT_BARCODE_GET
  (
    NELINVOBJECT            in number   -- Рег. номер записи ведомости инвентаризации
  ) return                  varchar2;   -- Штрих-код ОС
  
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
  
  /* Электронная инвентаризация - считывание местонахождений */
  procedure GETSTORAGES
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );  
  
  /* Электронная инвентаризация - сохранение результатов инвентаризации элемента хранения */
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
  STAG_FAULT                constant varchar2(40) := 'Fault';
  STAG_DETAIL               constant varchar2(40) := 'detail';
  STAG_MESSAGE              constant varchar2(40) := 'Message';  
  STAG_STORAGEMESSAGE       constant varchar2(40) := 'StorageMessage';
  STAG_ITEMMESSAGE          constant varchar2(40) := 'ItemMessage';
  STAG_ERRORMESSAGE         constant varchar2(40) := 'ErrorMessage';
  STAG_ERRORMESSAGE_SSITEM  constant varchar2(40) := 'ErrorSaveSheetItemMessage';  
  
  /* Константы - типы возвращаемых значений */
  SRESULT_TYPE_MNEMO        constant varchar2(40):='MNEMO';   -- Мнемокод
  SRESULT_TYPE_BARCODE      constant varchar2(40):='BARCODE'; -- Штрих-код
   
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
  
  /* Формирование ответа с ошибкой для процедуры импорта результатов инвентаризации */
  function UTL_CREATEERRORRESPONSE_SSITEM
  (
    SMSG_ELINVOBJECT        in varchar2,             -- Сообщение об ошибке (для инвентарного объекта)
    SMSG_DICPLACE           in varchar2              -- Сообщение об ошибке (для местонахождения)
  ) return                  clob                     -- Результат работы     
  is
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XFAULT                  DBMS_XMLDOM.DOMNODE;     -- Корневой узел
    XDETAIL                 DBMS_XMLDOM.DOMNODE;     -- Узел для детализации ошибки
    XERRMSG                 DBMS_XMLDOM.DOMNODE;     -- Узел с сообщением об ошибке
    XMSG_ELINVOBJECT        DBMS_XMLDOM.DOMNODE;     -- Узел текстом сообщения (для инвентарного объекта)
    XMSG_DICPLACE           DBMS_XMLDOM.DOMNODE;     -- Узел текстом сообщения (для местонахождения)
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- Буфер для узла
    CDATA                   clob;                    -- Буфер для результата
  begin
    /* Создаём документ для ответа */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* Собираем ошибку в ответ */
    XFAULT           := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_FAULT, SNS => SNS_SOAPENV);
    XDETAIL          := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_DETAIL);
    XERRMSG          := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ERRORMESSAGE_SSITEM, SNS => SNS_TSD);
    XMSG_ELINVOBJECT := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEMMESSAGE, SNS => SNS_TSD, SVAL => SMSG_ELINVOBJECT);
    XMSG_DICPLACE    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_STORAGEMESSAGE, SNS => SNS_TSD, SVAL => SMSG_DICPLACE);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG_ELINVOBJECT);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG_DICPLACE);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XDETAIL, NEWCHILD => XERRMSG);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XFAULT, NEWCHILD => XDETAIL);
    CDATA            := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XFAULT);
    /* Возвращаем результат */
    return CDATA;
  end UTL_CREATEERRORRESPONSE_SSITEM;
  
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
  
  /* Поиск геопонятия по стуктурным элементам */
  function UTL_GEOGRAFY_FIND_BY_HIER_ITEM
  (
    NCOMPANY              in number,    -- Рег. номер организации
    SADDR_COUNTRY         in varchar2,  -- Страна местонахождения
    SADDR_REGION          in varchar2,  -- Регион местонахождения
    SADDR_LOCALITY        in varchar2,  -- Населённый пункт местонахождения
    SADDR_STREET          in varchar2   -- Улица местонахождения
  ) return                number        -- Географическое понятие
  is
    NRES                  PKG_STD.TREF; -- Рег. номер найденного географического понятия
    NVERSION              PKG_STD.TREF; -- Рег. номер версии словаря географических понятий
  begin
    /* Проверим параметры */
    if (NCOMPANY is null) then
      return null;
    end if;
    if ((SADDR_COUNTRY is null) and (SADDR_REGION is null) and (SADDR_LOCALITY is null) and (SADDR_STREET is null)) then
      return null;
    end if;
    /* Определим версию словаря географических понятий */
    FIND_VERSION_BY_COMPANY(NCOMPANY => NCOMPANY, SUNITCODE => 'GEOGRAFY', NVERSION => NVERSION);
    /* Подберем географическое понятие - сначала страны */
    for C in (select G.RN
                from GEOGRAFY G
               where G.VERSION = NVERSION
                 and ((SADDR_COUNTRY is null) or
                     ((SADDR_COUNTRY is not null) and (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_COUNTRY || '%'))))
                 and G.GEOGRTYPE = 1)
    loop
      /* Теперь регионы страны */
      for R in (select G.RN
                  from GEOGRAFY G
                 where G.VERSION = NVERSION
                   and ((SADDR_REGION is null) or
                       ((SADDR_REGION is not null) and (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_REGION || '%'))))
                   and G.GEOGRTYPE = 2
                   and G.RN in (select GG.RN
                                  from GEOGRAFY GG
                                 where GG.GEOGRTYPE = 2
                                connect by prior GG.RN = GG.PRN
                                 start with GG.RN = C.RN))
      loop
        /* Спускаемся в населенные пункты */
        for L in (select G.RN
                    from GEOGRAFY G
                   where G.VERSION = NVERSION
                     and ((SADDR_LOCALITY is null) or ((SADDR_LOCALITY is not null) and
                         (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_LOCALITY || '%'))))
                     and G.GEOGRTYPE in (8, 4, 3, 2)
                     and G.RN in (select GG.RN
                                    from GEOGRAFY GG
                                   where GG.GEOGRTYPE in (8, 4, 3, 2)
                                  connect by prior GG.RN = GG.PRN
                                   start with GG.RN = R.RN)
                  
                  )
        loop
          /* Теперь - улицы */
          for S in (select G.RN
                      from GEOGRAFY G
                     where G.VERSION = NVERSION
                       and ((SADDR_STREET is null) or
                           ((SADDR_STREET is not null) and (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_STREET || '%'))))
                       and G.GEOGRTYPE = 5
                       and G.RN in (select GG.RN
                                      from GEOGRAFY GG
                                     where GG.GEOGRTYPE = 5
                                    connect by prior GG.RN = GG.PRN
                                     start with GG.RN = L.RN)
                    
                    )
          loop
            /* Возврат результата */
            return S.RN;
          end loop;
        end loop;
      end loop;
    end loop;
    /* Вернём пустой результат - сюда приходим только если ничего не нашли */
    return NRES;
  end UTL_GEOGRAFY_FIND_BY_HIER_ITEM;
  
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
      /* Скажем об этом */
      P_EXCEPTION(0,
                  'Идентификатор устровйства "%s" не определён в лицензии.',
                  SDEVICEID);
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
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
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
  
  /* Получение данных о местонахождении позиции ведомости инвентаризации */
  function UTL_ELINVOBJECT_DICPLACE_GET
  (
    NELINVOBJECT            in number,       -- Рег. номер записи ведомости инвентаризации
    SRESULT_TYPE            in varchar2      -- Тип результата (см. констнаты SRESULT_TYPE*)
  ) return                  varchar2         -- Штрих-код ОС
  is
    SRES                    PKG_STD.TSTRING; -- Результат работы
  begin
    /* Найдем искомые значения атрибутов местонахождения */
    begin
      select DECODE(SRESULT_TYPE,
                    SRESULT_TYPE_MNEMO,
                    DECODE(T.INVPACK, null, O.PLACE_MNEMO, OP.PLACE_MNEMO),
                    SRESULT_TYPE_BARCODE,
                    DECODE(T.INVPACK, null, O.BARCODE, OP.BARCODE),
                    null)
        into SRES
        from ELINVOBJECT T,
             INVENTORY   I,
             DICPLACE    O,
             DICPLACE    OP,
             INVPACK     P
       where T.RN = NELINVOBJECT
         and T.INVENTORY = I.RN
         and I.OBJECT_PLACE = O.RN(+)
         and T.INVPACK = P.RN(+)
         and P.OBJECT_PLACE = OP.RN(+);
    exception
      when NO_DATA_FOUND then
        SRES := null;
    end;
    /* Вернём результат */
    return SRES;
  end UTL_ELINVOBJECT_DICPLACE_GET;
  
  /* Получение штрих-кода позиции ведомости инвентаризации */
  function UTL_ELINVOBJECT_BARCODE_GET
  (
    NELINVOBJECT            in number        -- Рег. номер записи ведомости инвентаризации
  ) return                  varchar2         -- Штрих-код ОС
  is
    SRES                    PKG_STD.TSTRING; -- Результат работы
  begin
    /* Считаем штрих-код позиции ведомости инвентаризации */
    begin
      select DECODE(PS.RN,
                    null,
                    DECODE(T.INVPACK, null, DECODE(T.INVSUBST, null, I.BARCODE, U.BARCODE), P.BARCODE),
                    PS.BARCODE)
        into SRES
        from ELINVOBJECT T,
             INVENTORY   I,
             INVPACK     P,
             INVPACKPOS  PS,
             INVSUBST    U
       where T.RN = NELINVOBJECT
         and T.INVENTORY = I.RN
         and T.INVPACK = P.RN(+)
         and T.INVPACK = PS.PRN(+)
         and T.INVSUBST = PS.INVSUBST(+)
         and T.INVSUBST = U.RN(+);
    exception
      when NO_DATA_FOUND then
        SRES := null;
    end;
    /* Вернём результат */
    return SRES;
  end UTL_ELINVOBJECT_BARCODE_GET;

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
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
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
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
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
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
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
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQ_TYPECODE           PKG_STD.TREF;            -- Тип ведомости из запроса (параметр отбора)
    SREQ_PREFIX             PKG_STD.TSTRING;         -- Префикс ведомости из запроса (параметр отбора)
    SREQ_NUMBER             PKG_STD.TSTRING;         -- Номер ведомости из запроса (параметр отбора)
    DREQ_DATE               PKG_STD.TLDATE;          -- Дата ведомости из запроса (параметр отбора)
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Тип ведомости" (параметр отбора) */
      NREQ_TYPECODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_TYPECODE));
      /* Считываем "Префикс" (параметр отбора) */
      SREQ_PREFIX := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_PREFIX);
      /* Считываем "Номер" (параметр отбора) */
      SREQ_NUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_NUMBER);
      /* Считываем "Дату" (параметр отбора) */
      DREQ_DATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DATE), 'YYYY-MM-DD');
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
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
                     and (NREQ_TYPECODE is null or (NREQ_TYPECODE is not null and T.DOC_TYPE = NREQ_TYPECODE))
                     and (SREQ_PREFIX is null or (SREQ_PREFIX is not null and trim(T.DOC_PREF) = SREQ_PREFIX))
                     and (SREQ_NUMBER is null or (SREQ_NUMBER is not null and trim(T.DOC_NUMB) = SREQ_NUMBER))
                     and (DREQ_DATE is null or (DREQ_DATE is not null and T.DOC_DATE = DREQ_DATE)))
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
    XSTORAGEMNEMOCODE       DBMS_XMLDOM.DOMNODE;     -- Мнемокод местонахождения для элемента ответного списка
    XUSERCODE               DBMS_XMLDOM.DOMNODE;     -- МОЛ для элемента ответного списка
    XITEMCODE               DBMS_XMLDOM.DOMNODE;     -- Идентификатор ОС для элемента ответного списка
    XITEMNAME               DBMS_XMLDOM.DOMNODE;     -- Наименование ОС для элемента ответного списка
    XITEMMNEMOCODE          DBMS_XMLDOM.DOMNODE;     -- Код ОС для элемента ответного списка
    XITEMNUMBER             DBMS_XMLDOM.DOMNODE;     -- Номер ОС для элемента ответного списка
    XQUANTITY               DBMS_XMLDOM.DOMNODE;     -- Количество ОС для элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQ_SHEET_CODE         PKG_STD.TREF;            -- Ведомость из запроса (параметр отбора)
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Регистрационный номер ведомости" (параметр отбора) */
      NREQ_SHEET_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETSHEETITEMSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETITEMSRSPNS, SNS => SNS_TSD);
      /* Обходим типы документов связанные с разделом "Электронные инвентаризации" */
      for REC in (select T.RN NRN,
                         T.COMPANY NCOMPANY,
                         T.BARCODE SBARCODE,
                         T.IS_LOADED NIS_LOADED,
                         UTL_ELINVOBJECT_DICPLACE_GET(T.RN, SRESULT_TYPE_MNEMO) SSTORAGEMNEMOCODE,
                         UTL_ELINVOBJECT_DICPLACE_GET(T.RN, SRESULT_TYPE_BARCODE) SOBARCODE,
                         T.INVPERSONS NINVPERSONS,
                         UTL_ELINVOBJECT_BARCODE_GET(T.RN) SIBARCODE,
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
                     and T.PRN = NREQ_SHEET_CODE
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
        XQUANTITY         := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_QUANTITY, SNS => SNS_TSD, SVAL => REC.SQUANTITY);
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
  
  /* Электронная инвентаризация - считывание местонахождений */
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
    XMNEMOCODE              DBMS_XMLDOM.DOMNODE;     -- Мнемокод местонахождения для элемента ответного списка
    XLATITUDE               DBMS_XMLDOM.DOMNODE;     -- Широта местонахождения для элемента ответного списка
    XLONGITUDE              DBMS_XMLDOM.DOMNODE;     -- Долгота местонахождения для элемента ответного списка
    XPOSTCODE               DBMS_XMLDOM.DOMNODE;     -- Почтовый индекс местонахождения для элемента ответного списка
    XCOUNTRY                DBMS_XMLDOM.DOMNODE;     -- Страна местонахождения для элемента ответного списка
    XREGION                 DBMS_XMLDOM.DOMNODE;     -- Регион местонахождения для элемента ответного списка
    XLOCALITY               DBMS_XMLDOM.DOMNODE;     -- Населённый пункт местонахождения для элемента ответного списка
    XSTREET                 DBMS_XMLDOM.DOMNODE;     -- Улица местонахождения для элемента ответного списка
    XHOUSENUMBER            DBMS_XMLDOM.DOMNODE;     -- Номер дома местонахождения для элемента ответного списка
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- Документ
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- Корневой элемент первой ветки тела документа
    CRESPONSE               clob;                    -- Буфер для ответа
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQ_SHEET_CODE         PKG_STD.TREF;            -- Ведомость из запроса (параметр отбора)
  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Регистрационный номер ведомости" (параметр отбора) */
      NREQ_SHEET_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Создаём пространство имён для ответа */
      XGETSTORAGESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSTORAGESRSPNS, SNS => SNS_TSD);
      /* Обходим местонахождения */
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
                     and ((NREQ_SHEET_CODE is null) or
                         ((NREQ_SHEET_CODE is not null) and
                         (T.RN in (select DECODE(EO.INVPACK, null, INV.OBJECT_PLACE, P.OBJECT_PLACE)
                                       from ELINVOBJECT EO,
                                            INVENTORY   INV,
                                            INVPACK     P
                                      where EO.PRN = NREQ_SHEET_CODE
                                        and EO.INVENTORY = INV.RN
                                        and EO.INVPACK = P.RN(+))))))
      loop
        /* Собираем информацию по местонахождению в ответ */
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

  /* Электронная инвентаризация - сохранение результатов инвентаризации элемента хранения */
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
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- Идентификатор устройства из запроса
    NREQ_SHEET_CODE         PKG_STD.TREF;            -- Ведомость из запроса (параметр сохранения)
    NREQ_USER_CODE          PKG_STD.TREF;            -- Регистрационный номер МОЛ из запроса (параметр сохранения)
    SREQ_STORAGE_MNEMOCODE  PKG_STD.TSTRING;         -- Мнемокод местонахождения из запроса (параметр сохранения)
    NREQ_STORAGE_ISNEW      PKG_STD.TNUMBER;         -- Признак нового местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_CODE       PKG_STD.TSTRING;         -- Штрих-код местонахождения из запроса (параметр сохранения)
    SREQ_STORAGE_NAME       PKG_STD.TSTRING;         -- Наименование местонахождения из запроса (параметр сохранения)
    SREQ_STORAGE_POSTCODE   PKG_STD.TSTRING;         -- Почтовый индекс местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_COUNTRY    PKG_STD.TSTRING;         -- Страна местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_REGION     PKG_STD.TSTRING;         -- Регион местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_LOCALITY   PKG_STD.TSTRING;         -- Населенный пункт местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_STREET     PKG_STD.TSTRING;         -- Улица местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_HOUSE      PKG_STD.TSTRING;         -- Номер дома местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_LATITUDE   PKG_STD.TSTRING;         -- Широта местонахождения из запроса (параметр сохранения)    
    SREQ_STORAGE_LONGITUDE  PKG_STD.TSTRING;         -- Долгота местонахождения из запроса (параметр сохранения) 
    SREQ_ITEM_CODE          PKG_STD.TSTRING;         -- Штрих-код ОС из запроса (параметр сохранения)  
    SREQ_ITEM_NAME          PKG_STD.TSTRING;         -- Наименование номенклатуры ОС из запроса (параметр сохранения)
    SREQ_ITEM_MNEMOCODE     PKG_STD.TSTRING;         -- Мнемокод номенклатуры ОС из запроса (параметр сохранения)
    SREQ_ITEM_NUMBER        PKG_STD.TSTRING;         -- Инвентарный номер ОС из запроса (параметр сохранения)
    NREQ_ITEM_QUANTITY      PKG_STD.TQUANT;          -- Количество ОС из запроса (параметр сохранения)    
    DREQ_ITEM_CHECKDATE     PKG_STD.TLDATE;          -- Дата проведения инвентаризации ОС из запроса (параметр сохранения)  
    SREQ_ITEM_COMMENT       PKG_STD.TLSTRING;        -- Комментарий МОЛ ОС из запроса (параметр сохранения)
    SREQ_ITEM_LATITUDE      PKG_STD.TSTRING;         -- Широта ОС из запроса (параметр сохранения) 
    SREQ_ITEM_LONGITUDE     PKG_STD.TSTRING;         -- Долгота ОС из запроса (параметр сохранения)    
    NREQ_ITEM_DISTANCE      PKG_STD.TLNUMBER;        -- Расстояние до местонахождения ОС из запроса (параметр сохранения)    
    RELINVENTORY            ELINVENTORY%rowtype;     -- Запись модифицируемой ведомости инвентаризации
    NELINVOBJECT            PKG_STD.TREF;            -- Рег. номер позиции ведомости инвентаризации
    SDICPLACE_BARCODE       PKG_STD.TSTRING;         -- Штрих-код местонахождения ОС (для позиции ведомости инвентаризации)
    SERR_ELINVOBJECT        PKG_STD.TSTRING;         -- Буфер для ошибки обработки инвентарной карточки
    SERR_DICPLACE           PKG_STD.TSTRING;         -- Буфер для ошибки обработки местонахождения

    /* Поиск географического понятия по параметрам */
    function FIND_GEOGRAFY
    (
      NCOMPANY              in number,    -- Рег. номер организации
      SADDR_COUNTRY         in varchar2,  -- Страна местонахождения
      SADDR_REGION          in varchar2,  -- Регион местонахождения
      SADDR_LOCALITY        in varchar2,  -- Населённый пункт местонахождения
      SADDR_STREET          in varchar2   -- Улица местонахождения
    ) return                number        -- Географическое понятие
    is
    begin
      return UTL_GEOGRAFY_FIND_BY_HIER_ITEM(NCOMPANY       => NCOMPANY,
                                            SADDR_COUNTRY  => SADDR_COUNTRY,
                                            SADDR_REGION   => SADDR_REGION,
                                            SADDR_LOCALITY => SADDR_LOCALITY,
                                            SADDR_STREET   => SADDR_STREET);
    end FIND_GEOGRAFY;
    
    /* Обработка местонахождения - поиск и при необходимости добавление местонахождения ОС */
    procedure PROCESS_DICPLACE
    (
      NCOMPANY              in number,    -- Рег. номер организации
      NIS_NEW               in number,    -- Признак нового метонахождения (0 - старое, 1 - новое)
      SMNEMO                in varchar2,  -- Мнемокод местонахождения
      SNAME                 in varchar2,  -- Наименование местонахождения
      SBARCODE              in varchar2,  -- Штарих-код местонахождения
      SADDR_POSTCODE        in varchar2,  -- Почтовый индекс местонахождения
      SADDR_COUNTRY         in varchar2,  -- Страна местонахождения
      SADDR_REGION          in varchar2,  -- Регион местонахождения
      SADDR_LOCALITY        in varchar2,  -- Населённый пункт местонахождения
      SADDR_STREET          in varchar2,  -- Улица местонахождения
      SADDR_HOUSE           in varchar2,  -- Дом местонахождения
      SLATITUDE             in varchar2,  -- Широта местонахождения
      SLONGITUDE            in varchar2,  -- Долгота местонахождения
      SDICPLACE_BARCODE     out varchar2  -- Штрихкод обработанного мемстонахождения
    )
    is
      NPROP_LATITUDE        PKG_STD.TREF; -- Рег. номер ДС для хранения широты местонахождения
      NPROP_LONGITUDE       PKG_STD.TREF; -- Рег. номер ДС для хранения долготы местонахождения      
      NDICPLACE             PKG_STD.TREF; -- Рег. номер местонахождения
      NDICPLACE_CRN         PKG_STD.TREF; -- Рег. номер каталога местонахождения
      NTMP                  PKG_STD.TREF; -- Буфер для рег. номеров      
    begin
      /* Инициализируем ДС для хранения широты */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0, NCOMPANY => NCOMPANY, SCODE => 'LATITUDE', NRN => NPROP_LATITUDE);
      /* Инициализируем ДС для хранения долготы */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0, NCOMPANY => NCOMPANY, SCODE => 'LONGITUDE', NRN => NPROP_LONGITUDE);
      /* Проверяем наличие местонахождения по переданному штрихкоду */
      begin
        select T.RN
          into NDICPLACE
          from DICPLACE T
         where T.COMPANY = NCOMPANY
           and T.BARCODE = SBARCODE;
      exception
        when NO_DATA_FOUND then
          /* Пробуем найти по мнемокоду */
          begin
            select T.RN
              into NDICPLACE
              from DICPLACE T
             where T.COMPANY = NCOMPANY
               and T.PLACE_MNEMO = SMNEMO;
          exception
            when NO_DATA_FOUND then
              /* Нашли, но если это новое - добавляем */
              if (NIS_NEW = 1) then
                /* Определим каталог размещения */
                FIND_ROOT_CATALOG(NCOMPANY => NCOMPANY, SCODE => 'ObjPlace', NCRN => NDICPLACE_CRN);
                /* Добавим запись */
                P_DICPLACE_BASE_INSERT(NCOMPANY        => NCOMPANY,
                                       NCRN            => NDICPLACE_CRN,
                                       SMNEMO          => SMNEMO,
                                       SNAME           => SNAME,
                                       SBARCODE        => NVL(SBARCODE, GEN_BARCODE_EX()),
                                       DLABEL_DATE     => sysdate,
                                       SCAD_NUMB       => null,
                                       NGEOGRAFY       => null,
                                       SADDR_HOUSE     => SADDR_HOUSE,
                                       SADDR_BLOCK     => null,
                                       SADDR_BUILDING  => null,
                                       SADDR_FLAT      => null,
                                       SADDR_POST      => SADDR_POSTCODE,
                                       SPLACE_DESCRIPT => SADDR_COUNTRY || '/' || SADDR_REGION || '/' || SADDR_LOCALITY || '/' ||
                                                          SADDR_STREET,
                                       SAOID           => null,
                                       SAOGUID         => null,
                                       SHOUSEID        => null,
                                       SHOUSEGUID      => null,
                                       NRN             => NDICPLACE);
              else
                P_EXCEPTION(0,
                            'Местонахождение инвентарных объектов с штрих-кодом "%s" или мнемокодом "%s" не найдено.',
                            NVL(SBARCODE, '<НЕ УКАЗАН>'),
                            NVL(SMNEMO, '<НЕ УКАЗАНО>'));
              end if;
          end;
        when TOO_MANY_ROWS then
          P_EXCEPTION(0,
                      'Местонахождение инвентарных объектов с штрих-кодом "%s" определено неоднозначно.',
                      SBARCODE);
      end;
      /* Проверим что нашли местонахождение */
      if (NDICPLACE is null) then
        P_EXCEPTION(0,
                    'Не удалось определить фактическое местонахождение по штрихкоду "%s" и мнемокоду "%s".',
                    NVL(SBARCODE, '<НЕ УКАЗАН>'),
                    NVL(SMNEMO, '<НЕ УКАЗАН>'));
      end if;
      /* Актуализируем его */
      for C in (select T.* from DICPLACE T where T.RN = NDICPLACE)
      loop
        /* Подберем дату штрих-кода */
        if (NVL(SBARCODE, C.BARCODE) is not null) then
          if (SBARCODE = C.BARCODE) then
            C.LABEL_DATE := NVL(C.LABEL_DATE, sysdate);
          else
            C.LABEL_DATE := sysdate;
          end if;
        else
          C.LABEL_DATE := null;
        end if;
        /* Актуализируем запись */
        P_DICPLACE_BASE_UPDATE(NCOMPANY        => C.COMPANY,
                               NRN             => C.RN,
                               SMNEMO          => NVL(SMNEMO, C.PLACE_MNEMO),
                               SNAME           => NVL(SNAME, C.PLACE_NAME),
                               SBARCODE        => NVL(SBARCODE, C.BARCODE),
                               DLABEL_DATE     => C.LABEL_DATE,
                               SCAD_NUMB       => C.CAD_NUMB,
                               NGEOGRAFY       => NVL(FIND_GEOGRAFY(NCOMPANY       => C.COMPANY,
                                                                    SADDR_COUNTRY  => SADDR_COUNTRY,
                                                                    SADDR_REGION   => SADDR_REGION,
                                                                    SADDR_LOCALITY => SADDR_LOCALITY,
                                                                    SADDR_STREET   => SADDR_STREET),
                                                      C.GEOGRAFY),
                               SADDR_HOUSE     => SADDR_HOUSE,
                               SADDR_BLOCK     => C.ADDR_BLOCK,
                               SADDR_BUILDING  => C.ADDR_BUILDING,
                               SADDR_FLAT      => C.ADDR_FLAT,
                               SADDR_POST      => SADDR_POSTCODE,
                               SPLACE_DESCRIPT => C.PLACE_DESCRIPT,
                               SAOID           => null,
                               SAOGUID         => null,
                               SHOUSEID        => null,
                               SHOUSEGUID      => null);
        /* Выставим ДС с широтой */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ObjPlace',
                                      NPROPERTY   => NPROP_LATITUDE,
                                      SSTR_VALUE  => SLATITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* Выставим ДС с долготой */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ObjPlace',
                                      NPROPERTY   => NPROP_LONGITUDE,
                                      SSTR_VALUE  => SLONGITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
      end loop;
      /* Аккуратно считываем штрих-код местонахождения */
      begin
        select T.BARCODE into SDICPLACE_BARCODE from DICPLACE T where T.RN = NDICPLACE;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NDICPLACE, SUNIT_TABLE => 'DICPLACE');
      end;
    end PROCESS_DICPLACE;
    
    /* Обрабатываем ОС - поиск и при необходимости добавление позиции ведомости инвентаризации с импортируемым ОС */
    procedure PROCESS_INVENTORY
    (
      RELINVENTORY          in ELINVENTORY%rowtype, -- Запись обрабатываемой ведомости
      SBARCODE              in varchar2,            -- Штрих-код ОС
      SINV_NUMBER           in varchar2,            -- Инвентарный номер ОС
      NELINVOBJECT          out number              -- Рег. номер позиции ведомости инвентаризации
    )
    is
      NINVENTORY            PKG_STD.TREF;           -- Рег. номер ОС (карточки "Инвентарной картотеки")    
    begin
      /* Ищем позицию ведомости по штрих-коду ОС */
      begin
        select T.RN
          into NELINVOBJECT
          from ELINVOBJECT T
         where T.COMPANY = RELINVENTORY.COMPANY
           and T.PRN = RELINVENTORY.RN
           and UTL_ELINVOBJECT_BARCODE_GET(T.RN) = SBARCODE;
      exception
        when NO_DATA_FOUND then
          /* Не нашли позицию ведомости инвентаризации */
          begin
            /* Ищем рег. номер ИК по штрих-коду */
            select T.RN
              into NINVENTORY
              from INVENTORY T
             where T.BARCODE = SBARCODE
               and T.COMPANY = RELINVENTORY.COMPANY;
            /* Добавляем её в ведомость инвентаризации */
            P_ELINVOBJECT_BASE_INSERT(NCOMPANY     => RELINVENTORY.COMPANY,
                                      NPRN         => RELINVENTORY.RN,
                                      NINVENTORY   => NINVENTORY,
                                      NINVSUBST    => null,
                                      NINVPACK     => null,
                                      DUNLOAD_DATE => null,
                                      DINV_DATE    => null,
                                      NINVPERSONS  => null,
                                      SBARCODE     => null,
                                      NIS_LOADED   => 1,
                                      NRN          => NELINVOBJECT);
          exception
            when NO_DATA_FOUND then
              begin
                /* Ищем рег. номер ИК по инвентарному номеру */
                select T.RN
                  into NINVENTORY
                  from INVENTORY T
                 where trim(T.INV_NUMBER) = trim(SINV_NUMBER)
                   and T.COMPANY = RELINVENTORY.COMPANY;
                /* Добавляем её в ведомость инвентаризации */
                P_ELINVOBJECT_BASE_INSERT(NCOMPANY     => RELINVENTORY.COMPANY,
                                          NPRN         => RELINVENTORY.RN,
                                          NINVENTORY   => NINVENTORY,
                                          NINVSUBST    => null,
                                          NINVPACK     => null,
                                          DUNLOAD_DATE => null,
                                          DINV_DATE    => null,
                                          NINVPERSONS  => null,
                                          SBARCODE     => null,
                                          NIS_LOADED   => 1,
                                          NRN          => NELINVOBJECT);
              exception
                when NO_DATA_FOUND then
                  P_EXCEPTION(0,
                              'Инвентарная карточка с штрих-кодом "%s" не найдена.',
                              SBARCODE);
              end;
          end;
      end;
    end PROCESS_INVENTORY;
    
    /* Обрабатываем элемент ведомости */
    procedure PROCESS_ELINVOBJECT
    (
      RELINVENTORY          in ELINVENTORY%rowtype, -- Запись обрабатываемой ведомости
      NELINVOBJECT          in number,              -- Рег. номер элемента ведомости инвентаризации
      NINVPERSONS           in number,              -- Рег. номер инвентаризирующего лица
      DINV_DATE             in date,                -- Дата проведения инвентаризации
      SBARCODE              in varchar2,            -- Штрих-код местонахождения
      SITEM_COMMENT         in varchar2,            -- Комментарий инвентаризирующего лица
      NITEM_DISTANCE        in number,              -- Расстояние ОС до местонахождения
      SITEM_LATITUDE        in varchar2,            -- Широта ОС
      SITEM_LONGITUDE       in varchar2,            -- Долгота ОС
      NITEM_QUANTITY        in number               -- Количество ОС
    )
    is
      NPROP_COMMENT         PKG_STD.TREF;           -- Рег. номер ДС для хранения комментария
      NPROP_DISTANCE        PKG_STD.TREF;           -- Рег. номер ДС для хранения расстояния до местонахождения (метров)
      NPROP_LATITUDE        PKG_STD.TREF;           -- Рег. номер ДС для хранения широты
      NPROP_LONGITUDE       PKG_STD.TREF;           -- Рег. номер ДС для хранения долготы
      NPROP_QUANTITY        PKG_STD.TREF;           -- Рег. номер ДС для хранения количества
      NTMP                  PKG_STD.TREF;           -- Буфер для рег. номеров
    begin
      /* Инициализируем ДС для хранения примечания */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'COMMENT',
                           NRN         => NPROP_COMMENT);
      /* Инициализируем ДС для хранения расстояния до местонахождения */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'DISTANCE',
                           NRN         => NPROP_DISTANCE);
      /* Инициализируем ДС для хранения широты */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'LATITUDE',
                           NRN         => NPROP_LATITUDE);
      /* Инициализируем ДС для хранения долготы */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'LONGITUDE',
                           NRN         => NPROP_LONGITUDE);
      /* Инициализируем ДС для хранения количества */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'QUANTITY',
                           NRN         => NPROP_QUANTITY);
      /* Обратимся к обрабатываемой позиции ведомости инвентаризации */
      for C in (select T.* from ELINVOBJECT T where T.RN = NELINVOBJECT)
      loop
        /* Обновим позицию ведомости инвентаризации */        
        P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => C.COMPANY,
                                  NRN          => C.RN,
                                  DUNLOAD_DATE => C.UNLOAD_DATE,
                                  DINV_DATE    => DINV_DATE,
                                  NINVPERSONS  => NINVPERSONS,
                                  SBARCODE     => SBARCODE,
                                  NIS_LOADED   => C.IS_LOADED);
        /* Выставим ДС с примечанием */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_COMMENT,
                                      SSTR_VALUE  => SITEM_COMMENT,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* Выставим ДС с дистанцией */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_DISTANCE,
                                      SSTR_VALUE  => null,
                                      NNUM_VALUE  => NITEM_DISTANCE,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* Выставим ДС с широтой */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_LATITUDE,
                                      SSTR_VALUE  => SITEM_LATITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* Выставим ДС с долготой */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_LONGITUDE,
                                      SSTR_VALUE  => SITEM_LONGITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* Выставим ДС с количеством */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_QUANTITY,
                                      SSTR_VALUE  => null,
                                      NNUM_VALUE  => NITEM_QUANTITY,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
      end loop;
    end PROCESS_ELINVOBJECT;

  begin
    begin
      /* Считываем корневой элемент тела посылки */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* Считываем идентификатор устройства */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* Считываем "Регистрационный номер ведомости" (параметр сохранения) */
      NREQ_SHEET_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* Считываем "Регистрационный номер МОЛ" (параметр сохранения) */
      NREQ_USER_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_USERCODE));
      /* Считываем "Мнемокод местонахождения" (параметр сохранения) */
      SREQ_STORAGE_MNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEMNEMOCODE);
      /* Считываем "Признак нового местонахождения" (параметр сохранения) */
      NREQ_STORAGE_ISNEW := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEISNEW));
      /* Считываем "Штрих-код местонахождения" (параметр сохранения) */
      SREQ_STORAGE_CODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECODE);
      /* Считываем "Наименование местонахождения" (параметр сохранения) */
      SREQ_STORAGE_NAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGENAME);
      /* Считываем "Почтовый индекс местонахождения" (параметр сохранения) */
      SREQ_STORAGE_POSTCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEPOSTCODE);
      /* Считываем "Страна местонахождения" (параметр сохранения) */
      SREQ_STORAGE_COUNTRY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECOUNTRY);
      /* Считываем "Регион местонахождения" (параметр сохранения) */
      SREQ_STORAGE_REGION := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEREGION);
      /* Считываем "Населенный пункт местонахождения" (параметр сохранения) */
      SREQ_STORAGE_LOCALITY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELOCALITY);
      /* Считываем "Улица местонахождения" (параметр сохранения) */
      SREQ_STORAGE_STREET := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGESTREET);
      /* Считываем "Номер дома местонахождения" (параметр сохранения) */
      SREQ_STORAGE_HOUSE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEHOUSENUMBER);
      /* Считываем "Широта местонахождения" (параметр сохранения) */
      SREQ_STORAGE_LATITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELATITUDE);
      /* Считываем "Долгота местонахождения" (параметр сохранения) */
      SREQ_STORAGE_LONGITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELONGITUDE);
      /* Считываем "Штрих-код ОС" (параметр сохранения) */
      SREQ_ITEM_CODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMCODE);
      /* Считываем "Наименование номенклатуры ОС" (параметр сохранения) */
      SREQ_ITEM_NAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNAME);
      /* Считываем "Мнемокод номенклатуры ОС" (параметр сохранения) */
      SREQ_ITEM_MNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMMNEMOCODE);
      /* Считываем "Инвентарный номер ОС" (параметр сохранения) */
      SREQ_ITEM_NUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNUMBER);
      /* Считываем "Количество ОС" (параметр сохранения) */
      NREQ_ITEM_QUANTITY := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_QUANTITY));
      /* Считываем "Дата проведения инвентаризации ОС" (параметр сохранения) */
      DREQ_ITEM_CHECKDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_CHECKDATE),
                                     'YYYY-MM-DD"T"HH24:MI:SS');
      /* Считываем "Комментарий МОЛ ОС" (параметр сохранения) */
      SREQ_ITEM_COMMENT := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_COMMENT);
      /* Считываем "Широта ОС" (параметр сохранения) */
      SREQ_ITEM_LATITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LATITUDE);
      /* Считываем "Долгота ОС" (параметр сохранения) */
      SREQ_ITEM_LONGITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LONGITUDE);
      /* Считываем "Расстояние до местонахождения ОС" (параметр сохранения) */
      NREQ_ITEM_DISTANCE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DISTANCETOSTORAGE));
      /* Контроль индетификатора устройства по лицензии */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* Подготавливаем документ для ответа */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* Работаем только если указан регистрационный номер ведомости */
      if (NREQ_SHEET_CODE is not null) then
        /* Считаем запись ведомости инвентаризации */
        begin
          select T.* into RELINVENTORY from ELINVENTORY T where T.RN = NREQ_SHEET_CODE;
        exception
          when NO_DATA_FOUND then
            PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NREQ_SHEET_CODE, SUNIT_TABLE => 'ELINVENTORY');
        end;
        /* Обрабатываем местонахождение */
        begin
          PROCESS_DICPLACE(NCOMPANY          => RELINVENTORY.COMPANY,
                           NIS_NEW           => NREQ_STORAGE_ISNEW,
                           SMNEMO            => SREQ_STORAGE_MNEMOCODE,
                           SNAME             => SREQ_STORAGE_NAME,
                           SBARCODE          => SREQ_STORAGE_CODE,
                           SADDR_POSTCODE    => SREQ_STORAGE_POSTCODE,
                           SADDR_COUNTRY     => SREQ_STORAGE_COUNTRY,
                           SADDR_REGION      => SREQ_STORAGE_REGION,
                           SADDR_LOCALITY    => SREQ_STORAGE_LOCALITY,
                           SADDR_STREET      => SREQ_STORAGE_STREET,
                           SADDR_HOUSE       => SREQ_STORAGE_HOUSE,
                           SLATITUDE         => SREQ_STORAGE_LATITUDE,
                           SLONGITUDE        => SREQ_STORAGE_LONGITUDE,
                           SDICPLACE_BARCODE => SDICPLACE_BARCODE);
        exception
          when others then
            SERR_DICPLACE := sqlerrm;
        end;
        /* Если метонахождение обработано успешно */
        if (SERR_DICPLACE is null) then
          begin
            /* Обрабатываем ОС */
            PROCESS_INVENTORY(RELINVENTORY => RELINVENTORY,
                              SBARCODE     => SREQ_ITEM_CODE,
                              SINV_NUMBER  => SREQ_ITEM_NUMBER,
                              NELINVOBJECT => NELINVOBJECT);
            /* Обрабатываем элемент ведомости */
            PROCESS_ELINVOBJECT(RELINVENTORY    => RELINVENTORY,
                                NELINVOBJECT    => NELINVOBJECT,
                                NINVPERSONS     => NREQ_USER_CODE,
                                DINV_DATE       => DREQ_ITEM_CHECKDATE,
                                SBARCODE        => SDICPLACE_BARCODE,
                                SITEM_COMMENT   => SREQ_ITEM_COMMENT,
                                NITEM_DISTANCE  => NREQ_ITEM_DISTANCE,
                                SITEM_LATITUDE  => SREQ_ITEM_LATITUDE,
                                SITEM_LONGITUDE => SREQ_ITEM_LONGITUDE,
                                NITEM_QUANTITY  => NREQ_ITEM_QUANTITY);
          exception
            when others then
              SERR_ELINVOBJECT := sqlerrm;
          end;
        else
          SERR_ELINVOBJECT := 'Возникли ошибки при обработке места хранения';
        end if;
      else
        P_EXCEPTION(0, 'В запросе не указан идентификатор ведомости.');
      end if;
      /* Если ошибок нет - возвращаем положительный ответ */
      if ((SERR_ELINVOBJECT is null) and (SERR_DICPLACE is null)) then
        /* Создаём пространство имён для ответа */
        XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_SAVESHEETITEMRSPNS, SNS => SNS_TSD);
        /* Формируем результат */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_RESULT, SNS => SNS_TSD, SVAL => 'true');
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
        /* Оборачиваем ответ в конверт */
        CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
      else
        /* Были ошибки - вернём их */
        CRESPONSE := UTL_CREATEERRORRESPONSE_SSITEM(SMSG_ELINVOBJECT => UTL_CORRECT_ERR(SERR => SERR_ELINVOBJECT),
                                                    SMSG_DICPLACE    => UTL_CORRECT_ERR(SERR => SERR_DICPLACE));
      end if;
    exception
      /* Перехватываем возможные необработанные ранее ошибки */
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
