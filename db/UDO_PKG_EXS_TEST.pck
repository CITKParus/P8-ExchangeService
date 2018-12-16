create or replace package UDO_PKG_EXS_TEST as

  /* Запросить контрагента */
  procedure RECIVE_AGENT
  (
    NREMOTE_AGENT           in number   -- Рег. номер контрагента в удалённой БД
  );
  
  /* Обработка ответа с информацией о контрагенте от тестового стенда */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Обработка запроса на создание сессии */
  procedure RESP_LOGIN
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Обработка запроса на поиск контрагента */
  procedure RESP_FIND_AGENT
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Обработка запроса на поиск договора */
  procedure RESP_FIND_CONTRACT
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );  
  
  /* Электронная инвентаризация - аутентификация */
  procedure INV_CHECKAUTH_XML
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
  /* Электронная инвентаризация - считывание пользователей */
  procedure INV_GETUSERS_XML
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* Тип данных для коллекции шаблонов вспомогательных слов поиска */
  type THELPER_PATTERNS is table of varchar2(4000);

  /* Проверка на присутствие слова в списке вспомогательных */
  function UTL_HELPER_CHECK
  (
    SWORD                   in varchar2,        -- Проверяемое слово
    HELPER_PATTERNS         in THELPER_PATTERNS -- Коллекция шаблонов вспомогательных слов
  ) 
  return                    boolean             -- Резульата проверки
  is
    BRES                    boolean;            -- Буфер для результата
  begin
    /* Инициализируем буфер */
    BRES := false;
    /* Если коллекция не пуста */
    if ((HELPER_PATTERNS is not null) and (HELPER_PATTERNS.COUNT > 0)) then
      /* Обходим её */
      for I in HELPER_PATTERNS.FIRST .. HELPER_PATTERNS.LAST
      loop
        /* Если слово есть в коллекции */
        if (LOWER(SWORD) like LOWER(HELPER_PATTERNS(I))) then
          /* Выставим флаг присутствия и завершим поиск */
          BRES := true;
          exit;
        end if;
      end loop;
    end if;
    /* Возвращаем ответ */
    return BRES;
  end UTL_HELPER_CHECK;
  
  /* Инициализация общих вспомогательных поисковых фраз */
  procedure UTL_HELPER_INIT_COMMON
  (
    HELPER_PATTERNS         in out THELPER_PATTERNS -- Коллекция шаблонов вспомогательных слов
  )
  is
  begin
    /* Создадим пустую коллекцию если надо */
    if (HELPER_PATTERNS is null) then
      HELPER_PATTERNS := THELPER_PATTERNS();
    end if;
    /* Наполним её общими поисковыми вспомогательными фразами */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'расскажи';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'про';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'о';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'об';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'по';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'сведения';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'информацию';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'информация';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'информации';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'инфы';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'инфу';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'дай';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'нарой';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'запроси';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'найди';
  end UTL_HELPER_INIT_COMMON;
  
  /* Подготовка поисковой фразы к участию в выборке */
  function UTL_SEARCH_STR_PREPARE
  (
    SSEARCH_STR             in varchar2,        -- Поисковая фраза
    SDELIM                  in varchar2,        -- Разделитель слов в поисковой фразе
    HELPER_PATTERNS         in THELPER_PATTERNS -- Коллекция шаблонов вспомогательных слов
  ) 
  return                    varchar2            -- Подготовленная поисковая фраза
  is
    SRES                    varchar2(32000);    -- Результат работы
  begin
    /* Обходим слова поисковой фразы */
    for W in (select REGEXP_SUBSTR(T.STR, '[^' || SDELIM || ']+', 1, level) SWRD
                from (select replace(replace(SSEARCH_STR, ',', ''), '.', '') STR from DUAL) T
              connect by INSTR(T.STR, SDELIM, 1, level - 1) > 0)
    loop
      /* Если слово не в списке вспомогательных */
      if (not UTL_HELPER_CHECK(SWORD => W.SWRD, HELPER_PATTERNS => HELPER_PATTERNS)) then
        /* Оставляем его в итоговой выборке */
        SRES := SRES || '%' || W.SWRD;
      end if;
    end loop;
    /* Уберем лишние пробелы и готовим для поиска */
    SRES := '%' || trim(SRES) || '%';
    /* Вернем ответ */
    return SRES;
  end UTL_SEARCH_STR_PREPARE;
  
  /* Запросить контрагента */
  procedure RECIVE_AGENT
  (
    NREMOTE_AGENT           in number               -- Рег. номер контрагента в удалённой БД
  )
  is
    SEXSSERVICEFN           EXSSERVICEFN.CODE%type; -- Мнемокод функции сервиса
    NEXSSERVICEFN           EXSSERVICEFN.RN%type;   -- Рег. номер функции сервиса
    RCTMP                   sys_refcursor;          -- Буфер для измененной позиции очереди
  begin
    /* Инициализируем мнемокод функции сервиса */
    SEXSSERVICEFN := 'ПолучениеКонтрагента';
    /* Найдем рег. номер функции сервиса */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICEFN, NRN => NEXSSERVICEFN);
    /* Поместим задание в очередь */
    PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => NEXSSERVICEFN,
                      BMSG          => CLOB2BLOB(LCDATA => 'CPRMS={SACTION:"GET_AGENT",NAGENT:' || TO_CHAR(NREMOTE_AGENT) || '}'),
                      RCQUEUE       => RCTMP);
  end RECIVE_AGENT;
  
  /* Обработка ответа с информацией о контрагенте от тестового стенда */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,            -- Идентификатор процесса
    NSRV_TYPE               in number,            -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number             -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    CTMP                    clob;                 -- Буфер для конвертации
    RCTMP                   sys_refcursor;        -- Буфер для измененной позиции очереди
    NCOMPANY                PKG_STD.TREF;         -- Рег. номер организации
    NCRN                    PKG_STD.TREF;         -- Рег. номер каталога
    SAGNABBR                AGNLIST.AGNABBR%type; -- Мнемокод контрагента
    SAGNNAME                AGNLIST.AGNNAME%type; -- Наименование контрагента
    NAGENT                  AGNLIST.RN%type;      -- Рег. номер добавленного контрагента
  begin
    /* Инициализируем организацию */
    NCOMPANY := 136018;
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    /* Кладём конвертированное обратно (просто для удобства мониторинга) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* Разбираем ответ сервера */
    if (CTMP is not null) then
      select EXTRACTVALUE(XMLTYPE(CTMP), '/AGENT/SAGNABBR') SAGNABBR,
             EXTRACTVALUE(XMLTYPE(CTMP), '/AGENT/SAGNNAME') SAGNNAME
        into SAGNABBR,
             SAGNNAME
        from DUAL;
    else
      P_EXCEPTION(0, 'Не указаны данные для добавления контрагента.');
    end if;
    if (SAGNABBR is null) then
      P_EXCEPTION(0, 'В ответе сервера не указан мнемокод контрагента.');
    end if;
    if (SAGNNAME is null) then
      P_EXCEPTION(0,
                  'В ответе сервера не указано наименование контрагента.');
    end if;
    /* Найдём каталог */
    FIND_ACATALOG_NAME(NFLAG_SMART => 0,
                       NCOMPANY    => NCOMPANY,
                       NVERSION    => null,
                       SUNITCODE   => 'AGNLIST',
                       SNAME       => 'ExchangeService',
                       NRN         => NCRN);
    /* Регистрируем контрагента */
    P_AGNLIST_BASE_INSERT(NCOMPANY => NCOMPANY,
                          NCRN     => NCRN,
                          SAGNABBR => SUBSTR(NIDENT || SAGNABBR, 1, 20),
                          SAGNNAME => SAGNNAME || ' ' || NIDENT,
                          NRN      => NAGENT);
  exception
    when others then
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT, SARG => PKG_EXS.SCONT_FLD_SERR, SVALUE => sqlerrm);
  end PROCESS_AGN_INFO_RESP;
  
  /* Обработка запроса на создание сессии */
  procedure RESP_LOGIN
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
    SUSER                   PKG_STD.TSTRING;  -- Имя пользователя
    SPASS                   PKG_STD.TSTRING;  -- Пароль пользователя
    SCOMPANY                PKG_STD.TSTRING;  -- Наименование организации
    SCONNECT                PKG_STD.TSTRING;  -- Идентификатор сесии
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Кладём конвертированное обратно (просто для удобства мониторинга) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* Извлекаем логин и пароль */
    if (CTMP is not null) then
      select EXTRACTVALUE(XMLTYPE(CTMP), '/auth/user') SUSER,
             EXTRACTVALUE(XMLTYPE(CTMP), '/auth/pass') SPASS,
             EXTRACTVALUE(XMLTYPE(CTMP), '/auth/company') SCOMP
        into SUSER,
             SPASS,
             SCOMPANY
        from DUAL;
    else
      P_EXCEPTION(0, 'Не указаны данные для аутентификации.');
    end if;
    /* Если и логин и пароль и организация есть */
    if ((SUSER is not null) and (SPASS is not null) and (SCOMPANY is not null)) then
      /* Формируем идентификатор сесии */
      SCONNECT := SYS_GUID();
      /* Создаём сессию */
      PKG_SESSION.LOGON_WEB(SCONNECT        => SCONNECT,
                            SUTILIZER       => SUSER,
                            SPASSWORD       => SPASS,
                            SIMPLEMENTATION => 'Other',
                            SAPPLICATION    => 'Other',
                            SCOMPANY        => SCOMPANY);
      /* Выставляем результат обработки */
      PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                    SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                    BVALUE => CLOB2BLOB(LCDATA => SCONNECT, SCHARSET => 'UTF8'));
    
    else
      P_EXCEPTION(0, 'Не указано имя пользователя, пароль или организация.');
    end if;
  exception
    when others then
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT, SARG => PKG_EXS.SCONT_FLD_SERR, SVALUE => sqlerrm);
  end RESP_LOGIN;
  
  /* Обработка запроса на поиск контрагента */
  procedure RESP_FIND_AGENT
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- Коллекция шаблонов вспомогательных слов поиска
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
 begin
   /* Считаем запись очереди */
   REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
   /* Инициализируем коллекцию слов-помошников */
   UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
   /* Наполняем её значениями индивидуальными для данного запроса */
   HELPER_PATTERNS.EXTEND();
   HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'контрагент%';
   /* Забираем данные сообщения и конвертируем в кодировку БД */
   CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
   /* Кладём конвертированное обратно (просто для удобства мониторинга) */
   PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
   /* Если есть что искать */
   if (CTMP is not null) then
     /* Подготовим поисковую фразу */
     CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
     /* Инициализируем ответ */
     CRESP := 'Контрагент не найден';
     /* Ищем запрошенного контрагента */
     for C in (select T.AGNNAME ||
                      DECODE(T.AGNTYPE, 1, ', физическое лицо', ', юридическое лицо') SAGENT,
                      (select count(CN.RN) from CONTRACTS CN where CN.AGENT = T.RN) NCNT_CONTRACTS,
                      (select sum(CN.DOC_SUM) from CONTRACTS CN where CN.AGENT = T.RN) NSUM_CONTRACTS
                 from AGNLIST T
                where ((LOWER(T.AGNABBR) like LOWER(CTMP)) or (LOWER(T.AGNNAME) like LOWER(CTMP)))
                  and ROWNUM <= 1)
     loop
       CRESP := C.SAGENT;
       if (C.NCNT_CONTRACTS = 0) then
         CRESP := CRESP || ', не имеет зарегистрированных в системе договоров';
       else
         CRESP := CRESP || ', зарегистрировано договоров: ' || TO_CHAR(C.NCNT_CONTRACTS);
         if (C.NSUM_CONTRACTS <> 0) then
           CRESP := CRESP || ', на общую сумму: ' || TO_CHAR(C.NSUM_CONTRACTS) || ' руб.';
         end if;
       end if;
     end loop;
   else
     CRESP := 'Не указан поисковый запрос';
   end if;
   /* Возвращаем ответ */
   PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                 SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                 BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
 end RESP_FIND_AGENT;

  /* Обработка запроса на поиск договора */
  procedure RESP_FIND_CONTRACT
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- Коллекция шаблонов вспомогательных слов поиска
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Инициализируем коллекцию слов-помошников */
    UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
    /* Наполняем её значениями индивидуальными для данного запроса */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'договор%';
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Кладём конвертированное обратно (просто для удобства мониторинга) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* Если есть что искать */
    if (CTMP is not null) then
      /* Подготовим поисковую фразу */
      CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
      /* Ищем запрошенный договор */
      begin
        select DECODE(T.INOUT_SIGN, 0, 'Входящий', 'Исходящий') || ' договор №' ||
               NVL(T.EXT_NUMBER, trim(T.DOC_PREF) || '-' || trim(T.DOC_NUMB)) || ' от ' ||
               TO_CHAR(T.DOC_DATE, 'dd.mm.yyyy') || ' с контрагентом ' || AG.AGNNAME || ' на сумму ' ||
               TO_CHAR(T.DOC_SUM) || ' ' || CN.INTCODE || ', оплачено ' || TO_CHAR(T.FACT_OUTPAY_SUM) || ' ' ||
               CN.INTCODE SDOC
          into CRESP
          from CONTRACTS T,
               AGNLIST   AG,
               CURNAMES  CN
         where ((LOWER(T.EXT_NUMBER) like LOWER(CTMP)) or
               (LOWER(trim(T.DOC_PREF) || trim(T.DOC_NUMB)) like LOWER(CTMP)))
           and T.AGENT = AG.RN
           and T.CURRENCY = CN.RN
           and ROWNUM <= 1;
      exception
        when NO_DATA_FOUND then
          CRESP := 'Договор не найден';
      end;
    else
      CRESP := 'Не указан поисковый запрос';
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end RESP_FIND_CONTRACT;
  
  /* Электронная инвентаризация - аутентификация */
  procedure INV_CHECKAUTH_XML
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    /**/
    SREQDEVICEID       varchar2(30);
    XCHECKAUTHRESPONSE DBMS_XMLDOM.DOMNODE;
    XRESULT            DBMS_XMLDOM.DOMNODE;
    XNODE              DBMS_XMLDOM.DOMNODE;
    CRESPONSE          clob;
    XDOC DBMS_XMLDOM.DOMDOCUMENT;
    /**/
    XMLPARCER DBMS_XMLPARSER.PARSER;
    XENVELOPE DBMS_XMLDOM.DOMNODE;
    XBODY     DBMS_XMLDOM.DOMNODE;
    XNODELIST DBMS_XMLDOM.DOMNODELIST;
    XNODE_ROOT     DBMS_XMLDOM.DOMNODE;
    SNODE     varchar2(100);   
    CREQ      clob; 
    /**/
    STSD constant varchar2(20) := 'tsd';
    SCHECKAUTHRESPONSE constant varchar2(20) := 'CheckAuthResponse';
    SDEVICEID constant varchar2(20) := 'DeviceID';
    SRESULT constant varchar2(20) := 'Result';
    SSOAPENV constant varchar2(20) := 'soapenv';
    SENVELOPE constant varchar2(20) := 'Envelope';
    SHEADER constant varchar2(20) := 'Header';
    SBODY constant varchar2(20) := 'Body';
    /* Создание ветки XML */    
    function CREATENODE
    (
      STAG in varchar2,
      SNS  in varchar2 default null,
      SVAL in varchar2 default null
    ) return DBMS_XMLDOM.DOMNODE is
      XEL   DBMS_XMLDOM.DOMELEMENT;
      XNODE DBMS_XMLDOM.DOMNODE;
      XTEXT DBMS_XMLDOM.DOMNODE;
    begin
      if SNS is not null then
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG, NS => SNS);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
        DBMS_XMLDOM.SETPREFIX(N => XNODE, PREFIX => SNS);
      else
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
      end if;
      if SVAL is not null then
        XTEXT := DBMS_XMLDOM.APPENDCHILD(XNODE, DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(XDOC, SVAL)));
      end if;
      return XNODE;
    end;
    /* Считывание значения ветки XML */
    function GETNODEVAL
    (
      XROOTNODE in DBMS_XMLDOM.DOMNODE,
      SPATTERN  in varchar2
    ) return varchar2 is
      XNODE DBMS_XMLDOM.DOMNODE;
      SVAL  varchar2(100);
    begin
      XNODE := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XROOTNODE, PATTERN => SPATTERN);
      if DBMS_XMLDOM.ISNULL(XNODE) then
        return null;
      end if;
      SVAL := DBMS_XMLDOM.GETNODEVALUE(DBMS_XMLDOM.GETFIRSTCHILD(N => XNODE));
      return SVAL;
    end GETNODEVAL;
    /* Создание документа для ответа */
    procedure CREATERESPONSEDOC is
    begin
      XDOC := DBMS_XMLDOM.NEWDOMDOCUMENT;
      DBMS_XMLDOM.SETVERSION(XDOC
                            ,'1.0" encoding="UTF-8');
      DBMS_XMLDOM.SETCHARSET(XDOC
                            ,'UTF-8');
    end;
    /* Создание ответа */
    function CREATERESPONSE(XCONTENT in DBMS_XMLDOM.DOMNODE) return clob is
      XMAIN_NODE   DBMS_XMLDOM.DOMNODE;
      XENVELOPE_EL DBMS_XMLDOM.DOMELEMENT;
      XENVELOPE    DBMS_XMLDOM.DOMNODE;
      XHEADER      DBMS_XMLDOM.DOMNODE;
      XBODY        DBMS_XMLDOM.DOMNODE;
      XNODE        DBMS_XMLDOM.DOMNODE;
      CDATA        clob;
    begin
      -- Document
      XMAIN_NODE := DBMS_XMLDOM.MAKENODE(XDOC);
      -- Envelope
      XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => SENVELOPE, NS => SSOAPENV);
      DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                               name     => 'xmlns:soapenv',
                               NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
      DBMS_XMLDOM.SETATTRIBUTE(ELEM => XENVELOPE_EL, name => 'xmlns:tsd', NEWVALUE => 'http://www.example.org/TSDService/');
      XENVELOPE := DBMS_XMLDOM.MAKENODE(XENVELOPE_EL);
      DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SSOAPENV);
      XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
      -- Header
      XHEADER := CREATENODE(SHEADER, SSOAPENV);
      XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
      -- Body
      XBODY := CREATENODE(SBODY, SSOAPENV);
      XBODY := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XBODY);
      XNODE := DBMS_XMLDOM.APPENDCHILD(N => XBODY, NEWCHILD => XCONTENT);
      -- Создаем CLOB
      DBMS_LOB.CREATETEMPORARY(LOB_LOC => CDATA, CACHE => true, DUR => DBMS_LOB.SESSION);
      DBMS_XMLDOM.WRITETOCLOB(XDOC, CDATA, 'UTF-8');
      DBMS_XMLDOM.FREEDOCUMENT(DOC => XDOC);
      return CDATA;
    end;
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Конвертируем в кодировку БД */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
      -- Создаем инстанс XML парсера
      XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
      -- Считываем XML из запроса
      DBMS_XMLPARSER.PARSECLOB(XMLPARCER
                              ,CREQ);
      -- Берем XML документ
      XDOC := DBMS_XMLPARSER.GETDOCUMENT(XMLPARCER);
      -- Считываем Корневой элемент
      XENVELOPE := DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.GETDOCUMENTELEMENT(XDOC));
      -- Считываем элемент Body
      XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(XENVELOPE
                                                 ,SBODY);
      -- Считываем дочерние элементы к Body
      XNODELIST := DBMS_XMLDOM.GETCHILDNODES(XBODY);
      -- Берем первый дочерний элемент
      XNODE_ROOT := DBMS_XMLDOM.ITEM(XNODELIST
                               ,0);
      -- Считаем имя элемента
      DBMS_XMLDOM.GETLOCALNAME(XNODE_ROOT
                              ,SNODE);
    -- Считываем DeviceID
    SREQDEVICEID := GETNODEVAL(XNODE_ROOT
                              ,SDEVICEID);
    --CHECK_ID(SREQDEVICEID);
    CREATERESPONSEDOC();
    if SREQDEVICEID is not null
    then
      XCHECKAUTHRESPONSE := CREATENODE(SCHECKAUTHRESPONSE
                                      ,STSD);
      XRESULT            := CREATENODE(SRESULT
                                      ,STSD
                                      ,'true');
      XNODE              := DBMS_XMLDOM.APPENDCHILD(N        => XCHECKAUTHRESPONSE
                                                   ,NEWCHILD => XRESULT);
      CRESPONSE          := CREATERESPONSE(XCHECKAUTHRESPONSE);
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE));
  end;

  /* Электронная инвентаризация - считывание пользователей */
  procedure INV_GETUSERS_XML
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    /**/
    SREQDEVICEID       varchar2(30);
    XGETUSERSRESPONSE  DBMS_XMLDOM.DOMNODE;
    XITEM             DBMS_XMLDOM.DOMNODE;
    XCODE             DBMS_XMLDOM.DOMNODE;
    XNAME             DBMS_XMLDOM.DOMNODE;
    XNODE              DBMS_XMLDOM.DOMNODE;
    CRESPONSE          clob;
    XDOC DBMS_XMLDOM.DOMDOCUMENT;
    /**/
    XMLPARCER DBMS_XMLPARSER.PARSER;
    XENVELOPE DBMS_XMLDOM.DOMNODE;
    XBODY     DBMS_XMLDOM.DOMNODE;
    XNODELIST DBMS_XMLDOM.DOMNODELIST;
    XNODE_ROOT     DBMS_XMLDOM.DOMNODE;
    SNODE     varchar2(100);   
    CREQ      clob; 
    /**/
    STSD constant varchar2(20) := 'tsd';
    SGETUSERSRESPONSE constant varchar2(20) := 'GetUsersResponse';
    SDEVICEID constant varchar2(20) := 'DeviceID';
    SRESULT constant varchar2(20) := 'Result';
    SSOAPENV constant varchar2(20) := 'soapenv';
    SENVELOPE constant varchar2(20) := 'Envelope';
    SHEADER constant varchar2(20) := 'Header';
    SBODY constant varchar2(20) := 'Body';
    SITEM constant varchar2(20) := 'Item';
    SCODE constant varchar2(20) := 'Code'; 
    SNAME constant varchar2(20) := 'Name';   
    /* Создание ветки XML */    
    function CREATENODE
    (
      STAG in varchar2,
      SNS  in varchar2 default null,
      SVAL in varchar2 default null
    ) return DBMS_XMLDOM.DOMNODE is
      XEL   DBMS_XMLDOM.DOMELEMENT;
      XNODE DBMS_XMLDOM.DOMNODE;
      XTEXT DBMS_XMLDOM.DOMNODE;
    begin
      if SNS is not null then
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG, NS => SNS);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
        DBMS_XMLDOM.SETPREFIX(N => XNODE, PREFIX => SNS);
      else
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
      end if;
      if SVAL is not null then
        XTEXT := DBMS_XMLDOM.APPENDCHILD(XNODE, DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(XDOC, SVAL)));
      end if;
      return XNODE;
    end;
    /* Считывание значения ветки XML */
    function GETNODEVAL
    (
      XROOTNODE in DBMS_XMLDOM.DOMNODE,
      SPATTERN  in varchar2
    ) return varchar2 is
      XNODE DBMS_XMLDOM.DOMNODE;
      SVAL  varchar2(100);
    begin
      XNODE := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XROOTNODE, PATTERN => SPATTERN);
      if DBMS_XMLDOM.ISNULL(XNODE) then
        return null;
      end if;
      SVAL := DBMS_XMLDOM.GETNODEVALUE(DBMS_XMLDOM.GETFIRSTCHILD(N => XNODE));
      return SVAL;
    end GETNODEVAL;
    /* Создание документа для ответа */
    procedure CREATERESPONSEDOC is
    begin
      XDOC := DBMS_XMLDOM.NEWDOMDOCUMENT;
      DBMS_XMLDOM.SETVERSION(XDOC
                            ,'1.0" encoding="UTF-8');
      DBMS_XMLDOM.SETCHARSET(XDOC
                            ,'UTF-8');
    end;
    /* Создание ответа */
    function CREATERESPONSE(XCONTENT in DBMS_XMLDOM.DOMNODE) return clob is
      XMAIN_NODE   DBMS_XMLDOM.DOMNODE;
      XENVELOPE_EL DBMS_XMLDOM.DOMELEMENT;
      XENVELOPE    DBMS_XMLDOM.DOMNODE;
      XHEADER      DBMS_XMLDOM.DOMNODE;
      XBODY        DBMS_XMLDOM.DOMNODE;
      XNODE        DBMS_XMLDOM.DOMNODE;
      CDATA        clob;
    begin
      -- Document
      XMAIN_NODE := DBMS_XMLDOM.MAKENODE(XDOC);
      -- Envelope
      XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => SENVELOPE, NS => SSOAPENV);
      DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                               name     => 'xmlns:soapenv',
                               NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
      DBMS_XMLDOM.SETATTRIBUTE(ELEM => XENVELOPE_EL, name => 'xmlns:tsd', NEWVALUE => 'http://www.example.org/TSDService/');
      XENVELOPE := DBMS_XMLDOM.MAKENODE(XENVELOPE_EL);
      DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SSOAPENV);
      XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
      -- Header
      XHEADER := CREATENODE(SHEADER, SSOAPENV);
      XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
      -- Body
      XBODY := CREATENODE(SBODY, SSOAPENV);
      XBODY := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XBODY);
      XNODE := DBMS_XMLDOM.APPENDCHILD(N => XBODY, NEWCHILD => XCONTENT);
      -- Создаем CLOB
      DBMS_LOB.CREATETEMPORARY(LOB_LOC => CDATA, CACHE => true, DUR => DBMS_LOB.SESSION);
      DBMS_XMLDOM.WRITETOCLOB(XDOC, CDATA, 'UTF-8');
      DBMS_XMLDOM.FREEDOCUMENT(DOC => XDOC);
      return CDATA;
    end;
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Конвертируем в кодировку БД */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
      -- Создаем инстанс XML парсера
      XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
      -- Считываем XML из запроса
      DBMS_XMLPARSER.PARSECLOB(XMLPARCER
                              ,CREQ);
      -- Берем XML документ
      XDOC := DBMS_XMLPARSER.GETDOCUMENT(XMLPARCER);
      -- Считываем Корневой элемент
      XENVELOPE := DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.GETDOCUMENTELEMENT(XDOC));
      -- Считываем элемент Body
      XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(XENVELOPE
                                                 ,SBODY);
      -- Считываем дочерние элементы к Body
      XNODELIST := DBMS_XMLDOM.GETCHILDNODES(XBODY);
      -- Берем первый дочерний элемент
      XNODE_ROOT := DBMS_XMLDOM.ITEM(XNODELIST
                               ,0);
      -- Считаем имя элемента
      DBMS_XMLDOM.GETLOCALNAME(XNODE_ROOT
                              ,SNODE);
    -- Считываем DeviceID
    SREQDEVICEID := GETNODEVAL(XNODE_ROOT
                              ,SDEVICEID);
    --CHECK_ID(SREQDEVICEID);
    CREATERESPONSEDOC();
    if SREQDEVICEID is not null
    then
      XGETUSERSRESPONSE := CREATENODE(SGETUSERSRESPONSE
                                     ,STSD);
      for REC in (select T.RN
                        ,A.AGNABBR
                    from INVPERSONS T
                        ,AGNLIST    A
                   where T.COMPANY = 136018
                     and T.AGNLIST = A.RN)
      loop
        XITEM := CREATENODE(SITEM
                           ,STSD);
        XCODE := CREATENODE(SCODE
                           ,STSD
                           ,REC.RN);
        XNAME := CREATENODE(SNAME
                           ,STSD
                           ,REC.AGNABBR);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N        => XITEM
                                        ,NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N        => XITEM
                                        ,NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N        => XGETUSERSRESPONSE
                                        ,NEWCHILD => XITEM);
      end loop;
      CRESPONSE := CREATERESPONSE(XGETUSERSRESPONSE);
    end if;         
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE, sCHARSET => 'UTF8'));
  end;

end;
/
