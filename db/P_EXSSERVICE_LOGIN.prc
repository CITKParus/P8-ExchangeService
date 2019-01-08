create or replace procedure P_EXSSERVICE_LOGIN
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
                   SACTION   => 'EXSSERVICE_LOGIN',
                   STABLE    => 'EXSSERVICE',
                   NDOCUMENT => REXSSERVICE.RN);

  /* Базовое начало сеанса */
  P_EXSSERVICE_BASE_LOGIN(NRN => REXSSERVICE.RN);

  /* Фиксация окончания выполнения действия */
  PKG_ENV.EPILOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => REXSSERVICE.CRN,
                   SUNIT     => 'EXSService',
                   SACTION   => 'EXSSERVICE_LOGIN',
                   STABLE    => 'EXSSERVICE',
                   NDOCUMENT => REXSSERVICE.RN);
end;
/
