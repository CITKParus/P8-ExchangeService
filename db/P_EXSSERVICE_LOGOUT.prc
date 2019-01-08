create or replace procedure P_EXSSERVICE_LOGOUT
(
  NRN                       in number           -- Рег. номер записи сервиса обмена
)
as
  REXSSERVICE               EXSSERVICE%rowtype; -- Запись сервиса обмена
begin
  /* Считывание записи */
  REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => NRN);

  /* Фиксация начала выполнения действия */
  PKG_ENV.PROLOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => REXSSERVICE.CRN,
                   SUNIT     => 'EXSService',
                   SACTION   => 'EXSSERVICE_LOGOUT',
                   STABLE    => 'EXSSERVICE',
                   NDOCUMENT => REXSSERVICE.RN);

  /* Базовое завершение сеанса */
  P_EXSSERVICE_BASE_LOGOUT(NRN => REXSSERVICE.RN);

  /* Фиксация окончания выполнения действия */
  PKG_ENV.EPILOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => REXSSERVICE.CRN,
                   SUNIT     => 'EXSService',
                   SACTION   => 'EXSSERVICE_LOGOUT',
                   STABLE    => 'EXSSERVICE',
                   NDOCUMENT => REXSSERVICE.RN);
end;
/
