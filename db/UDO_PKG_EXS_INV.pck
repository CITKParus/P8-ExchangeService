create or replace package UDO_PKG_EXS_INV as

  /* ���������� �������� ������������ �������� �� �������� ������ ��������������� ������� */
  function UTL_GEOGRAFY_GET_HIER_ITEM
  (
    NGEOGRAFY               in number,  -- ��������������� ����� ��������������� �������
    NGEOGRTYPE              in number   -- ��� �������� ������������ �������� ������ (1 - ������, 2 - ������, 3 - �����, 4 - ���������� �����, 5 - �����, 6 - ���������������� �����, 7 - ������������� �����, 8 - �����, 9 - ������� ��������������� ����������, 10 - ������� �������������� ����������, 11 - ������� ����������� �������������� ����������� ��������)
  ) return                  varchar2;   -- ������������ ���������� ����������� �������� ������
  
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
  
  /* ����������� �������������� - ���������� ����������� �������������� (����, ������!!!!) */
  procedure SAVESHEETITEM_TMP
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
  SGETSTORAGESRESPONSE      constant varchar2(40) := 'GetStoragesResponse';
  SGETSHEETITEMSRESPONSE    constant varchar2(40) := 'GetSheetItemsResponse';
  SSAVESHEETITEMRESPONSE    constant varchar2(40) := 'SaveSheetItemResponse';
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
  SSHEETCODE                constant varchar2(40) := 'SheetCode';
  SMNEMOCODE                constant varchar2(40) := 'MnemoCode';
  SLATITUDE                 constant varchar2(40) := 'Latitude';
  SLONGITUDE                constant varchar2(40) := 'Longitude';
  SPOSTCODE                 constant varchar2(40) := 'Postcode';
  SCOUNTRY                  constant varchar2(40) := 'Country';
  SREGION                   constant varchar2(40) := 'Region';
  SLOCALITY                 constant varchar2(40) := 'Locality';
  SSTREET                   constant varchar2(40) := 'Street';
  SHOUSENUMBER              constant varchar2(40) := 'HouseNumber';
  SSTORAGEMNEMOCODE         constant varchar2(40) := 'StorageMnemoCode';
  SUSERCODE                 constant varchar2(40) := 'UserCode';
  SITEMCODE                 constant varchar2(40) := 'ItemCode';
  SITEMNAME                 constant varchar2(40) := 'ItemName';
  SITEMMNEMOCODE            constant varchar2(40) := 'ItemMnemoCode';
  SITEMNUMBER               constant varchar2(40) := 'ItemNumber';
  SQUANTITY                 constant varchar2(40) := 'Quantity';
  SSTORAGEISNEW             constant varchar2(40) := 'StorageIsNew';
  SSTORAGECODE              constant varchar2(40) := 'StorageCode';
  SSTORAGENAME              constant varchar2(40) := 'StorageName';
  SSTORAGEPOSTCODE          constant varchar2(40) := 'StoragePostcode';
  SSTORAGECOUNTRY           constant varchar2(40) := 'StorageCountry';
  SSTORAGEREGION            constant varchar2(40) := 'StorageRegion';
  SSTORAGELOCALITY          constant varchar2(40) := 'StorageLocality';
  SSTORAGESTREET            constant varchar2(40) := 'StorageStreet';
  SSTORAGEHOUSENUMBER       constant varchar2(40) := 'StorageHouseNumber';
  SSTORAGELATITUDE          constant varchar2(40) := 'StorageLatitude';
  SSTORAGELONGITUDE         constant varchar2(40) := 'StorageLongitude';
  SCHECKDATE                constant varchar2(40) := 'CheckDate';
  SCOMMENT                  constant varchar2(40) := 'Comment';
  SDISTANCETOSTORAGE        constant varchar2(40) := 'DistanceToStorage';
  SFLOOR                    constant varchar2(40) := 'Floor';
  SROOM                     constant varchar2(40) := 'Room';
  SRACK                     constant varchar2(40) := 'Rack'; 
  SFAULT                    constant varchar2(40) := 'Fault';
  SDETAIL                   constant varchar2(40) := 'detail';
  SMESSAGE                  constant varchar2(40) := 'Message';
  SERRORMESSAGE             constant varchar2(40) := 'ErrorMessage';
   
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
    XMAIN_NODE              DBMS_XMLDOM.DOMNODE;        -- �������� ������� ���������
    XENVELOPE_EL            DBMS_XMLDOM.DOMELEMENT;     -- ������� ��� ������ ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;        -- ������ ������
    XHEADER                 DBMS_XMLDOM.DOMNODE;        -- ������� ��� ���������� ������
    XBODY                   DBMS_XMLDOM.DOMNODE;        -- ������� ��� ���� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;        -- ������� ������� ���������
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
  
  /* ������������ ������ � ������� */
  function UTL_CREATEERRORRESPONSE
  (
    XDOC                    in DBMS_XMLDOM.DOMDOCUMENT, -- ��������
    SMSG                    in varchar2                 -- ��������� �� ������
  ) return                  clob                        -- ��������� ������     
  is
    XFAULT                  DBMS_XMLDOM.DOMNODE;        --
    XDETAIL                 DBMS_XMLDOM.DOMNODE;        -- 
    XERRMSG                 DBMS_XMLDOM.DOMNODE;        --
    XMSG                    DBMS_XMLDOM.DOMNODE;        --
    XNODE                   DBMS_XMLDOM.DOMNODE;        --
    CDATA                   clob;                       -- ����� ��� ����������
  begin
    /* �������� ������ � ����� */
    XFAULT  := UTL_CREATENODE(XDOC => XDOC, STAG => SFAULT, SNS => SSOAPENV);
    XDETAIL := UTL_CREATENODE(XDOC => XDOC, STAG => SDETAIL);
    XERRMSG := UTL_CREATENODE(XDOC => XDOC, STAG => SERRORMESSAGE, SNS => STSD);
    XMSG    := UTL_CREATENODE(XDOC => XDOC, STAG => SMESSAGE, SNS => STSD, SVAL => SMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XDETAIL, NEWCHILD => XERRMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XFAULT, NEWCHILD => XDETAIL);
    CDATA   := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XFAULT);
    /* ���������� ��������� */
    return CDATA;
  end UTL_CREATEERRORRESPONSE;
  
  
  /* ���������� �������� ������������ �������� �� �������� ������ ��������������� ������� */
  function UTL_GEOGRAFY_GET_HIER_ITEM
  (
    NGEOGRAFY               in number,       -- ��������������� ����� ��������������� �������
    NGEOGRTYPE              in number        -- ��� �������� ������������ �������� ������ (1 - ������, 2 - ������, 3 - �����, 4 - ���������� �����, 5 - �����, 6 - ���������������� �����, 7 - ������������� �����, 8 - �����, 9 - ������� ��������������� ����������, 10 - ������� �������������� ����������, 11 - ������� ����������� �������������� ����������� ��������)
  ) return                  varchar2         -- ������������ ���������� ����������� �������� ������
  is
    SRES                    PKG_STD.TSTRING; -- ��������� ������
  begin
    /* ������� ����� ����� ����� */
    for REC in (select G.GEOGRNAME,
                       G.GEOGRTYPE
                  from GEOGRAFY G
                connect by prior G.PRN = G.RN
                 start with G.RN = NGEOGRAFY)
    loop
      if (REC.GEOGRTYPE = NGEOGRTYPE) then
        SRES := REC.GEOGRNAME;
        exit;
      end if;
    end loop;
    /* ����� ��������� */
    return SRES;
  end UTL_GEOGRAFY_GET_HIER_ITEM;

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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
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
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQTYPECODE            PKG_STD.TREF;            -- ��� ��������� �� ������� (�������� ������)
    SREQPREFIX              PKG_STD.TSTRING;         -- ������� ��������� �� ������� (�������� ������)
    SREQNUMBER              PKG_STD.TSTRING;         -- ����� ��������� �� ������� (�������� ������)
    DREQDATE                PKG_STD.TLDATE;          -- ���� ��������� �� ������� (�������� ������)
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
      /* ������� ������ ������� "����������� ��������������" ��������������� �������� ������ */
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
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XGETSHEETITEMSRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XSTORAGEMNEMOCODE       DBMS_XMLDOM.DOMNODE;     -- �������� �������������� ��� �������� ��������� ������
    XUSERCODE               DBMS_XMLDOM.DOMNODE;     -- ��� ��� �������� ��������� ������
    XITEMCODE               DBMS_XMLDOM.DOMNODE;     -- ������������� �� ��� �������� ��������� ������
    XITEMNAME               DBMS_XMLDOM.DOMNODE;     -- ������������ �� ��� �������� ��������� ������
    XITEMMNEMOCODE          DBMS_XMLDOM.DOMNODE;     -- ��� �� ��� �������� ��������� ������
    XITEMNUMBER             DBMS_XMLDOM.DOMNODE;     -- ����� �� ��� �������� ��������� ������
    XQUANTITY               DBMS_XMLDOM.DOMNODE;     -- ���������� �� ��� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    CREQ                    clob;                    -- ����� ��� �������
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQSHEETCODE           PKG_STD.TREF;            -- ��������� �� ������� (�������� ������)
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
    /* ��������� "��������������� ����� ���������" (�������� ������) */
    NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSHEETCODE));
    /* �������� �������������� ���������� �� �������� */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* �������������� �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ �������� �� �������� - ���� ������ �������� �� ��, ��� ������������� ���������� ��� ������� */
    if (SREQDEVICEID is not null) then
      /* ������ ������������ ��� ��� ������ */
      XGETSHEETITEMSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSHEETITEMSRESPONSE, SNS => STSD);
      /* ������� ���� ���������� ��������� � �������� "����������� ��������������" */
      for REC in (select DECODE(T.INVPACK, null, O.PLACE_MNEMO, OP.PLACE_MNEMO) SSTORAGEMNEMOCODE,
                         DECODE(T.INVPACK, null, O.BARCODE, OP.BARCODE) SOBARCODE,
                         T.INVPERSONS NINVPERSONS,
                         DECODE(PS.RN,
                                null,
                                DECODE(T.INVPACK, null, DECODE(T.INVSUBST, null, I.BARCODE, U.BARCODE), P.BARCODE),
                                PS.BARCODE) SIBARCODE,
                         N1.NOMEN_CODE SNOM_CODE,
                         N1.NOMEN_NAME SNOM_NAME,
                         I.INV_NUMBER SINV_NUMBER,
                         '1' SQUANTITY
                    from ELINVOBJECT T,
                         INVENTORY   I,
                         DICPLACE    O,
                         DICPLACE    OP,
                         INVPACK     P,
                         INVPACKPOS  PS,
                         INVSUBST    U,
                         DICNOMNS    N1
                   where T.COMPANY = 136018
                     and T.PRN = NREQSHEETCODE
                     and T.INVENTORY = I.RN
                     and I.OBJECT_PLACE = O.RN(+)
                     and T.INVPACK = P.RN(+)
                     and P.OBJECT_PLACE = OP.RN(+)
                     and T.INVPACK = PS.PRN(+)
                     and T.INVSUBST = PS.INVSUBST(+)
                     and T.INVSUBST = U.RN(+)
                     and I.NOMENCLATURE = N1.RN)
      loop
        /* �������� ���������� �� ��������� ��������� � ����� */
        XITEM             := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XSTORAGEMNEMOCODE := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => SSTORAGEMNEMOCODE,
                                            SNS  => STSD,
                                            SVAL => REC.SSTORAGEMNEMOCODE);
        XUSERCODE         := UTL_CREATENODE(XDOC => XDOC, STAG => SUSERCODE, SNS => STSD, SVAL => trim(REC.NINVPERSONS));
        XITEMCODE         := UTL_CREATENODE(XDOC => XDOC, STAG => SITEMCODE, SNS => STSD, SVAL => trim(REC.SIBARCODE));
        XITEMNAME         := UTL_CREATENODE(XDOC => XDOC, STAG => SITEMNAME, SNS => STSD, SVAL => trim(REC.SNOM_NAME));
        XITEMMNEMOCODE    := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => SITEMMNEMOCODE,
                                            SNS  => STSD,
                                            SVAL => trim(REC.SNOM_CODE));
        XITEMNUMBER       := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => SITEMNUMBER,
                                            SNS  => STSD,
                                            SVAL => trim(REC.SINV_NUMBER));
        XQUANTITY         := UTL_CREATENODE(XDOC => XDOC, STAG => SQUANTITY, SNS => STSD, SVAL => REC.SQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XSTORAGEMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XUSERCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNAME);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNUMBER);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETITEMSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETITEMSRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETITEMS;
  
  /* ����������� �������������� - ���������� ���� �������� */
  procedure GETSTORAGES
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XGETSTORAGESRESPONSE    DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- ��� �������� ��������� ������
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- ����������� �������� ��������� ������
    XMNEMOCODE              DBMS_XMLDOM.DOMNODE;     -- �������� �������������� ��� �������� ��������� ������
    XLATITUDE               DBMS_XMLDOM.DOMNODE;     -- ������ �������������� ��� �������� ��������� ������
    XLONGITUDE              DBMS_XMLDOM.DOMNODE;     -- ������� �������������� ��� �������� ��������� ������
    XPOSTCODE               DBMS_XMLDOM.DOMNODE;     -- �������� ������ �������������� ��� �������� ��������� ������
    XCOUNTRY                DBMS_XMLDOM.DOMNODE;     -- ������ �������������� ��� �������� ��������� ������
    XREGION                 DBMS_XMLDOM.DOMNODE;     -- ������ �������������� ��� �������� ��������� ������
    XLOCALITY               DBMS_XMLDOM.DOMNODE;     -- ��������� ����� �������������� ��� �������� ��������� ������
    XSTREET                 DBMS_XMLDOM.DOMNODE;     -- ����� �������������� ��� �������� ��������� ������
    XHOUSENUMBER            DBMS_XMLDOM.DOMNODE;     -- ����� ���� �������������� ��� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    CREQ                    clob;                    -- ����� ��� �������
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQSHEETCODE           PKG_STD.TREF;            -- ��������� �� ������� (�������� ������)
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
    /* ��������� "��������������� ����� ���������" (�������� ������) */
    NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSHEETCODE));
    /* �������� �������������� ���������� �� �������� */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* �������������� �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ �������� �� �������� - ���� ������ �������� �� ��, ��� ������������� ���������� ��� ������� */
    if (SREQDEVICEID is not null) then
      /* ������ ������������ ��� ��� ������ */
      XGETSTORAGESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SGETSTORAGESRESPONSE, SNS => STSD);
      /* ������� ����� �������� */
      for REC in (select T.RN NRN,
                         T.PLACE_MNEMO SMNEMOCODE,
                         T.PLACE_NAME SNAME,
                         UDO_F_GET_DOC_PROP_VAL_STR('LATITUDE', 'ObjPlace', T.RN) SLATITUDE,
                         UDO_F_GET_DOC_PROP_VAL_STR('LONGITUDE', 'ObjPlace', T.RN) SLONGITUDE,
                         nvl(T.ADDR_POST, G.POSTAL_CODE) SPOSTCODE,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 1) SCOUNTRY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2) SREGION,
                         NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 8),
                             NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 4),
                                 NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 3), UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2)))) SLOCALITY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 5) SSTREET,
                         T.ADDR_HOUSE SHOUSENUMBER
                    from DICPLACE T,
                         GEOGRAFY G
                   where T.COMPANY = 136018
                     and T.GEOGRAFY = G.RN(+)
                     and ((NREQSHEETCODE is null) or
                         ((NREQSHEETCODE is not null) and
                         (T.RN in (select DECODE(EO.INVPACK, null, INV.OBJECT_PLACE, P.OBJECT_PLACE)
                                       from ELINVOBJECT EO,
                                            INVENTORY   INV,
                                            INVPACK     P
                                      where EO.PRN = NREQSHEETCODE
                                        and EO.INVENTORY = INV.RN
                                        and EO.INVPACK = P.RN(+))))))
      loop
        /* �������� ���������� �� ����� �������� � ����� */
        XITEM        := UTL_CREATENODE(XDOC => XDOC, STAG => SITEM, SNS => STSD);
        XCODE        := UTL_CREATENODE(XDOC => XDOC, STAG => SCODE, SNS => STSD, SVAL => REC.NRN);
        XNAME        := UTL_CREATENODE(XDOC => XDOC, STAG => SNAME, SNS => STSD, SVAL => REC.SNAME);
        XMNEMOCODE   := UTL_CREATENODE(XDOC => XDOC, STAG => SMNEMOCODE, SNS => STSD, SVAL => REC.SMNEMOCODE);
        XLATITUDE    := UTL_CREATENODE(XDOC => XDOC, STAG => SLATITUDE, SNS => STSD, SVAL => REC.SLATITUDE);
        XLONGITUDE   := UTL_CREATENODE(XDOC => XDOC, STAG => SLONGITUDE, SNS => STSD, SVAL => REC.SLONGITUDE);
        XPOSTCODE    := UTL_CREATENODE(XDOC => XDOC, STAG => SPOSTCODE, SNS => STSD, SVAL => REC.SPOSTCODE);
        XCOUNTRY     := UTL_CREATENODE(XDOC => XDOC, STAG => SCOUNTRY, SNS => STSD, SVAL => REC.SCOUNTRY);
        XREGION      := UTL_CREATENODE(XDOC => XDOC, STAG => SREGION, SNS => STSD, SVAL => REC.SREGION);
        XLOCALITY    := UTL_CREATENODE(XDOC => XDOC, STAG => SLOCALITY, SNS => STSD, SVAL => REC.SLOCALITY);
        XSTREET      := UTL_CREATENODE(XDOC => XDOC, STAG => SSTREET, SNS => STSD, SVAL => REC.SSTREET);
        XHOUSENUMBER := UTL_CREATENODE(XDOC => XDOC, STAG => SHOUSENUMBER, SNS => STSD, SVAL => REC.SHOUSENUMBER);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XMNEMOCODE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XLATITUDE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XLONGITUDE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XPOSTCODE);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCOUNTRY);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XREGION);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XLOCALITY);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XSTREET);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XHOUSENUMBER);
        XNODE        := DBMS_XMLDOM.APPENDCHILD(N => XGETSTORAGESRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSTORAGESRESPONSE);
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSTORAGES;

  /* ����������� �������������� - ���������� ����������� �������������� */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XSAVESHEETITEMRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    CREQ                    clob;                    -- ����� ��� �������
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQSHEETCODE           PKG_STD.TREF;            -- ��������� �� ������� (�������� ����������)
    NREQUSERCODE            PKG_STD.TREF;            -- ��������������� ����� ��� �� ������� (�������� ����������)
    SREQSTORAGEMNEMOCODE    PKG_STD.TSTRING;         -- �������� ����� �������� �� ������� (�������� ����������)
    NREQSTORAGEISNEW        PKG_STD.TNUMBER;         -- ������� ������ ����� �������� �� ������� (�������� ����������)    
    SREQSTORAGECODE         PKG_STD.TSTRING;         -- �����-��� ����� �������� �� ������� (�������� ����������)
    SREQSTORAGENAME         PKG_STD.TSTRING;         -- ������������ ����� �������� �� ������� (�������� ����������)
    SREQSTORAGEPOSTCODE     PKG_STD.TSTRING;         -- �������� ������ ����� �������� �� ������� (�������� ����������)    
    SREQSTORAGECOUNTRY      PKG_STD.TSTRING;         -- ������ ����� �������� �� ������� (�������� ����������)    
    SREQSTORAGEREGION       PKG_STD.TSTRING;         -- ������ ����� �������� �� ������� (�������� ����������)    
    SREQSTORAGELOCALITY     PKG_STD.TSTRING;         -- ���������� ����� ����� �������� �� ������� (�������� ����������)    
    SREQSTORAGESTREET       PKG_STD.TSTRING;         -- ����� ����� �������� �� ������� (�������� ����������)    
    SREQSTORAGEHOUSENUMBER  PKG_STD.TSTRING;         -- ����� ���� ����� �������� �� ������� (�������� ����������)    
    NREQSTORAGELATITUDE     PKG_STD.TLNUMBER;        -- ������ ����� �������� �� ������� (�������� ����������)    
    NREQSTORAGELONGITUDE    PKG_STD.TLNUMBER;        -- ������� ����� �������� �� ������� (�������� ����������) 
    SREQITEMCODE            PKG_STD.TSTRING;         -- �����-��� �� �� ������� (�������� ����������)  
    SREQITEMNAME            PKG_STD.TSTRING;         -- ������������ ������������ �� �� ������� (�������� ����������)
    SREQITEMMNEMOCODE       PKG_STD.TSTRING;         -- �������� ������������ �� �� ������� (�������� ����������)
    SREQITEMNUMBER          PKG_STD.TSTRING;         -- ����������� ����� �� �� ������� (�������� ����������)
    NREQQUANTITY            PKG_STD.TQUANT;          -- ���������� �� �� ������� (�������� ����������)    
    DREQCHECKDATE           PKG_STD.TLDATE;          -- ���� ���������� �������������� �� �� ������� (�������� ����������)  
    SREQCOMMENT             PKG_STD.TLSTRING;        -- ����������� ��� �� �� ������� (�������� ����������)
    NREQLATITUDE            PKG_STD.TLNUMBER;        -- ������ �� ������� (�������� ����������) 
    NREQLONGITUDE           PKG_STD.TLNUMBER;        -- ������� �� ������� (�������� ����������)    
    NREQDISTANCETOSTORAGE   PKG_STD.TLNUMBER;        -- ���������� �� ����� �������� �� �� ������� (�������� ����������)    
    SREQFLOOR               PKG_STD.TSTRING;         -- ���� ������������ �� �� ������� (�������� ����������)
    SREQROOM                PKG_STD.TSTRING;         -- ��������� ������������ �� �� ������� (�������� ����������)
    SREQRACK                PKG_STD.TSTRING;         -- ������� ������������ �� �� ������� (�������� ����������)
    NELINVOBJECT            PKG_STD.TREF;            -- ���. ����� ������� ��������� ��������������
    NDICPLACE               PKG_STD.TREF;            -- ���. ����� ����� ��������
    NINVENTORY              PKG_STD.TREF;            -- ���. ����� �� (�������� "����������� ���������")
    NCOMPANY                PKG_STD.TREF;            -- ���. ����� �����������
    SERR                    PKG_STD.TSTRING;         -- ����� ��� ������
  begin
    /* �������������� ����������� */
    NCOMPANY := 136018;
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
    /* ��������� "��������������� ����� ���������" (�������� ����������) */
    NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSHEETCODE));
    /* ��������� "��������������� ����� ���" (�������� ����������) */
    NREQUSERCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SUSERCODE));
    /* ��������� "�������� ����� ��������" (�������� ����������) */
    SREQSTORAGEMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEMNEMOCODE);
    /* ��������� "������� ������ ����� ��������" (�������� ����������) */
    NREQSTORAGEISNEW := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEISNEW));
    /* ��������� "�����-��� ����� ��������" (�������� ����������) */
    SREQSTORAGECODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGECODE);
    /* ��������� "������������ ����� ��������" (�������� ����������) */
    SREQSTORAGENAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGENAME);
    /* ��������� "�������� ������ ����� ��������" (�������� ����������) */
    SREQSTORAGEPOSTCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEPOSTCODE);
    /* ��������� "������ ����� ��������" (�������� ����������) */
    SREQSTORAGECOUNTRY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGECOUNTRY);
    /* ��������� "������ ����� ��������" (�������� ����������) */
    SREQSTORAGEREGION := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEREGION);
    /* ��������� "���������� ����� ����� ��������" (�������� ����������) */
    SREQSTORAGELOCALITY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGELOCALITY);
    /* ��������� "����� ����� ��������" (�������� ����������) */
    SREQSTORAGESTREET := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGESTREET);
    /* ��������� "����� ���� ����� ��������" (�������� ����������) */
    SREQSTORAGEHOUSENUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGEHOUSENUMBER);
    /* ��������� "������ ����� ��������" (�������� ����������) */
    NREQSTORAGELATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGELATITUDE));
    /* ��������� "������� ����� ��������" (�������� ����������) */
    NREQSTORAGELONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SSTORAGELONGITUDE));
    /* ��������� "�����-��� ��" (�������� ����������) */
    SREQITEMCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMCODE);
    /* ��������� "������������ ������������ ��" (�������� ����������) */
    SREQITEMNAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMNAME);
    /* ��������� "�������� ������������ ��" (�������� ����������) */
    SREQITEMMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMMNEMOCODE);
    /* ��������� "����������� ����� ��" (�������� ����������) */
    SREQITEMNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SITEMNUMBER);
    /* ��������� "���������� ��" (�������� ����������) */
    NREQQUANTITY := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SQUANTITY));
    /* ��������� "���� ���������� �������������� ��" (�������� ����������) */
    DREQCHECKDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SCHECKDATE), 'yyyy-mm-dd');
    /* ��������� "����������� ��� ��" (�������� ����������) */
    SREQCOMMENT := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SCOMMENT);
    /* ��������� "������" (�������� ����������) */
    NREQLATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SLATITUDE));
    /* ��������� "�������" (�������� ����������) */
    NREQLONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SLONGITUDE));
    /* ��������� "���������� �� ����� �������� ��" (�������� ����������) */
    NREQDISTANCETOSTORAGE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SDISTANCETOSTORAGE));
    /* ��������� "���� ������������ ��" (�������� ����������) */
    SREQFLOOR := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SFLOOR);
    /* ��������� "��������� ������������ ��" (�������� ����������) */
    SREQROOM := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SROOM);
    /* ��������� "������� ������������ ��" (�������� ����������) */
    SREQRACK := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => SRACK);
    /* �������� �������������� ���������� �� �������� */
    /* UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID); */
    /* �������������� �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ �������� �� �������� - ���� ������ �������� �� ��, ��� ������������� ���������� ��� ������� */
    if (SREQDEVICEID is not null) then
      if ((NREQSHEETCODE is not null) and (DREQCHECKDATE is not null)) then
        /*
        TODO: owner="root" created="14.01.2019"
        text="������ ����� �� ��� ������ (������ ���������� �������� �� ����).
              ���� ����������� ���������� ������ ��������������� + ����� ��������"
        */
        /* ���� ����� �����-��� �������������� �� */
        if (SREQSTORAGECODE is not null) then
          /* ��������� ���������������� �� �����-���� */
          begin
            select T.RN
              into NDICPLACE
              from DICPLACE T
             where T.COMPANY = NCOMPANY
               and T.BARCODE = SREQSTORAGECODE;
          exception
            when NO_DATA_FOUND then
              SERR := '��������������� ����������� �������� � �����-�����: ' || SREQSTORAGECODE || ' �� �������';
          end;
        end if;
        /* ������� ����� ������� ��������� �������������� �� �����-���� (���� ������� ���. ����� ��������� � ���� ��� ������) */
        if ((NREQSHEETCODE is not null) and (SERR is null)) then
          begin
            select T.NRN
              into NELINVOBJECT
              from V_ELINVOBJECT T
             where T.NCOMPANY = NCOMPANY
               and T.NPRN = NREQSHEETCODE
               and T.SIBARCODE = SREQITEMCODE;
          exception
            when NO_DATA_FOUND then
              /* ���� ���. ����� �� �� ���������, ���� �� ����� ������� ��������� �������������� */
              begin
                select T.RN
                  into NINVENTORY
                  from INVENTORY T
                 where T.BARCODE = SREQITEMCODE
                   and T.COMPANY = NCOMPANY;
              exception
                when NO_DATA_FOUND then
                  SERR := '����������� �������� � �����-�����: ' || SREQITEMCODE || ' �� �������';
              end;
          end;
        end if;
        /* ���� ��� ������ ��� ��������� */
        if (SERR is null) then
          /* ���� ������� ��������� �������������� ������� */
          if (NELINVOBJECT is not null) then
            /* ������� � */
            P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => NCOMPANY,
                                      NRN          => NELINVOBJECT,
                                      DUNLOAD_DATE => null,
                                      DINV_DATE    => DREQCHECKDATE,
                                      NINVPERSONS  => NREQUSERCODE,
                                      SBARCODE     => SREQSTORAGECODE,
                                      NIS_LOADED   => 0);
          else
            /* ��� ������� � ��������� ��������� �� ���� �� ����� ������� ��������� �� �����-���� */
            P_ELINVOBJECT_BASE_INSERT(NCOMPANY     => NCOMPANY,
                                      NPRN         => NREQSHEETCODE,
                                      NINVENTORY   => NINVENTORY,
                                      NINVSUBST    => null,
                                      NINVPACK     => null,
                                      DUNLOAD_DATE => null,
                                      DINV_DATE    => DREQCHECKDATE,
                                      NINVPERSONS  => NREQUSERCODE,
                                      SBARCODE     => SREQSTORAGECODE,
                                      NIS_LOADED   => 1,
                                      NRN          => NELINVOBJECT);
          end if;
        end if;
      end if;
      /* ���� ��� ������ */
      if (SERR is null) then
        /* ������ ������������ ��� ��� ������ */
        XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SSAVESHEETITEMRESPONSE, SNS => STSD);
        /* ��������� ��������� */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SRESULT, SNS => STSD, SVAL => 'true');
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
        /* ����������� ����� � ������� */
        CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
      else
        CRESPONSE := UTL_CREATEERRORRESPONSE(XDOC => XDOC, SMSG => SERR);
      end if;
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end SAVESHEETITEM;
  
  /* ����������� �������������� - ���������� ����������� �������������� (����, ������!!!!) */
  procedure SAVESHEETITEM_TMP
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    CRESPONSE               clob;                    -- ����� ��� ������
    XSAVESHEETITEMRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
  begin
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* ������ ������������ ��� ��� ������ */
    XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => SSAVESHEETITEMRESPONSE, SNS => STSD);
    /* ��������� ��������� */
    XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => SRESULT, SNS => STSD, SVAL => 'true');
    XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
    /* ����������� ����� � ������� */
    CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end SAVESHEETITEM_TMP;

end;
/
