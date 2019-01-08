create or replace procedure P_EXSSERVICE_LOGOUT
(
  NRN                       in number           -- ���. ����� ������ ������� ������
)
as
  REXSSERVICE               EXSSERVICE%rowtype; -- ������ ������� ������
begin
  /* ���������� ������ */
  REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => NRN);

  /* �������� ������ ���������� �������� */
  PKG_ENV.PROLOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => REXSSERVICE.CRN,
                   SUNIT     => 'EXSService',
                   SACTION   => 'EXSSERVICE_LOGOUT',
                   STABLE    => 'EXSSERVICE',
                   NDOCUMENT => REXSSERVICE.RN);

  /* ������� ���������� ������ */
  P_EXSSERVICE_BASE_LOGOUT(NRN => REXSSERVICE.RN);

  /* �������� ��������� ���������� �������� */
  PKG_ENV.EPILOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => REXSSERVICE.CRN,
                   SUNIT     => 'EXSService',
                   SACTION   => 'EXSSERVICE_LOGOUT',
                   STABLE    => 'EXSSERVICE',
                   NDOCUMENT => REXSSERVICE.RN);
end;
/