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

end;
/
create or replace package body UDO_PKG_EXS_TEST as

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
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Кладём конвертированное обратно (просто для удобства мониторинга) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* Если есть что искать */
    if (CTMP is not null) then
      /* Инициализируем ответ */
      CRESP := 'Контрагент "' || CTMP || '" не найден';
      /* Ищем запрошенного контрагента */
      for C in (select T.AGNNAME ||
                       DECODE(T.AGNTYPE, 1, ', физическое лицо', ', юридическое лицо') SAGENT,
                       (select count(CN.RN) from CONTRACTS CN where CN.AGENT = T.RN) NCNT_CONTRACTS,
                       (select sum(CN.DOC_SUM) from CONTRACTS CN where CN.AGENT = T.RN) NSUM_CONTRACTS
                  from AGNLIST T
                 where ((STRINLIKE(LOWER(T.AGNABBR), '%' || LOWER(replace(CTMP, ' ', '% %')) || '%', ' ') <> 0) or
                       (STRINLIKE(LOWER(T.AGNNAME), '%' || LOWER(replace(CTMP, ' ', '% %')) || '%', ' ') <> 0))
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
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Кладём конвертированное обратно (просто для удобства мониторинга) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* Если есть что искать */
    if (CTMP is not null) then
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
         where ((STRINLIKE(LOWER(T.EXT_NUMBER), '%' || LOWER(replace(CTMP, ' ', '% %')) || '%', ' ') <> 0) or
               (STRINLIKE(LOWER(trim(T.DOC_PREF) || trim(T.DOC_NUMB)),
                           '%' || LOWER(replace(CTMP, ' ', '% %')) || '%',
                           ' ') <> 0))
           and T.AGENT = AG.RN
           and T.CURRENCY = CN.RN
           and ROWNUM <= 1;
      exception
        when NO_DATA_FOUND then
          CRESP := 'Договор "' || CTMP || '" не найден';
      end;
    else
      CRESP := 'Не указан поисковый запрос';
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end RESP_FIND_CONTRACT;

end;
/
