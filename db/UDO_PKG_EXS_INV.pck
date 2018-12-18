create or replace package UDO_PKG_EXS_INV as

  /* ����������� �������������� - �������������� */
  procedure CHECKAUTH
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ����������� �������������� - ���������� ������������� */
  procedure GETUSERS
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

end;
/
create or replace package body UDO_PKG_EXS_INV as

  /* ��������� - ���� */
  STSD                      constant varchar2(20) := 'tsd';
  SCHECKAUTHRESPONSE        constant varchar2(20) := 'CheckAuthResponse';
  SGETUSERSRESPONSE         constant varchar2(20) := 'GetUsersResponse';  
  SDEVICEID                 constant varchar2(20) := 'DeviceID';
  SRESULT                   constant varchar2(20) := 'Result';
  SSOAPENV                  constant varchar2(20) := 'soapenv';
  SENVELOPE                 constant varchar2(20) := 'Envelope';
  SHEADER                   constant varchar2(20) := 'Header';
  SBODY                     constant varchar2(20) := 'Body';
  SITEM                     constant varchar2(20) := 'Item';
  SCODE                     constant varchar2(20) := 'Code'; 
  SNAME                     constant varchar2(20) := 'Name';    
    
  /* �������� ����� XML */    
  function UTL_CREATENODE
  (
    XDOC                    in DBMS_XMLDOM.DOMDOCUMENT, -- ��������
    STAG                    in varchar2,                -- ������������ ����
    SNS                     in varchar2 default null,   -- ������������ ���
    SVAL                    in varchar2 default null    -- �������� ����
  ) 
  return                    DBMS_XMLDOM.DOMNODE         -- ������ �� �������������� ��� ���������
  is
    XEL                     DBMS_XMLDOM.DOMELEMENT;     -- ������� ������������ ���
    XNODE                   DBMS_XMLDOM.DOMNODE;        -- ����������� �����
    XTEXT                   DBMS_XMLDOM.DOMNODE;        -- ����� (��������) ����������� �����
  begin
    /* ���� ������ ������������ ��� */
    if (SNS is not null) then
      /* ������ ������� � ��� �������������� */
      XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG, NS => SNS);
      XNODE := DBMS_XMLDOM.MAKENODE(ELEM => XEL);
      DBMS_XMLDOM.SETPREFIX(N => XNODE, PREFIX => SNS);
    else
      /* ��� ��� ���� */
      XEL   := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG);
      XNODE := DBMS_XMLDOM.MAKENODE(ELEM => XEL);
    end if;
    /* �������� ��������� � ��������� ����� ����� */
    if (SVAL is not null) then
      XTEXT := DBMS_XMLDOM.APPENDCHILD(N        => XNODE,
                                       NEWCHILD => DBMS_XMLDOM.MAKENODE(T => DBMS_XMLDOM.CREATETEXTNODE(DOC  => XDOC,
                                                                                                        DATA => SVAL)));
    end if;
    /* ������ ��������� */
    return XNODE;
  end UTL_CREATENODE;
      
  /* ���������� �������� ����� XML */
  function UTL_GETNODEVAL
  (
    XROOTNODE               in DBMS_XMLDOM.DOMNODE, -- �������� ����� ��� ���������� ��������
    SPATTERN                in varchar2             -- ������ ��� ���������� ������
  ) 
  return                    varchar2                -- ��������� ��������
  is
    XNODE                   DBMS_XMLDOM.DOMNODE;    -- ������� ����� �� ��������� (���������� ��� ������)
    SVAL                    PKG_STD.TSTRING;        -- ��������� ������
  begin
    /* ������ ������ ����� �� ������� */
    XNODE := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XROOTNODE, PATTERN => SPATTERN);
    /* ���� ��� ��� ������ */
    if (DBMS_XMLDOM.ISNULL(N => XNODE)) then
      /* ��� � ����� */
      return null;
    end if;
    /* ���-�� ���� - ������ ������ */
    SVAL := DBMS_XMLDOM.GETNODEVALUE(DBMS_XMLDOM.GETFIRSTCHILD(N => XNODE));
    /* ����� ��������� */
    return SVAL;
  end UTL_GETNODEVAL;
      
  /* �������� ��������� ��� ������ */
  procedure UTL_CREATERESPONSEDOC
  (
    XDOC                    out DBMS_XMLDOM.DOMDOCUMENT -- ����� ��� ���������
  )
  is
  begin
    /* ������ ����� �������� */
    XDOC := DBMS_XMLDOM.NEWDOMDOCUMENT();
    /* ���������� ��������� ��������� */
    DBMS_XMLDOM.SETVERSION(DOC => XDOC, VERSION => '1.0" encoding="UTF-8');
    /* ���������� ��������� */
    DBMS_XMLDOM.SETCHARSET(DOC => XDOC, CHARSET => 'UTF-8');
  end UTL_CREATERESPONSEDOC;
      
  /* ����������� ������ �� ������ �� XML-��������� (���������� � ������� �������������� ������) */
  function UTL_CREATERESPONSE
  (
    XDOC                    in DBMS_XMLDOM.DOMDOCUMENT, -- ��������
    XCONTENT                in DBMS_XMLDOM.DOMNODE      -- ������������ ���� � ������������ ���������
  ) return                  clob                        -- ��������� ������
  is
    XMAIN_NODE              DBMS_XMLDOM.DOMNODE;
    XENVELOPE_EL            DBMS_XMLDOM.DOMELEMENT;
    XENVELOPE               DBMS_XMLDOM.DOMNODE;
    XHEADER                 DBMS_XMLDOM.DOMNODE;
    XBODY                   DBMS_XMLDOM.DOMNODE;
    XNODE                   DBMS_XMLDOM.DOMNODE;
    CDATA                   clob;                       -- ����� ��� ����������
  begin
    /* ���������� �������� */
    XMAIN_NODE := DBMS_XMLDOM.MAKENODE(DOC => XDOC);
    /* ������ ��� � ������� */
    XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => SENVELOPE, NS => SSOAPENV);
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:soapenv',
                             NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:tsd',
                             NEWVALUE => 'http://www.example.org/TSDService/');
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => XENVELOPE_EL);
    DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SSOAPENV);
    XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
    /* ���������� ��������� */
    XHEADER := UTL_CREATENODE(XDOC => XDOC, STAG => SHEADER, SNS => SSOAPENV);
    XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
    /* ���������� ���� */
    XBODY := UTL_CREATENODE(XDOC => XDOC, STAG => SBODY, SNS => SSOAPENV);
    XBODY := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XBODY);
    XNODE := DBMS_XMLDOM.APPENDCHILD(N => XBODY, NEWCHILD => XCONTENT);
    /* ������������ � CLOB */
    DBMS_LOB.CREATETEMPORARY(LOB_LOC => CDATA, CACHE => true, DUR => DBMS_LOB.SESSION);
    DBMS_XMLDOM.WRITETOCLOB(DOC => XDOC, CL => CDATA, CHARSET => 'UTF-8');
    DBMS_XMLDOM.FREEDOCUMENT(DOC => XDOC);
    /* ������ ��������� */
    return CDATA;
  end UTL_CREATERESPONSE;

  /* ����������� �������������� - �������������� */
  procedure CHECKAUTH
  (
    NIDENT                  in number,               -- ������������� ��������
    NSRV_TYPE               in number,               -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XCHECKAUTHRESPONSE      DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XRESULT                 DBMS_XMLDOM.DOMNODE;     -- ��������� ��������������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    CREQ                    clob;                    -- ����� ��� �������
    SREQDEVICEID            varchar2(30);            -- ������������� ���������� �� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������� ����� ������� */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* ������� ������� XML ������� */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* ��������� XML �� ������� */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* ����� XML �������� �� ������������ */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* ��������� �������� ������� */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* ��������� ������� ���� */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* ��������� �������� �������� ���� */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* ����� ������ �������� ������� */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* ��������� ������������� ���������� */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* �������� �������������� ���������� �� �������� */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* �������������� �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ �������� �� �������� - ���� ������ �������� �� ��, ��� ������������� ���������� ��� ������� */
    if (SREQDEVICEID is not null) then
      /* �.�. ���� �������� ��� ������� - ������ ���������� ������������� ����� */
      XCHECKAUTHRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SCHECKAUTHRESPONSE, SNS => STSD);
      XRESULT            := UTL_CREATENODE(XDOC => XDOC, STAG => SRESULT, SNS => STSD, SVAL => 'true');
      XNODE              := DBMS_XMLDOM.APPENDCHILD(N => XCHECKAUTHRESPONSE, NEWCHILD => XRESULT);
      /* ����������� ��� � ������� */
      CRESPONSE          := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XCHECKAUTHRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE));
  end CHECKAUTH;

  /* ����������� �������������� - ���������� ������������� */
  procedure GETUSERS
  (
    NIDENT                  in number,               -- ������������� ��������
    NSRV_TYPE               in number,               -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XGETUSERSRESPONSE       DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- ��� �������� ��������� ������
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- ����������� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    CREQ                    clob;                    -- ����� ��� �������
    SREQDEVICEID            varchar2(30);            -- ������������� ���������� �� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������� ����� ������� */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG);
    /* ������� ������� XML ������� */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* ��������� XML �� ������� */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* ����� XML �������� �� ������������ */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* ��������� �������� ������� */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* ��������� ������� ���� */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => SBODY);
    /* ��������� �������� �������� ���� */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* ����� ������ �������� ������� */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
    /* ��������� ������������� ���������� */
    SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDEVICEID);
    /* �������� �������������� ���������� �� �������� */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* �������������� �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ �������� �� �������� - ���� ������ �������� �� ��, ��� ������������� ���������� ��� ������� */
    if (SREQDEVICEID is not null) then
      /* ������ ������������ ��� ��� ������ */
      XGETUSERSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETUSERSRESPONSE, SNS => STSD);
      /* ������� �����������-���������������� */
      for REC in (select T.RN,
                         A.AGNABBR
                    from INVPERSONS T,
                         AGNLIST    A
                   where T.COMPANY = 136018
                     and T.AGNLIST = A.RN)
      loop
        /* �������� ���������� �� ���������� � ����� */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => SNAME, SNS => STSD, SVAL => REC.AGNABBR);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETUSERSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETUSERSRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  end GETUSERS;

end;
/
