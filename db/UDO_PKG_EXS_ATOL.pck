create or replace package UDO_PKG_EXS_ATOL as

  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,        -- ������������� ��������
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    CTMP                    clob;             -- ����� ��� �������� ������ ������ �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ��� ������� ������� ��������� */
    if (REXSQUEUE.LNK_DOCUMENT is null) then
      P_EXCEPTION(0, '��� ������� ������� �� ������ ��������� ��������.');
    end if;
    if (REXSQUEUE.LNK_UNITCODE is null) then
      P_EXCEPTION(0, '��� ������� ������� �� ������ ��������� ������.');
    end if;
    if (REXSQUEUE.LNK_UNITCODE <> 'UDO_FiscalDocuments') then
      P_EXCEPTION(0,
                  '��������� ������ "%s", ��������� � ������� �������, �� ��������������.',
                  REXSQUEUE.LNK_UNITCODE);
    end if;
    /* ��������� ����� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    if (CTMP is null) then
      P_EXCEPTION(0, '��� ������ �� �������.');
    end if;
    /* ���������� ������������� ���� � �� */
    update UDO_FISCDOCS T set T.NUMB_FD = CTMP where T.RN = REXSQUEUE.LNK_DOCUMENT;
    /* �� ������ ������� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end V4_FFD105_PROCESS_REG_BILL_SIR;

end;
/
