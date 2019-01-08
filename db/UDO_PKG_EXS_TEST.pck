create or replace package UDO_PKG_EXS_TEST as

  /* ��������� ������� �� �������� ������ */
  procedure UTL_LOGIN
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ��������� ����������� */
  procedure AGENT_GET_INFO
  (
    NCOMPANY                in number,  -- ���. ����� �����������    
    NREMOTE_AGENT           in number   -- ���. ����� ����������� � �������� ��
  );
  
  /* ��������� ������ � ����������� � ����������� �� ��������� ������ */
  procedure AGENT_PROCESS_INFO
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* ��������� ������� �� �������� ������ */
  procedure UTL_LOGIN
  (
    NIDENT                  in number,        -- ������������� ��������    
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    CTMP                    clob;             -- ����� ��� �����������
    RCTMP                   sys_refcursor;    -- ����� ��� ���������� ������� �������
    SUSER                   PKG_STD.TSTRING;  -- ��� ������������
    SPASS                   PKG_STD.TSTRING;  -- ������ ������������
    SCOMPANY                PKG_STD.TSTRING;  -- ������������ �����������
    SCONNECT                PKG_STD.TSTRING;  -- ������������� �����
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ������ ��������� � ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ��������� ����� � ������ */
    if (CTMP is not null) then
      select EXTRACTVALUE(XMLTYPE(CTMP), '/auth/user') SUSER,
             EXTRACTVALUE(XMLTYPE(CTMP), '/auth/pass') SPASS,
             EXTRACTVALUE(XMLTYPE(CTMP), '/auth/company') SCOMP
        into SUSER,
             SPASS,
             SCOMPANY
        from DUAL;
    else
      P_EXCEPTION(0, '�� ������� ������ ��� ��������������.');
    end if;
    /* ���� � ����� � ������ � ����������� ���� */
    if ((SUSER is not null) and (SPASS is not null) and (SCOMPANY is not null)) then
      /* ��������� ������������� ����� */
      SCONNECT := SYS_GUID();
      /* ������ ������ */
      PKG_SESSION.LOGON_WEB(SCONNECT        => SCONNECT,
                            SUTILIZER       => SUSER,
                            SPASSWORD       => SPASS,
                            SIMPLEMENTATION => 'Other',
                            SAPPLICATION    => 'Other',
                            SCOMPANY        => SCOMPANY);
      /* ���������� ��������� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                  SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                  BRESP   => CLOB2BLOB(LCDATA => SCONNECT, SCHARSET => 'UTF8'));
    else
      P_EXCEPTION(0,
                  '�� ������� ��� ������������, ������ ��� �����������.');
    end if;
  exception
    when others then
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end UTL_LOGIN;
  
  /* ��������� ����������� �� �������� ������� */
  procedure AGENT_GET_INFO
  (
    NCOMPANY                in number,              -- ���. ����� �����������
    NREMOTE_AGENT           in number               -- ���. ����� ����������� � �������� ��
  )
  is
    RCTMP                   sys_refcursor;          -- ����� ��� ���������� ������� �������
  begin
    /* �������� ������� � ������� */
    PKG_EXS.QUEUE_PUT(SEXSSERVICE   => '�������������',
                      SEXSSERVICEFN => '��������������������',
                      BMSG          => CLOB2BLOB(LCDATA => '{"SACTION":"GET_AGENT","NAGENT":' || TO_CHAR(NREMOTE_AGENT) ||
                                                           ',"NCOMPANY":' || TO_CHAR(NCOMPANY) || '}'),
                      RCQUEUE       => RCTMP);
  end AGENT_GET_INFO;
  
  /* ��������� ������ � ����������� � ����������� �� ��������� ������ */
  procedure AGENT_PROCESS_INFO
  (
    NIDENT                  in number,            -- ������������� ��������
    NEXSQUEUE               in number             -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    CMSG                    clob;                 -- ����� ��� �������
    CRESP                   clob;                 -- ����� ��� ������
    RCTMP                   sys_refcursor;        -- ����� ��� ���������� ������� �������
    NCOMPANY                PKG_STD.TREF;         -- ���. ����� �����������
    NCRN                    PKG_STD.TREF;         -- ���. ����� ��������
    SAGNABBR                AGNLIST.AGNABBR%type; -- �������� �����������
    SAGNNAME                AGNLIST.AGNNAME%type; -- ������������ �����������
    NAGENT                  AGNLIST.RN%type;      -- ���. ����� ������������ �����������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������� ������ ������� */
    CMSG := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* ������� ����� ������� � ������������ � ��������� �� */
    CRESP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_RESP_SET(NEXSQUEUE    => REXSQUEUE.RN,
                           BRESP        => CLOB2BLOB(LCDATA => CRESP),
                           NIS_ORIGINAL => PKG_EXS.NIS_ORIGINAL_NO,
                           RCQUEUE      => RCTMP);
    /* ������� ����������� �� ���������� ��������� */
    begin
      select EXTRACTVALUE(XMLTYPE(CMSG), '/MSG/NCOMPANY') NCOMPANY into NCOMPANY from DUAL;
    exception
      when others then
        P_EXCEPTION(0, '�� ������� ���������� �����������');
    end;
    if (NCOMPANY is null) then
      P_EXCEPTION(0, '� ��������� ��������� �� ������� �����������');
    end if;
    /* ��������� ����� ������� */
    if (CRESP is not null) then
      begin
        select EXTRACTVALUE(XMLTYPE(CRESP), '/AGENT/SAGNABBR') SAGNABBR,
               EXTRACTVALUE(XMLTYPE(CRESP), '/AGENT/SAGNNAME') SAGNNAME
          into SAGNABBR,
               SAGNNAME
          from DUAL;
      exception
        when others then
          P_EXCEPTION(0, '����������� ����� �������.');
      end;
    else
      P_EXCEPTION(0, '�� ������� ������ ��� ���������� �����������.');
    end if;
    if (SAGNABBR is null) then
      P_EXCEPTION(0, '� ������ ������� �� ������ �������� �����������.');
    end if;
    if (SAGNNAME is null) then
      P_EXCEPTION(0,
                  '� ������ ������� �� ������� ������������ �����������.');
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
    /* ��������� ����� ���������� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK);
  exception
    when others then
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end AGENT_PROCESS_INFO;

end;
/
