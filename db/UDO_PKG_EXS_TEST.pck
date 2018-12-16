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
  
  /* ����������� �������������� - �������������� */
  procedure INV_CHECKAUTH_XML
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  );
  
  /* ����������� �������������� - ���������� ������������� */
  procedure INV_GETUSERS_XML
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  );
  
end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* ��� ������ ��� ��������� �������� ��������������� ���� ������ */
  type THELPER_PATTERNS is table of varchar2(4000);

  /* �������� �� ����������� ����� � ������ ��������������� */
  function UTL_HELPER_CHECK
  (
    SWORD                   in varchar2,        -- ����������� �����
    HELPER_PATTERNS         in THELPER_PATTERNS -- ��������� �������� ��������������� ����
  ) 
  return                    boolean             -- ��������� ��������
  is
    BRES                    boolean;            -- ����� ��� ����������
  begin
    /* �������������� ����� */
    BRES := false;
    /* ���� ��������� �� ����� */
    if ((HELPER_PATTERNS is not null) and (HELPER_PATTERNS.COUNT > 0)) then
      /* ������� � */
      for I in HELPER_PATTERNS.FIRST .. HELPER_PATTERNS.LAST
      loop
        /* ���� ����� ���� � ��������� */
        if (LOWER(SWORD) like LOWER(HELPER_PATTERNS(I))) then
          /* �������� ���� ����������� � �������� ����� */
          BRES := true;
          exit;
        end if;
      end loop;
    end if;
    /* ���������� ����� */
    return BRES;
  end UTL_HELPER_CHECK;
  
  /* ������������� ����� ��������������� ��������� ���� */
  procedure UTL_HELPER_INIT_COMMON
  (
    HELPER_PATTERNS         in out THELPER_PATTERNS -- ��������� �������� ��������������� ����
  )
  is
  begin
    /* �������� ������ ��������� ���� ���� */
    if (HELPER_PATTERNS is null) then
      HELPER_PATTERNS := THELPER_PATTERNS();
    end if;
    /* �������� � ������ ���������� ���������������� ������� */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '��������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '���';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '��';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '��';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '��������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '����������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '����������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '����������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '����';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '����';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '���';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�����';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�����';
  end UTL_HELPER_INIT_COMMON;
  
  /* ���������� ��������� ����� � ������� � ������� */
  function UTL_SEARCH_STR_PREPARE
  (
    SSEARCH_STR             in varchar2,        -- ��������� �����
    SDELIM                  in varchar2,        -- ����������� ���� � ��������� �����
    HELPER_PATTERNS         in THELPER_PATTERNS -- ��������� �������� ��������������� ����
  ) 
  return                    varchar2            -- �������������� ��������� �����
  is
    SRES                    varchar2(32000);    -- ��������� ������
  begin
    /* ������� ����� ��������� ����� */
    for W in (select REGEXP_SUBSTR(T.STR, '[^' || SDELIM || ']+', 1, level) SWRD
                from (select replace(replace(SSEARCH_STR, ',', ''), '.', '') STR from DUAL) T
              connect by INSTR(T.STR, SDELIM, 1, level - 1) > 0)
    loop
      /* ���� ����� �� � ������ ��������������� */
      if (not UTL_HELPER_CHECK(SWORD => W.SWRD, HELPER_PATTERNS => HELPER_PATTERNS)) then
        /* ��������� ��� � �������� ������� */
        SRES := SRES || '%' || W.SWRD;
      end if;
    end loop;
    /* ������ ������ ������� � ������� ��� ������ */
    SRES := '%' || trim(SRES) || '%';
    /* ������ ����� */
    return SRES;
  end UTL_SEARCH_STR_PREPARE;
  
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
    HELPER_PATTERNS         THELPER_PATTERNS; -- ��������� �������� ��������������� ���� ������
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    CTMP                    clob;             -- ����� ��� �����������
    CRESP                   clob;             -- ������ ��� ������
    RCTMP                   sys_refcursor;    -- ����� ��� ���������� ������� �������
 begin
   /* ������� ������ ������� */
   REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
   /* �������������� ��������� ����-���������� */
   UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
   /* ��������� � ���������� ��������������� ��� ������� ������� */
   HELPER_PATTERNS.EXTEND();
   HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '����������%';
   /* �������� ������ ��������� � ������������ � ��������� �� */
   CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
   /* ����� ���������������� ������� (������ ��� �������� �����������) */
   PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
   /* ���� ���� ��� ������ */
   if (CTMP is not null) then
     /* ���������� ��������� ����� */
     CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
     /* �������������� ����� */
     CRESP := '���������� �� ������';
     /* ���� ������������ ����������� */
     for C in (select T.AGNNAME ||
                      DECODE(T.AGNTYPE, 1, ', ���������� ����', ', ����������� ����') SAGENT,
                      (select count(CN.RN) from CONTRACTS CN where CN.AGENT = T.RN) NCNT_CONTRACTS,
                      (select sum(CN.DOC_SUM) from CONTRACTS CN where CN.AGENT = T.RN) NSUM_CONTRACTS
                 from AGNLIST T
                where ((LOWER(T.AGNABBR) like LOWER(CTMP)) or (LOWER(T.AGNNAME) like LOWER(CTMP)))
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
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- ��������� �������� ��������������� ���� ������
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    CTMP                    clob;             -- ����� ��� �����������
    CRESP                   clob;             -- ������ ��� ������
    RCTMP                   sys_refcursor;    -- ����� ��� ���������� ������� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������������� ��������� ����-���������� */
    UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
    /* ��������� � ���������� ��������������� ��� ������� ������� */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�������%';
    /* �������� ������ ��������� � ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ���� ���� ��� ������ */
    if (CTMP is not null) then
      /* ���������� ��������� ����� */
      CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
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
         where ((LOWER(T.EXT_NUMBER) like LOWER(CTMP)) or
               (LOWER(trim(T.DOC_PREF) || trim(T.DOC_NUMB)) like LOWER(CTMP)))
           and T.AGENT = AG.RN
           and T.CURRENCY = CN.RN
           and ROWNUM <= 1;
      exception
        when NO_DATA_FOUND then
          CRESP := '������� �� ������';
      end;
    else
      CRESP := '�� ������ ��������� ������';
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end RESP_FIND_CONTRACT;
  
  /* ����������� �������������� - �������������� */
  procedure INV_CHECKAUTH_XML
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    /**/
    SREQDEVICEID       varchar2(30);
    XCHECKAUTHRESPONSE DBMS_XMLDOM.DOMNODE;
    XRESULT            DBMS_XMLDOM.DOMNODE;
    XNODE              DBMS_XMLDOM.DOMNODE;
    CRESPONSE          clob;
    XDOC DBMS_XMLDOM.DOMDOCUMENT;
    /**/
    XMLPARCER DBMS_XMLPARSER.PARSER;
    XENVELOPE DBMS_XMLDOM.DOMNODE;
    XBODY     DBMS_XMLDOM.DOMNODE;
    XNODELIST DBMS_XMLDOM.DOMNODELIST;
    XNODE_ROOT     DBMS_XMLDOM.DOMNODE;
    SNODE     varchar2(100);   
    CREQ      clob; 
    /**/
    STSD constant varchar2(20) := 'tsd';
    SCHECKAUTHRESPONSE constant varchar2(20) := 'CheckAuthResponse';
    SDEVICEID constant varchar2(20) := 'DeviceID';
    SRESULT constant varchar2(20) := 'Result';
    SSOAPENV constant varchar2(20) := 'soapenv';
    SENVELOPE constant varchar2(20) := 'Envelope';
    SHEADER constant varchar2(20) := 'Header';
    SBODY constant varchar2(20) := 'Body';
    /* �������� ����� XML */    
    function CREATENODE
    (
      STAG in varchar2,
      SNS  in varchar2 default null,
      SVAL in varchar2 default null
    ) return DBMS_XMLDOM.DOMNODE is
      XEL   DBMS_XMLDOM.DOMELEMENT;
      XNODE DBMS_XMLDOM.DOMNODE;
      XTEXT DBMS_XMLDOM.DOMNODE;
    begin
      if SNS is not null then
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG, NS => SNS);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
        DBMS_XMLDOM.SETPREFIX(N => XNODE, PREFIX => SNS);
      else
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
      end if;
      if SVAL is not null then
        XTEXT := DBMS_XMLDOM.APPENDCHILD(XNODE, DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(XDOC, SVAL)));
      end if;
      return XNODE;
    end;
    /* ���������� �������� ����� XML */
    function GETNODEVAL
    (
      XROOTNODE in DBMS_XMLDOM.DOMNODE,
      SPATTERN  in varchar2
    ) return varchar2 is
      XNODE DBMS_XMLDOM.DOMNODE;
      SVAL  varchar2(100);
    begin
      XNODE := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XROOTNODE, PATTERN => SPATTERN);
      if DBMS_XMLDOM.ISNULL(XNODE) then
        return null;
      end if;
      SVAL := DBMS_XMLDOM.GETNODEVALUE(DBMS_XMLDOM.GETFIRSTCHILD(N => XNODE));
      return SVAL;
    end GETNODEVAL;
    /* �������� ��������� ��� ������ */
    procedure CREATERESPONSEDOC is
    begin
      XDOC := DBMS_XMLDOM.NEWDOMDOCUMENT;
      DBMS_XMLDOM.SETVERSION(XDOC
                            ,'1.0" encoding="UTF-8');
      DBMS_XMLDOM.SETCHARSET(XDOC
                            ,'UTF-8');
    end;
    /* �������� ������ */
    function CREATERESPONSE(XCONTENT in DBMS_XMLDOM.DOMNODE) return clob is
      XMAIN_NODE   DBMS_XMLDOM.DOMNODE;
      XENVELOPE_EL DBMS_XMLDOM.DOMELEMENT;
      XENVELOPE    DBMS_XMLDOM.DOMNODE;
      XHEADER      DBMS_XMLDOM.DOMNODE;
      XBODY        DBMS_XMLDOM.DOMNODE;
      XNODE        DBMS_XMLDOM.DOMNODE;
      CDATA        clob;
    begin
      -- Document
      XMAIN_NODE := DBMS_XMLDOM.MAKENODE(XDOC);
      -- Envelope
      XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => SENVELOPE, NS => SSOAPENV);
      DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                               name     => 'xmlns:soapenv',
                               NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
      DBMS_XMLDOM.SETATTRIBUTE(ELEM => XENVELOPE_EL, name => 'xmlns:tsd', NEWVALUE => 'http://www.example.org/TSDService/');
      XENVELOPE := DBMS_XMLDOM.MAKENODE(XENVELOPE_EL);
      DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SSOAPENV);
      XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
      -- Header
      XHEADER := CREATENODE(SHEADER, SSOAPENV);
      XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
      -- Body
      XBODY := CREATENODE(SBODY, SSOAPENV);
      XBODY := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XBODY);
      XNODE := DBMS_XMLDOM.APPENDCHILD(N => XBODY, NEWCHILD => XCONTENT);
      -- ������� CLOB
      DBMS_LOB.CREATETEMPORARY(LOB_LOC => CDATA, CACHE => true, DUR => DBMS_LOB.SESSION);
      DBMS_XMLDOM.WRITETOCLOB(XDOC, CDATA, 'UTF-8');
      DBMS_XMLDOM.FREEDOCUMENT(DOC => XDOC);
      return CDATA;
    end;
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������������ � ��������� �� */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
      -- ������� ������� XML �������
      XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
      -- ��������� XML �� �������
      DBMS_XMLPARSER.PARSECLOB(XMLPARCER
                              ,CREQ);
      -- ����� XML ��������
      XDOC := DBMS_XMLPARSER.GETDOCUMENT(XMLPARCER);
      -- ��������� �������� �������
      XENVELOPE := DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.GETDOCUMENTELEMENT(XDOC));
      -- ��������� ������� Body
      XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(XENVELOPE
                                                 ,SBODY);
      -- ��������� �������� �������� � Body
      XNODELIST := DBMS_XMLDOM.GETCHILDNODES(XBODY);
      -- ����� ������ �������� �������
      XNODE_ROOT := DBMS_XMLDOM.ITEM(XNODELIST
                               ,0);
      -- ������� ��� ��������
      DBMS_XMLDOM.GETLOCALNAME(XNODE_ROOT
                              ,SNODE);
    -- ��������� DeviceID
    SREQDEVICEID := GETNODEVAL(XNODE_ROOT
                              ,SDEVICEID);
    --CHECK_ID(SREQDEVICEID);
    CREATERESPONSEDOC();
    if SREQDEVICEID is not null
    then
      XCHECKAUTHRESPONSE := CREATENODE(SCHECKAUTHRESPONSE
                                      ,STSD);
      XRESULT            := CREATENODE(SRESULT
                                      ,STSD
                                      ,'true');
      XNODE              := DBMS_XMLDOM.APPENDCHILD(N        => XCHECKAUTHRESPONSE
                                                   ,NEWCHILD => XRESULT);
      CRESPONSE          := CREATERESPONSE(XCHECKAUTHRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE));
  end;

  /* ����������� �������������� - ���������� ������������� */
  procedure INV_GETUSERS_XML
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    /**/
    SREQDEVICEID       varchar2(30);
    XGETUSERSRESPONSE  DBMS_XMLDOM.DOMNODE;
    XITEM             DBMS_XMLDOM.DOMNODE;
    XCODE             DBMS_XMLDOM.DOMNODE;
    XNAME             DBMS_XMLDOM.DOMNODE;
    XNODE              DBMS_XMLDOM.DOMNODE;
    CRESPONSE          clob;
    XDOC DBMS_XMLDOM.DOMDOCUMENT;
    /**/
    XMLPARCER DBMS_XMLPARSER.PARSER;
    XENVELOPE DBMS_XMLDOM.DOMNODE;
    XBODY     DBMS_XMLDOM.DOMNODE;
    XNODELIST DBMS_XMLDOM.DOMNODELIST;
    XNODE_ROOT     DBMS_XMLDOM.DOMNODE;
    SNODE     varchar2(100);   
    CREQ      clob; 
    /**/
    STSD constant varchar2(20) := 'tsd';
    SGETUSERSRESPONSE constant varchar2(20) := 'GetUsersResponse';
    SDEVICEID constant varchar2(20) := 'DeviceID';
    SRESULT constant varchar2(20) := 'Result';
    SSOAPENV constant varchar2(20) := 'soapenv';
    SENVELOPE constant varchar2(20) := 'Envelope';
    SHEADER constant varchar2(20) := 'Header';
    SBODY constant varchar2(20) := 'Body';
    SITEM constant varchar2(20) := 'Item';
    SCODE constant varchar2(20) := 'Code'; 
    SNAME constant varchar2(20) := 'Name';   
    /* �������� ����� XML */    
    function CREATENODE
    (
      STAG in varchar2,
      SNS  in varchar2 default null,
      SVAL in varchar2 default null
    ) return DBMS_XMLDOM.DOMNODE is
      XEL   DBMS_XMLDOM.DOMELEMENT;
      XNODE DBMS_XMLDOM.DOMNODE;
      XTEXT DBMS_XMLDOM.DOMNODE;
    begin
      if SNS is not null then
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG, NS => SNS);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
        DBMS_XMLDOM.SETPREFIX(N => XNODE, PREFIX => SNS);
      else
        XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG);
        XNODE := DBMS_XMLDOM.MAKENODE(XEL);
      end if;
      if SVAL is not null then
        XTEXT := DBMS_XMLDOM.APPENDCHILD(XNODE, DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(XDOC, SVAL)));
      end if;
      return XNODE;
    end;
    /* ���������� �������� ����� XML */
    function GETNODEVAL
    (
      XROOTNODE in DBMS_XMLDOM.DOMNODE,
      SPATTERN  in varchar2
    ) return varchar2 is
      XNODE DBMS_XMLDOM.DOMNODE;
      SVAL  varchar2(100);
    begin
      XNODE := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XROOTNODE, PATTERN => SPATTERN);
      if DBMS_XMLDOM.ISNULL(XNODE) then
        return null;
      end if;
      SVAL := DBMS_XMLDOM.GETNODEVALUE(DBMS_XMLDOM.GETFIRSTCHILD(N => XNODE));
      return SVAL;
    end GETNODEVAL;
    /* �������� ��������� ��� ������ */
    procedure CREATERESPONSEDOC is
    begin
      XDOC := DBMS_XMLDOM.NEWDOMDOCUMENT;
      DBMS_XMLDOM.SETVERSION(XDOC
                            ,'1.0" encoding="UTF-8');
      DBMS_XMLDOM.SETCHARSET(XDOC
                            ,'UTF-8');
    end;
    /* �������� ������ */
    function CREATERESPONSE(XCONTENT in DBMS_XMLDOM.DOMNODE) return clob is
      XMAIN_NODE   DBMS_XMLDOM.DOMNODE;
      XENVELOPE_EL DBMS_XMLDOM.DOMELEMENT;
      XENVELOPE    DBMS_XMLDOM.DOMNODE;
      XHEADER      DBMS_XMLDOM.DOMNODE;
      XBODY        DBMS_XMLDOM.DOMNODE;
      XNODE        DBMS_XMLDOM.DOMNODE;
      CDATA        clob;
    begin
      -- Document
      XMAIN_NODE := DBMS_XMLDOM.MAKENODE(XDOC);
      -- Envelope
      XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => SENVELOPE, NS => SSOAPENV);
      DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                               name     => 'xmlns:soapenv',
                               NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
      DBMS_XMLDOM.SETATTRIBUTE(ELEM => XENVELOPE_EL, name => 'xmlns:tsd', NEWVALUE => 'http://www.example.org/TSDService/');
      XENVELOPE := DBMS_XMLDOM.MAKENODE(XENVELOPE_EL);
      DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SSOAPENV);
      XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
      -- Header
      XHEADER := CREATENODE(SHEADER, SSOAPENV);
      XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
      -- Body
      XBODY := CREATENODE(SBODY, SSOAPENV);
      XBODY := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XBODY);
      XNODE := DBMS_XMLDOM.APPENDCHILD(N => XBODY, NEWCHILD => XCONTENT);
      -- ������� CLOB
      DBMS_LOB.CREATETEMPORARY(LOB_LOC => CDATA, CACHE => true, DUR => DBMS_LOB.SESSION);
      DBMS_XMLDOM.WRITETOCLOB(XDOC, CDATA, 'UTF-8');
      DBMS_XMLDOM.FREEDOCUMENT(DOC => XDOC);
      return CDATA;
    end;
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������������ � ��������� �� */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
      -- ������� ������� XML �������
      XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
      -- ��������� XML �� �������
      DBMS_XMLPARSER.PARSECLOB(XMLPARCER
                              ,CREQ);
      -- ����� XML ��������
      XDOC := DBMS_XMLPARSER.GETDOCUMENT(XMLPARCER);
      -- ��������� �������� �������
      XENVELOPE := DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.GETDOCUMENTELEMENT(XDOC));
      -- ��������� ������� Body
      XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(XENVELOPE
                                                 ,SBODY);
      -- ��������� �������� �������� � Body
      XNODELIST := DBMS_XMLDOM.GETCHILDNODES(XBODY);
      -- ����� ������ �������� �������
      XNODE_ROOT := DBMS_XMLDOM.ITEM(XNODELIST
                               ,0);
      -- ������� ��� ��������
      DBMS_XMLDOM.GETLOCALNAME(XNODE_ROOT
                              ,SNODE);
    -- ��������� DeviceID
    SREQDEVICEID := GETNODEVAL(XNODE_ROOT
                              ,SDEVICEID);
    --CHECK_ID(SREQDEVICEID);
    CREATERESPONSEDOC();
    if SREQDEVICEID is not null
    then
      XGETUSERSRESPONSE := CREATENODE(SGETUSERSRESPONSE
                                     ,STSD);
      for REC in (select T.RN
                        ,A.AGNABBR
                    from INVPERSONS T
                        ,AGNLIST    A
                   where T.COMPANY = 136018
                     and T.AGNLIST = A.RN)
      loop
        XITEM := CREATENODE(SITEM
                           ,STSD);
        XCODE := CREATENODE(SCODE
                           ,STSD
                           ,REC.RN);
        XNAME := CREATENODE(SNAME
                           ,STSD
                           ,REC.AGNABBR);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N        => XITEM
                                        ,NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N        => XITEM
                                        ,NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N        => XGETUSERSRESPONSE
                                        ,NEWCHILD => XITEM);
      end loop;
      CRESPONSE := CREATERESPONSE(XGETUSERSRESPONSE);
    end if;         
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE, sCHARSET => 'UTF8'));
  end;

end;
/
