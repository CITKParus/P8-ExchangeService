create or replace package UDO_PKG_EXS_INV as

  /* Электронная инвентаризация - аутентификация */
  procedure CHECKAUTH
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Электронная инвентаризация - считывание пользователей */
  procedure GETUSERS
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_INV as

  /* Константы - тэги */
  STSD                      constant varchar2(20) := 'tsd';
  SCHECKAUTHRESPONSE        constant varchar2(20) := 'CheckAuthResponse';
  SGETUSERSRESPONSE         constant varchar2(20) := 'GetUsersResponse';  
  SDEVICEID                 constant varchar2(20) := 'DeviceID';
  SRESULT                   constant varchar2(20) := 'Result';
  SSOAPENV                  constant varchar2(20) := 'soapenv';
  SENVELOPE                 constant varchar2(20) := 'Envelope';
  SHEADER                   constant varchar2(20) := 'Header';
  SBODY                     constant varchar2(20) := 'Body';
  SITEM                     constant varchar2(20) := 'Item';
  SCODE                     constant varchar2(20) := 'Code'; 
  SNAME                     constant varchar2(20) := 'Name';    
    
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
    NSRV_TYPE               in number,               -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
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
      CRESPONSE          := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XCHECKAUTHRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE));
  end CHECKAUTH;

  /* Электронная инвентаризация - считывание пользователей */
  procedure GETUSERS
  (
    NIDENT                  in number,               -- Идентификатор процесса
    NSRV_TYPE               in number,               -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
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
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  end GETUSERS;

end;
/
