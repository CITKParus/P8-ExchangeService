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
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Эмулируем работу */
    /*if (REXSQUEUE.RN = 3) then
      --dbms_lock.sleep(15);
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT,
                                   SARG   => PKG_EXS.SCONT_FLD_SERR,
                                   SVALUE => 'Ошибка обработки позиции очереди ' || TO_CHAR(REXSQUEUE.RN));
    else*/
      dbms_lock.sleep(5);
      insert into UDO_T_EXS_ATOL (RN, DT, MSG) values (GEN_ID, sysdate, BLOB2CLOB(LBDATA => REXSQUEUE.RESP));
    --end if;
  end PROCESS_BILL_SEND_RESP;

  /* Отработка ответов ОФД на запрос печатной версии чека */
  procedure PROCESS_BILL_PRINT_RESP
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
  begin
    null;
  end PROCESS_BILL_PRINT_RESP;

end;
/
