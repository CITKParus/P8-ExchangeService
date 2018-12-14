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
    /* инициализируем мнемокод функции сервиса */
    SEXSSERVICEFN := 'ПолучениеКонтрагента';
    /* Найдем рег. номер функции сервсива */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICEFN, NRN => NEXSSERVICEFN);
    /* Поместим задание в очередь */
    PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => NEXSSERVICEFN,
                      BMSG          => CLOB2BLOB(LCDATA => TO_CHAR(NREMOTE_AGENT)),
                      RCQUEUE       => RCTMP);
  end;
  
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
    NVERSION                PKG_STD.TREF;         -- Рег. номер версии
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
    PKG_EXS.QUEUE_RESP_SET(NEXSQUEUE => REXSQUEUE.RN, BRESP => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* Разбираем ответ сервера */
    declare
      SSPR  varchar2(3) := '$#$';
      NSPRL number := LENGTH(SSPR);
    begin
      SAGNABBR := SUBSTR(CTMP, 1, INSTR(CTMP, SSPR) - 1);
      SAGNNAME := SUBSTR(CTMP, INSTR(CTMP, SSPR) + NSPRL);
    exception
      when others then
        P_EXCEPTION(0, 'Неожиданный ответ сервера');
    end;
    if (SAGNABBR is null) then
      P_EXCEPTION(0, 'В ответе сервера не указан мнемокод контрагента');
    end if;
    if (SAGNNAME is null) then
      P_EXCEPTION(0,
                  'В ответе сервера не указано наименование контрагента');
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
  end;
  
  /* Обработка запроса на создание сессии */
  procedure RESP_LOGIN
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    CTMP                    clob;                 -- Буфер для конвертации
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Выставляем результат обработки */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CTMP || ' ОБРАБОТКА ПАРУС 8', SCHARSET => 'UTF8'));
  end;
  
  /* Обработка запроса на поиск контрагента */
  procedure RESP_FIND_AGENT
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end;

  /* Обработка запроса на поиск договора */
  procedure RESP_FIND_CONTRACT
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end;

end;
/
