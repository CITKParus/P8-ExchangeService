create or replace procedure P_EXSSERVICE_BASE_LOGOUT
(
  NRN                       in number   -- Рег. номер записи сервиса обмена
)
as
begin
  /* Поставим в очередь задание на отмену аутентификации */
  PKG_EXS.SERVICE_UNAUTH_PUT_INQUEUE(NEXSSERVICE => NRN);
end;
/
