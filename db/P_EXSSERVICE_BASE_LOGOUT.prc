create or replace procedure P_EXSSERVICE_BASE_LOGOUT
(
  NRN                       in number   -- ���. ����� ������ ������� ������
)
as
begin
  /* �������� � ������� ������� �� ������ �������������� */
  PKG_EXS.SERVICE_UNAUTH_PUT_INQUEUE(NEXSSERVICE => NRN);
end;
/
