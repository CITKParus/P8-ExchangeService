create or replace package UDO_PKG_EXS_INV as

  /* ����������� �������������� - �������������� */
  procedure CHECKAUTH
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ����������� �������������� - ���������� ������������� */
  procedure GETUSERS
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ����������� �������������� - ���������� ����� ���������� */
  procedure GETSHEETTYPES
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
  /* ����������� �������������� - ���������� ���������� ���������� �������������� */
  procedure GETSHEETS
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
  /* ����������� �������������� - ���������� ������� ���������� �������������� */
  procedure GETSHEETITEMS
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
  /* ����������� �������������� - ���������� ���� �������� */
  procedure GETSTORAGES
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );  
  
  /* ����������� �������������� - ���������� ����������� �������������� */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  ); 
  
end;
/
create or replace package body UDO_PKG_EXS_INV as

  /* ��������� - ���� */
  STSD                      constant varchar2(40) := 'tsd';
  SCHECKAUTHRESPONSE        constant varchar2(40) := 'CheckAuthResponse';
  SGETUSERSRESPONSE         constant varchar2(40) := 'GetUsersResponse';
  SGETSHEETTYPESRESPONSE    constant varchar2(40) := 'GetSheetTypesResponse';
  SGETSHEETSRESPONSE        constant varchar2(40) := 'GetSheetsResponse';
  SDEVICEID                 constant varchar2(40) := 'DeviceID';
  SRESULT                   constant varchar2(40) := 'Result';
  SSOAPENV                  constant varchar2(40) := 'soapenv';
  SENVELOPE                 constant varchar2(40) := 'Envelope';
  SHEADER                   constant varchar2(40) := 'Header';
  SBODY                     constant varchar2(40) := 'Body';
  SITEM                     constant varchar2(40) := 'Item';
  SCODE                     constant varchar2(40) := 'Code'; 
  SNAME                     constant varchar2(40) := 'Name';
  STYPECODE                 constant varchar2(40) := 'TypeCode';
  SPREFIX                   constant varchar2(40) := 'Prefix';
  SNUMBER                   constant varchar2(40) := 'Number';
  SDATE                     constant varchar2(40) := 'Date';  
    
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
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XCHECKAUTHRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end CHECKAUTH;

  /* ����������� �������������� - ���������� ������������� */
  procedure GETUSERS
  (
    NIDENT                  in number,               -- ������������� ��������
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
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETUSERS;

  /* ����������� �������������� - ���������� ����� ���������� */
  procedure GETSHEETTYPES
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XGETSHEETTYPESRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
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
      XGETSHEETTYPESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSHEETTYPESRESPONSE, SNS => STSD);
      /* ������� ���� ���������� ��������� � �������� "����������� ��������������" */
      for REC in (select T.RN,
                         T.DOCCODE
                    from DOCTYPES    T,
                         COMPVERLIST CV
                   where T.VERSION = CV.VERSION
                     and CV.COMPANY = 136018
                     and T.RN in (select DOCRN from DOCPARAMS where DOCPARAMS.UNITCODE = 'ElectronicInventories')
                   order by T.DOCCODE)
      loop
        /* �������� ���������� �� ���� ��������� � ����� */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => SNAME, SNS => STSD, SVAL => REC.DOCCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETTYPESRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETTYPESRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETTYPES;
  
  /* ����������� �������������� - ���������� ���������� ���������� �������������� */
  procedure GETSHEETS
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XGETSHEETSRESPONSE      DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- ��� �������� ��������� ������
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- ����������� �������� ��������� ������
    XTYPECODE               DBMS_XMLDOM.DOMNODE;     -- ��� ��������� �������� ��������� ������
    XPREFIX                 DBMS_XMLDOM.DOMNODE;     -- ������� ��������� �������� ��������� ������
    XNUMBER                 DBMS_XMLDOM.DOMNODE;     -- ����� ��������� �������� ��������� ������
    XDATE                   DBMS_XMLDOM.DOMNODE;     -- ���� ��������� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    CREQ                    clob;                    -- ����� ��� �������
    SREQDEVICEID            varchar2(30);            -- ������������� ���������� �� �������
    NREQTYPECODE            number(17);              -- ��� ��������� �� ������� (�������� ������)
    SREQPREFIX              varchar2(30);            -- ������� ��������� �� ������� (�������� ������)
    SREQNUMBER              varchar2(30);            -- ����� ��������� �� ������� (�������� ������)
    DREQDATE                date;                    -- ���� ��������� �� ������� (�������� ������)
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
    /* ��������� "��� ���������" (�������� ������) */
    NREQTYPECODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STYPECODE));
    /* ��������� "�������" (�������� ������) */
    SREQPREFIX := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SPREFIX);
    /* ��������� "�����" (�������� ������) */
    SREQNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SNUMBER);
    /* ��������� "����" (�������� ������) */
    DREQDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDATE), 'yyyy-mm-dd');
    /* �������� �������������� ���������� �� �������� */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* �������������� �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ �������� �� �������� - ���� ������ �������� �� ��, ��� ������������� ���������� ��� ������� */
    if (SREQDEVICEID is not null) then
      /* ������ ������������ ��� ��� ������ */
      XGETSHEETSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSHEETSRESPONSE, SNS => STSD);
      /* ������� ���� ���������� ��������� � �������� "����������� ��������������" */
      for REC in (select T.RN,
                         T.DOC_TYPE,
                         DT.DOCCODE as DOC_TYPE_CODE,
                         trim(T.DOC_PREF) as DOC_PREF,
                         trim(T.DOC_NUMB) as DOC_NUMB,
                         T.DOC_DATE
                    from ELINVENTORY T,
                         DOCTYPES    DT
                   where T.COMPANY = 136018
                     and T.DOC_TYPE = DT.RN
                     and (NREQTYPECODE is null or (NREQTYPECODE is not null and T.DOC_TYPE = NREQTYPECODE))
                     and (SREQPREFIX is null or (SREQPREFIX is not null and trim(T.DOC_PREF) = SREQPREFIX))
                     and (SREQNUMBER is null or (SREQNUMBER is not null and trim(T.DOC_NUMB) = SREQNUMBER))
                     and (DREQDATE is null or (DREQDATE is not null and T.DOC_DATE = DREQDATE)))
      loop
        /* �������� ���������� �� ��������� � ����� */
        XITEM     := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE     := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.RN);
        XNAME     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => SNAME,
                                    SNS  => STSD,
                                    SVAL => REC.DOC_TYPE_CODE || ', ' || REC.DOC_PREF || '-' || REC.DOC_NUMB || ', ' ||
                                            TO_CHAR(REC.DOC_DATE, 'dd.mm.yyyy'));
        XTYPECODE := UTL_CREATENODE(XDOC => XDOC, STAG => STYPECODE, SNS => STSD, SVAL => REC.DOC_TYPE);
        XPREFIX   := UTL_CREATENODE(XDOC => XDOC, STAG => SPREFIX, SNS => STSD, SVAL => REC.DOC_PREF);
        XNUMBER   := UTL_CREATENODE(XDOC => XDOC, STAG => SNUMBER, SNS => STSD, SVAL => REC.DOC_NUMB);
        XDATE     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => SDATE,
                                    SNS  => STSD,
                                    SVAL => TO_CHAR(REC.DOC_DATE, 'yyyy-mm-dd'));
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XTYPECODE);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XPREFIX);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNUMBER);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XDATE);
        XNODE     := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETSRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETS;
  
  /* ����������� �������������� - ���������� ������� ���������� �������������� */
  procedure GETSHEETITEMS
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end GETSHEETITEMS;
  
  /* ����������� �������������� - ���������� ���� �������� */
  procedure GETSTORAGES
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end GETSTORAGES;

  /* ����������� �������������� - ���������� ����������� �������������� */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end SAVESHEETITEM; 

end;
/
