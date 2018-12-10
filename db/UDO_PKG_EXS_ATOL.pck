create or replace package UDO_PKG_EXS_ATOL as

  /* Отработка ответов АТОЛ на отправку чека */
  procedure PROCESS_BILL_SEND_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Отработка ответов ОФД на запрос печатной версии чека */
  procedure PROCESS_BILL_PRINT_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* Отработка ответов АТОЛ на отправку чека */
  procedure PROCESS_BILL_SEND_RESP
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Разбираем ответ */
    null;
  end PROCESS_BILL_SEND_RESP;

  /* Отработка ответов ОФД на запрос печатной версии чека */
  procedure PROCESS_BILL_PRINT_RESP
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Разбираем ответ */
    null;
  end PROCESS_BILL_PRINT_RESP;

end;
/
