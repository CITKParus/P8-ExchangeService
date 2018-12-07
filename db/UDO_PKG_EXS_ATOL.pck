create or replace package UDO_PKG_EXS_ATOL as

  /* ��������� ������� ���� �� �������� ���� */
  procedure PROCESS_BILL_SEND_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ��������� ������� ��� �� ������ �������� ������ ���� */
  procedure PROCESS_BILL_PRINT_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* ��������� ������� ���� �� �������� ���� */
  procedure PROCESS_BILL_SEND_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ��������� ������ */
    /*if (REXSQUEUE.RN = 3) then
      --dbms_lock.sleep(15);
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT,
                                   SARG   => PKG_EXS.SCONT_FLD_SERR,
                                   SVALUE => '������ ��������� ������� ������� ' || TO_CHAR(REXSQUEUE.RN));
    else*/
      dbms_lock.sleep(5);
      insert into UDO_T_EXS_ATOL (RN, DT, MSG) values (GEN_ID, sysdate, BLOB2CLOB(LBDATA => REXSQUEUE.RESP));
    --end if;
  end PROCESS_BILL_SEND_RESP;

  /* ��������� ������� ��� �� ������ �������� ������ ���� */
  procedure PROCESS_BILL_PRINT_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end PROCESS_BILL_PRINT_RESP;

end;
/
