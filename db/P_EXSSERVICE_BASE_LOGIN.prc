create or replace procedure P_EXSSERVICE_BASE_LOGIN
(
  NRN                       in number   -- ���. ����� ������ ������� ������
)
as
begin
  /* �������� � ������� ������� �� �������������� */
  PKG_EXS.SERVICE_AUTH_PUT_INQUEUE(NEXSSERVICE => NRN);
end;
/
