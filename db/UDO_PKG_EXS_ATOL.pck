create or replace package UDO_PKG_EXS_ATOL as

  /* Отработка ответов АТОЛ на отправку чека */
  procedure PROCESS_SEND_CHECK_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Отработка ответов ОФД на запрос печатной версии чека */
  procedure PROCESS_CHECK_PRINT_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* Отработка ответов АТОЛ на отправку чека */
  procedure PROCESS_SEND_CHECK_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end;

  /* Отработка ответов ОФД на запрос печатной версии чека */
  procedure PROCESS_CHECK_PRINT_RESP
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
