create or replace package UDO_PKG_EXS_INV as

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

  /* Константы - тэги */
  STSD                      constant varchar2(40) := 'tsd';
  SCHECKAUTHRESPONSE        constant varchar2(40) := 'CheckAuthResponse';
  SGETUSERSRESPONSE         constant varchar2(40) := 'GetUsersResponse';
  SGETSHEETTYPESRESPONSE    constant varchar2(40) := 'GetSheetTypesResponse';
  SGETSHEETSRESPONSE        constant varchar2(40) := 'GetSheetsResponse';
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
    XMAIN_NODE              DBMS_XMLDOM.DOMNODE;
    XENVELOPE_EL            DBMS_XMLDOM.DOMELEMENT;
    XENVELOPE               DBMS_XMLDOM.DOMNODE;
    XHEADER                 DBMS_XMLDOM.DOMNODE;
    XBODY                   DBMS_XMLDOM.DOMNODE;
    XNODE                   DBMS_XMLDOM.DOMNODE;
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
    SREQDEVICEID            varchar2(30);            -- Идентификатор устройства из запроса
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
    SREQDEVICEID            varchar2(30);            -- Идентификатор устройства из запроса
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
    SREQDEVICEID            varchar2(30);            -- Идентификатор устройства из запроса
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
      /* Обходим типы документов связанные с разделом "Электронные инвенторизации" */
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
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
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
    SREQDEVICEID            varchar2(30);            -- Идентификатор устройства из запроса
    NREQTYPECODE            number(17);              -- Тип ведомости из запроса (параметр отбора)
    SREQPREFIX              varchar2(30);            -- Префикс ведомости из запроса (параметр отбора)
    SREQNUMBER              varchar2(30);            -- Номер ведомости из запроса (параметр отбора)
    DREQDATE                date;                    -- Дата ведомости из запроса (параметр отбора)
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
      /* Обходим типы документов связанные с разделом "Электронные инвенторизации" */
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
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end GETSHEETITEMS;
  
  /* Электронная инвентаризация - считывание мест хранения */
  procedure GETSTORAGES
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end GETSTORAGES;

  /* Электронная инвентаризация - сохранение результатов инвентаризации */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end SAVESHEETITEM; 

end;
/
