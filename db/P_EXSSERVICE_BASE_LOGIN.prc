create or replace procedure P_EXSSERVICE_BASE_LOGIN
(
  NRN                       in number   -- Рег. номер записи сервиса обмена
)
as
begin
  /* Поставим в очередь задание на аутентификацию */
  PKG_EXS.SERVICE_AUTH_PUT_INQUEUE(NEXSSERVICE => NRN);
end;
/
