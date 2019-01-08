create or replace package UDO_PKG_EXS_TEST as

  /* Обработка запроса на создание сессии */
  procedure UTL_LOGIN
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Запросить контрагента */
  procedure AGENT_GET_INFO
  (
    NCOMPANY                in number,  -- Рег. номер организации    
    NREMOTE_AGENT           in number   -- Рег. номер контрагента в удалённой БД
  );
  
  /* Обработка ответа с информацией о контрагенте от тестового стенда */
  procedure AGENT_PROCESS_INFO
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );
  
end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* Обработка запроса на создание сессии */
  procedure UTL_LOGIN
  (
    NIDENT                  in number,        -- Идентификатор процесса    
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
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                  SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                  BRESP   => CLOB2BLOB(LCDATA => SCONNECT, SCHARSET => 'UTF8'));
    else
      P_EXCEPTION(0,
                  'Не указано имя пользователя, пароль или организация.');
    end if;
  exception
    when others then
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end UTL_LOGIN;
  
  /* Запросить контрагента на удалённом сервере */
  procedure AGENT_GET_INFO
  (
    NCOMPANY                in number,              -- Рег. номер организации
    NREMOTE_AGENT           in number               -- Рег. номер контрагента в удалённой БД
  )
  is
    RCTMP                   sys_refcursor;          -- Буфер для измененной позиции очереди
  begin
    /* Поместим задание в очередь */
    PKG_EXS.QUEUE_PUT(SEXSSERVICE   => 'ТестовыйСтенд',
                      SEXSSERVICEFN => 'ПолучениеКонтрагента',
                      BMSG          => CLOB2BLOB(LCDATA => '{"SACTION":"GET_AGENT","NAGENT":' || TO_CHAR(NREMOTE_AGENT) ||
                                                           ',"NCOMPANY":' || TO_CHAR(NCOMPANY) || '}'),
                      RCQUEUE       => RCTMP);
  end AGENT_GET_INFO;
  
  /* Обработка ответа с информацией о контрагенте от тестового стенда */
  procedure AGENT_PROCESS_INFO
  (
    NIDENT                  in number,            -- Идентификатор процесса
    NEXSQUEUE               in number             -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    CMSG                    clob;                 -- Буфер для запроса
    CRESP                   clob;                 -- Буфер для ответа
    RCTMP                   sys_refcursor;        -- Буфер для измененной позиции очереди
    NCOMPANY                PKG_STD.TREF;         -- Рег. номер организации
    NCRN                    PKG_STD.TREF;         -- Рег. номер каталога
    SAGNABBR                AGNLIST.AGNABBR%type; -- Мнемокод контрагента
    SAGNNAME                AGNLIST.AGNNAME%type; -- Наименование контрагента
    NAGENT                  AGNLIST.RN%type;      -- Рег. номер добавленного контрагента
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Считаем запрос серверу */
    CMSG := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* Считаем ответ сервера и конвертируем в кодировку БД */
    CRESP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    /* Кладём конвертированное обратно (просто для удобства мониторинга) */
    PKG_EXS.QUEUE_RESP_SET(NEXSQUEUE    => REXSQUEUE.RN,
                           BRESP        => CLOB2BLOB(LCDATA => CRESP),
                           NIS_ORIGINAL => PKG_EXS.NIS_ORIGINAL_NO,
                           RCQUEUE      => RCTMP);
    /* Заберем организацию из исходящего сообщения */
    begin
      select EXTRACTVALUE(XMLTYPE(CMSG), '/MSG/NCOMPANY') NCOMPANY into NCOMPANY from DUAL;
    exception
      when others then
        P_EXCEPTION(0, 'Не удалось определить организацию');
    end;
    if (NCOMPANY is null) then
      P_EXCEPTION(0, 'В исходящем сообщении не указана организация');
    end if;
    /* Разбираем ответ сервера */
    if (CRESP is not null) then
      begin
        select EXTRACTVALUE(XMLTYPE(CRESP), '/AGENT/SAGNABBR') SAGNABBR,
               EXTRACTVALUE(XMLTYPE(CRESP), '/AGENT/SAGNNAME') SAGNNAME
          into SAGNABBR,
               SAGNNAME
          from DUAL;
      exception
        when others then
          P_EXCEPTION(0, 'Неожиданный ответ сервера.');
      end;
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
    /* Фиксируем испех исполнения */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK);
  exception
    when others then
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end AGENT_PROCESS_INFO;

end;
/
