create or replace package UDO_PKG_EXS_TEST as

  /* Обработка ответа с информацией о контрагенте от тестового стенда */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* Обработка ответа с информацией о контрагенте от тестового стенда */
  procedure PROCESS_AGN_INFO_RESP
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
