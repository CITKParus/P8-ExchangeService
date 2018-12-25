create or replace package UDO_PKG_EXS_ATOL as

  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ��������� ����� */
    null;
  end V4_FFD105_PROCESS_REG_BILL_SIR;

end;
/
