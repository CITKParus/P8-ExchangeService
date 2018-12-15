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
    /* ������ ���. ����� ������� ������� */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICEFN, NRN => NEXSSERVICEFN);
    /* �������� ������� � ������� */
    PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => NEXSSERVICEFN,
                      BMSG          => CLOB2BLOB(LCDATA => 'CPRMS={SACTION:"GET_AGENT",NAGENT:' || TO_CHAR(NREMOTE_AGENT) || '}'),
                      RCQUEUE       => RCTMP);
  end RECIVE_AGENT;
  
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
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ��������� ����� ������� */
    if (CTMP is not null) then
      select EXTRACTVALUE(XMLTYPE(CTMP), '/AGENT/SAGNABBR') SAGNABBR,
             EXTRACTVALUE(XMLTYPE(CTMP), '/AGENT/SAGNNAME') SAGNNAME
        into SAGNABBR,
             SAGNNAME
        from DUAL;
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
  exception
    when others then
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT, SARG => PKG_EXS.SCONT_FLD_SERR, SVALUE => sqlerrm);
  end PROCESS_AGN_INFO_RESP;
  
  /* ��������� ������� �� �������� ������ */
  procedure RESP_LOGIN
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
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
      PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                    SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                    BVALUE => CLOB2BLOB(LCDATA => SCONNECT, SCHARSET => 'UTF8'));
    
    else
      P_EXCEPTION(0, '�� ������� ��� ������������, ������ ��� �����������.');
    end if;
  exception
    when others then
      PKG_EXS.PRC_RESP_ARG_STR_SET(NIDENT => NIDENT, SARG => PKG_EXS.SCONT_FLD_SERR, SVALUE => sqlerrm);
  end RESP_LOGIN;
  
  /* ��������� ������� �� ����� ����������� */
  procedure RESP_FIND_AGENT
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    CTMP                    clob;             -- ����� ��� �����������
    CRESP                   clob;             -- ������ ��� ������
    RCTMP                   sys_refcursor;    -- ����� ��� ���������� ������� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ������ ��������� � ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ���� ���� ��� ������ */
    if (CTMP is not null) then
      /* �������������� ����� */
      CRESP := '���������� "' || CTMP || '" �� ������';
      /* ���� ������������ ����������� */
      for C in (select T.AGNNAME ||
                       DECODE(T.AGNTYPE, 1, ', ���������� ����', ', ����������� ����') SAGENT,
                       (select count(CN.RN) from CONTRACTS CN where CN.AGENT = T.RN) NCNT_CONTRACTS,
                       (select sum(CN.DOC_SUM) from CONTRACTS CN where CN.AGENT = T.RN) NSUM_CONTRACTS
                  from AGNLIST T
                 where ((STRINLIKE(LOWER(T.AGNABBR), '%' || LOWER(replace(CTMP, ' ', '% %')) || '%', ' ') <> 0) or
                       (STRINLIKE(LOWER(T.AGNNAME), '%' || LOWER(replace(CTMP, ' ', '% %')) || '%', ' ') <> 0))
                   and ROWNUM <= 1)
      loop
        CRESP := C.SAGENT;
        if (C.NCNT_CONTRACTS = 0) then
          CRESP := CRESP || ', �� ����� ������������������ � ������� ���������';
        else
          CRESP := CRESP || ', ���������������� ���������: ' || TO_CHAR(C.NCNT_CONTRACTS);
          if (C.NSUM_CONTRACTS <> 0) then
            CRESP := CRESP || ', �� ����� �����: ' || TO_CHAR(C.NSUM_CONTRACTS) || ' ���.';
          end if;
        end if;
      end loop;
    else
      CRESP := '�� ������ ��������� ������';
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end RESP_FIND_AGENT;

  /* ��������� ������� �� ����� �������� */
  procedure RESP_FIND_CONTRACT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    CTMP                    clob;             -- ����� ��� �����������
    CRESP                   clob;             -- ������ ��� ������
    RCTMP                   sys_refcursor;    -- ����� ��� ���������� ������� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ������ ��������� � ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ���� ���� ��� ������ */
    if (CTMP is not null) then
      /* ���� ����������� ������� */
      begin
        select DECODE(T.INOUT_SIGN, 0, '��������', '���������') || ' ������� �' ||
               NVL(T.EXT_NUMBER, trim(T.DOC_PREF) || '-' || trim(T.DOC_NUMB)) || ' �� ' ||
               TO_CHAR(T.DOC_DATE, 'dd.mm.yyyy') || ' � ������������ ' || AG.AGNNAME || ' �� ����� ' ||
               TO_CHAR(T.DOC_SUM) || ' ' || CN.INTCODE || ', �������� ' || TO_CHAR(T.FACT_OUTPAY_SUM) || ' ' ||
               CN.INTCODE SDOC
          into CRESP
          from CONTRACTS T,
               AGNLIST   AG,
               CURNAMES  CN
         where ((STRINLIKE(LOWER(T.EXT_NUMBER), '%' || LOWER(replace(CTMP, ' ', '% %')) || '%', ' ') <> 0) or
               (STRINLIKE(LOWER(trim(T.DOC_PREF) || trim(T.DOC_NUMB)),
                           '%' || LOWER(replace(CTMP, ' ', '% %')) || '%',
                           ' ') <> 0))
           and T.AGENT = AG.RN
           and T.CURRENCY = CN.RN
           and ROWNUM <= 1;
      exception
        when NO_DATA_FOUND then
          CRESP := '������� "' || CTMP || '" �� ������';
      end;
    else
      CRESP := '�� ������ ��������� ������';
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end RESP_FIND_CONTRACT;

end;
/
