create or replace package UDO_PKG_EXS_TEST as

  /* ��������� ����������� */
  procedure RECIVE_AGENT
  (
    NREMOTE_AGENT           in number   -- ���. ����� ����������� � �������� ��
  );
  
  /* ��������� ������ � ����������� � ����������� �� ��������� ������ */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
  /* ��������� ������� �� �������� ������ */
  procedure RESP_LOGIN
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
  /* ��������� ������� �� ����� ����������� */
  procedure RESP_FIND_AGENT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ��������� ������� �� ����� �������� */
  procedure RESP_FIND_CONTRACT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );  

end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* ��������� ����������� */
  procedure RECIVE_AGENT
  (
    NREMOTE_AGENT           in number               -- ���. ����� ����������� � �������� ��
  )
  is
    SEXSSERVICEFN           EXSSERVICEFN.CODE%type; -- �������� ������� �������
    NEXSSERVICEFN           EXSSERVICEFN.RN%type;   -- ���. ����� ������� �������
    RCTMP                   sys_refcursor;          -- ����� ��� ���������� ������� �������
  begin
    /* �������������� �������� ������� ������� */
    SEXSSERVICEFN := '��������������������';
    /* ������ ���. ����� ������� �������� */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICEFN, NRN => NEXSSERVICEFN);
    /* �������� ������� � ������� */
    PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => NEXSSERVICEFN,
                      BMSG          => CLOB2BLOB(LCDATA => TO_CHAR(NREMOTE_AGENT)),
                      RCQUEUE       => RCTMP);
  end;
  
  /* ��������� ������ � ����������� � ����������� �� ��������� ������ */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,            -- ������������� ��������
    NSRV_TYPE               in number,            -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number             -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    CTMP                    clob;                 -- ����� ��� �����������
    RCTMP                   sys_refcursor;        -- ����� ��� ���������� ������� �������
    NCOMPANY                PKG_STD.TREF;         -- ���. ����� �����������
    NVERSION                PKG_STD.TREF;         -- ���. ����� ������
    NCRN                    PKG_STD.TREF;         -- ���. ����� ��������
    SAGNABBR                AGNLIST.AGNABBR%type; -- �������� �����������
    SAGNNAME                AGNLIST.AGNNAME%type; -- ������������ �����������
    NAGENT                  AGNLIST.RN%type;      -- ���. ����� ������������ �����������
  begin
    /* �������������� ����������� */
    NCOMPANY := 136018;
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_RESP_SET(NEXSQUEUE => REXSQUEUE.RN, BRESP => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ��������� ����� ������� */
    declare
      SSPR  varchar2(3) := '$#$';
      NSPRL number := LENGTH(SSPR);
    begin
      SAGNABBR := SUBSTR(CTMP, 1, INSTR(CTMP, SSPR) - 1);
      SAGNNAME := SUBSTR(CTMP, INSTR(CTMP, SSPR) + NSPRL);
    exception
      when others then
        P_EXCEPTION(0, '����������� ����� �������');
    end;
    if (SAGNABBR is null) then
      P_EXCEPTION(0, '� ������ ������� �� ������ �������� �����������');
    end if;
    if (SAGNNAME is null) then
      P_EXCEPTION(0,
                  '� ������ ������� �� ������� ������������ �����������');
    end if;
    /* ����� ������� */
    FIND_ACATALOG_NAME(NFLAG_SMART => 0,
                       NCOMPANY    => NCOMPANY,
                       NVERSION    => null,
                       SUNITCODE   => 'AGNLIST',
                       SNAME       => 'ExchangeService',
                       NRN         => NCRN);
    /* ������������ ����������� */
    P_AGNLIST_BASE_INSERT(NCOMPANY => NCOMPANY,
                          NCRN     => NCRN,
                          SAGNABBR => SUBSTR(NIDENT || SAGNABBR, 1, 20),                          
                          SAGNNAME => SAGNNAME || ' ' || NIDENT,
                          NRN      => NAGENT);
  exception
    when others then
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT, SARG => PKG_EXS.SCONT_FLD_SERR, SVALUE => sqlerrm);
  end;
  
  /* ��������� ������� �� �������� ������ */
  procedure RESP_LOGIN
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    CTMP                    clob;                 -- ����� ��� �����������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ���������� ��������� ��������� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CTMP || ' ��������� ����� 8', SCHARSET => 'UTF8'));
  end;
  
  /* ��������� ������� �� ����� ����������� */
  procedure RESP_FIND_AGENT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end;

  /* ��������� ������� �� ����� �������� */
  procedure RESP_FIND_CONTRACT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end;

end;
/
