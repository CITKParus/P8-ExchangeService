create or replace package UDO_PKG_EXS_INV as

  /* ���������� �������� ������������ �������� �� �������� ������ ��������������� ������� */
  function UTL_GEOGRAFY_GET_HIER_ITEM
  (
    NGEOGRAFY               in number,  -- ��������������� ����� ��������������� �������
    NGEOGRTYPE              in number   -- ��� �������� ������������ �������� ������ (1 - ������, 2 - ������, 3 - �����, 4 - ���������� �����, 5 - �����, 6 - ���������������� �����, 7 - ������������� �����, 8 - �����, 9 - ������� ��������������� ����������, 10 - ������� �������������� ����������, 11 - ������� ����������� �������������� ����������� ��������)
  ) return                  varchar2;   -- ������������ ���������� ����������� �������� ������
  
  /* ����� ���������� �� ���������� ��������� */
  function UTL_GEOGRAFY_FIND_BY_HIER_ITEM
  (
    NCOMPANY              in number,    -- ���. ����� �����������
    SADDR_COUNTRY         in varchar2,  -- ������ ���������������
    SADDR_REGION          in varchar2,  -- ������ ���������������
    SADDR_LOCALITY        in varchar2,  -- ��������� ����� ���������������
    SADDR_STREET          in varchar2   -- ����� ���������������
  ) return                number;       -- �������������� �������
  
  /* ��������� ������ � ��������������� ������� ��������� �������������� */
  function UTL_ELINVOBJECT_DICPLACE_GET
  (
    NELINVOBJECT            in number,  -- ���. ����� ������ ��������� ��������������
    SRESULT_TYPE            in varchar2 -- ��� ���������� (��. ��������� SRESULT_TYPE*)
  ) return                  varchar2;   -- �����-��� ��
  
  /* ��������� �����-���� ������� ��������� �������������� */
  function UTL_ELINVOBJECT_BARCODE_GET
  (
    NELINVOBJECT            in number   -- ���. ����� ������ ��������� ��������������
  ) return                  varchar2;   -- �����-��� ��
  
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
  
  /* ����������� �������������� - ���������� ��������������� */
  procedure GETSTORAGES
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );  
  
  /* ����������� �������������� - ���������� ����������� �������������� �������� �������� */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );
  
end;
/
create or replace package body UDO_PKG_EXS_INV as

  /* ��������� - ������������ ��� */
  SNS_TSD                   constant varchar2(40) := 'tsd';
  SNS_SOAPENV               constant varchar2(40) := 'soapenv';
  
  /* ��������� - ���� */
  STAG_CHECKAUTHRSPNS       constant varchar2(40) := 'CheckAuthResponse';
  STAG_GETUSERSRSPNS        constant varchar2(40) := 'GetUsersResponse';
  STAG_GETSHEETTYPESRSPNS   constant varchar2(40) := 'GetSheetTypesResponse';
  STAG_GETSHEETSRSPNS       constant varchar2(40) := 'GetSheetsResponse';
  STAG_GETSTORAGESRSPNS     constant varchar2(40) := 'GetStoragesResponse';
  STAG_GETSHEETITEMSRSPNS   constant varchar2(40) := 'GetSheetItemsResponse';
  STAG_SAVESHEETITEMRSPNS   constant varchar2(40) := 'SaveSheetItemResponse';
  STAG_DEVICEID             constant varchar2(40) := 'DeviceID';
  STAG_RESULT               constant varchar2(40) := 'Result';
  STAG_ENVELOPE             constant varchar2(40) := 'Envelope';
  STAG_HEADER               constant varchar2(40) := 'Header';
  STAG_BODY                 constant varchar2(40) := 'Body';
  STAG_ITEM                 constant varchar2(40) := 'Item';
  STAG_CODE                 constant varchar2(40) := 'Code'; 
  STAG_NAME                 constant varchar2(40) := 'Name';
  STAG_TYPECODE             constant varchar2(40) := 'TypeCode';
  STAG_PREFIX               constant varchar2(40) := 'Prefix';
  STAG_NUMBER               constant varchar2(40) := 'Number';
  STAG_DATE                 constant varchar2(40) := 'Date';
  STAG_SHEETCODE            constant varchar2(40) := 'SheetCode';
  STAG_MNEMOCODE            constant varchar2(40) := 'MnemoCode';
  STAG_LATITUDE             constant varchar2(40) := 'Latitude';
  STAG_LONGITUDE            constant varchar2(40) := 'Longitude';
  STAG_POSTCODE             constant varchar2(40) := 'Postcode';
  STAG_COUNTRY              constant varchar2(40) := 'Country';
  STAG_REGION               constant varchar2(40) := 'Region';
  STAG_LOCALITY             constant varchar2(40) := 'Locality';
  STAG_STREET               constant varchar2(40) := 'Street';
  STAG_HOUSENUMBER          constant varchar2(40) := 'HouseNumber';
  STAG_STORAGEMNEMOCODE     constant varchar2(40) := 'StorageMnemoCode';
  STAG_USERCODE             constant varchar2(40) := 'UserCode';
  STAG_ITEMCODE             constant varchar2(40) := 'ItemCode';
  STAG_ITEMNAME             constant varchar2(40) := 'ItemName';
  STAG_ITEMMNEMOCODE        constant varchar2(40) := 'ItemMnemoCode';
  STAG_ITEMNUMBER           constant varchar2(40) := 'ItemNumber';
  STAG_QUANTITY             constant varchar2(40) := 'Quantity';
  STAG_STORAGEISNEW         constant varchar2(40) := 'StorageIsNew';
  STAG_STORAGECODE          constant varchar2(40) := 'StorageCode';
  STAG_STORAGENAME          constant varchar2(40) := 'StorageName';
  STAG_STORAGEPOSTCODE      constant varchar2(40) := 'StoragePostcode';
  STAG_STORAGECOUNTRY       constant varchar2(40) := 'StorageCountry';
  STAG_STORAGEREGION        constant varchar2(40) := 'StorageRegion';
  STAG_STORAGELOCALITY      constant varchar2(40) := 'StorageLocality';
  STAG_STORAGESTREET        constant varchar2(40) := 'StorageStreet';
  STAG_STORAGEHOUSENUMBER   constant varchar2(40) := 'StorageHouseNumber';
  STAG_STORAGELATITUDE      constant varchar2(40) := 'StorageLatitude';
  STAG_STORAGELONGITUDE     constant varchar2(40) := 'StorageLongitude';
  STAG_CHECKDATE            constant varchar2(40) := 'CheckDate';
  STAG_COMMENT              constant varchar2(40) := 'Comment';
  STAG_DISTANCETOSTORAGE    constant varchar2(40) := 'DistanceToStorage';
  STAG_FAULT                constant varchar2(40) := 'Fault';
  STAG_DETAIL               constant varchar2(40) := 'detail';
  STAG_MESSAGE              constant varchar2(40) := 'Message';  
  STAG_STORAGEMESSAGE       constant varchar2(40) := 'StorageMessage';
  STAG_ITEMMESSAGE          constant varchar2(40) := 'ItemMessage';
  STAG_ERRORMESSAGE         constant varchar2(40) := 'ErrorMessage';
  STAG_ERRORMESSAGE_SSITEM  constant varchar2(40) := 'ErrorSaveSheetItemMessage';  
  
  /* ��������� - ���� ������������ �������� */
  SRESULT_TYPE_MNEMO        constant varchar2(40):='MNEMO';   -- ��������
  SRESULT_TYPE_BARCODE      constant varchar2(40):='BARCODE'; -- �����-���
   
  /* ������������ ��������� �� ������ */
  function UTL_CORRECT_ERR
  (
    SERR                    varchar2          -- ��������� �� ������
  ) return                  varchar2          -- ��������������� ��������� �� ������
  is
    STMP                    PKG_STD.TSTRING;  -- ����� ��� ���������
    SRES                    PKG_STD.TSTRING;  -- ��������� ������
    NB                      PKG_STD.TLNUMBER; -- ������� ������ ��������� ���������
    NE                      PKG_STD.TLNUMBER; -- ������� ��������� ��������� ���������
  begin
    /* �������������� ����� */
    STMP := SERR;
    /* ������� ������ ����������� � ����������� ���������� �� ������ */
    begin
      while (INSTR(STMP, 'ORA') <> 0)
      loop
        NB   := INSTR(STMP, 'ORA');
        NE   := INSTR(STMP, ':', NB);
        STMP := trim(replace(STMP, trim(SUBSTR(STMP, NB, NE - NB + 1)), ''));
      end loop;
      SRES := STMP;
    exception
      when others then
        SRES := SERR;
    end;
    /* ���������� �������� */
    return SRES;
  end UTL_CORRECT_ERR;
  
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
    XENVELOPE_EL := DBMS_XMLDOM.CREATEELEMENT(DOC => XDOC, TAGNAME => STAG_ENVELOPE, NS => SNS_SOAPENV);
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:soapenv',
                             NEWVALUE => 'http://schemas.xmlsoap.org/soap/envelope/');
    DBMS_XMLDOM.SETATTRIBUTE(ELEM     => XENVELOPE_EL,
                             name     => 'xmlns:tsd',
                             NEWVALUE => 'http://www.example.org/TSDService/');
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => XENVELOPE_EL);
    DBMS_XMLDOM.SETPREFIX(N => XENVELOPE, PREFIX => SNS_SOAPENV);
    XENVELOPE := DBMS_XMLDOM.APPENDCHILD(N => XMAIN_NODE, NEWCHILD => XENVELOPE);
    /* ���������� ��������� */
    XHEADER := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_HEADER, SNS => SNS_SOAPENV);
    XHEADER := DBMS_XMLDOM.APPENDCHILD(N => XENVELOPE, NEWCHILD => XHEADER);
    /* ���������� ���� */
    XBODY := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_BODY, SNS => SNS_SOAPENV);
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
    SMSG                    in varchar2              -- ��������� �� ������
  ) return                  clob                     -- ��������� ������     
  is
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XFAULT                  DBMS_XMLDOM.DOMNODE;     -- �������� ����
    XDETAIL                 DBMS_XMLDOM.DOMNODE;     -- ���� ��� ����������� ������
    XERRMSG                 DBMS_XMLDOM.DOMNODE;     -- ���� � ���������� �� ������
    XMSG                    DBMS_XMLDOM.DOMNODE;     -- ���� ������� ���������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����
    CDATA                   clob;                    -- ����� ��� ����������
  begin
    /* ������ �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* �������� ������ � ����� */
    XFAULT  := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_FAULT, SNS => SNS_SOAPENV);
    XDETAIL := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_DETAIL);
    XERRMSG := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ERRORMESSAGE, SNS => SNS_TSD);
    XMSG    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_MESSAGE, SNS => SNS_TSD, SVAL => SMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XDETAIL, NEWCHILD => XERRMSG);
    XNODE   := DBMS_XMLDOM.APPENDCHILD(N => XFAULT, NEWCHILD => XDETAIL);
    CDATA   := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XFAULT);
    /* ���������� ��������� */
    return CDATA;
  end UTL_CREATEERRORRESPONSE;
  
  /* ������������ ������ � ������� ��� ��������� ������� ����������� �������������� */
  function UTL_CREATEERRORRESPONSE_SSITEM
  (
    SMSG_ELINVOBJECT        in varchar2,             -- ��������� �� ������ (��� ������������ �������)
    SMSG_DICPLACE           in varchar2              -- ��������� �� ������ (��� ���������������)
  ) return                  clob                     -- ��������� ������     
  is
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XFAULT                  DBMS_XMLDOM.DOMNODE;     -- �������� ����
    XDETAIL                 DBMS_XMLDOM.DOMNODE;     -- ���� ��� ����������� ������
    XERRMSG                 DBMS_XMLDOM.DOMNODE;     -- ���� � ���������� �� ������
    XMSG_ELINVOBJECT        DBMS_XMLDOM.DOMNODE;     -- ���� ������� ��������� (��� ������������ �������)
    XMSG_DICPLACE           DBMS_XMLDOM.DOMNODE;     -- ���� ������� ��������� (��� ���������������)
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����
    CDATA                   clob;                    -- ����� ��� ����������
  begin
    /* ������ �������� ��� ������ */
    UTL_CREATERESPONSEDOC(XDOC => XDOC);
    /* �������� ������ � ����� */
    XFAULT           := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_FAULT, SNS => SNS_SOAPENV);
    XDETAIL          := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_DETAIL);
    XERRMSG          := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ERRORMESSAGE_SSITEM, SNS => SNS_TSD);
    XMSG_ELINVOBJECT := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEMMESSAGE, SNS => SNS_TSD, SVAL => SMSG_ELINVOBJECT);
    XMSG_DICPLACE    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_STORAGEMESSAGE, SNS => SNS_TSD, SVAL => SMSG_DICPLACE);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG_ELINVOBJECT);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XERRMSG, NEWCHILD => XMSG_DICPLACE);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XDETAIL, NEWCHILD => XERRMSG);
    XNODE            := DBMS_XMLDOM.APPENDCHILD(N => XFAULT, NEWCHILD => XDETAIL);
    CDATA            := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XFAULT);
    /* ���������� ��������� */
    return CDATA;
  end UTL_CREATEERRORRESPONSE_SSITEM;
  
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
  
  /* ����� ���������� �� ���������� ��������� */
  function UTL_GEOGRAFY_FIND_BY_HIER_ITEM
  (
    NCOMPANY              in number,    -- ���. ����� �����������
    SADDR_COUNTRY         in varchar2,  -- ������ ���������������
    SADDR_REGION          in varchar2,  -- ������ ���������������
    SADDR_LOCALITY        in varchar2,  -- ��������� ����� ���������������
    SADDR_STREET          in varchar2   -- ����� ���������������
  ) return                number        -- �������������� �������
  is
    NRES                  PKG_STD.TREF; -- ���. ����� ���������� ��������������� �������
    NVERSION              PKG_STD.TREF; -- ���. ����� ������ ������� �������������� �������
  begin
    /* �������� ��������� */
    if (NCOMPANY is null) then
      return null;
    end if;
    if ((SADDR_COUNTRY is null) and (SADDR_REGION is null) and (SADDR_LOCALITY is null) and (SADDR_STREET is null)) then
      return null;
    end if;
    /* ��������� ������ ������� �������������� ������� */
    FIND_VERSION_BY_COMPANY(NCOMPANY => NCOMPANY, SUNITCODE => 'GEOGRAFY', NVERSION => NVERSION);
    /* �������� �������������� ������� - ������� ������ */
    for C in (select G.RN
                from GEOGRAFY G
               where G.VERSION = NVERSION
                 and ((SADDR_COUNTRY is null) or
                     ((SADDR_COUNTRY is not null) and (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_COUNTRY || '%'))))
                 and G.GEOGRTYPE = 1)
    loop
      /* ������ ������� ������ */
      for R in (select G.RN
                  from GEOGRAFY G
                 where G.VERSION = NVERSION
                   and ((SADDR_REGION is null) or
                       ((SADDR_REGION is not null) and (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_REGION || '%'))))
                   and G.GEOGRTYPE = 2
                   and G.RN in (select GG.RN
                                  from GEOGRAFY GG
                                 where GG.GEOGRTYPE = 2
                                connect by prior GG.RN = GG.PRN
                                 start with GG.RN = C.RN))
      loop
        /* ���������� � ���������� ������ */
        for L in (select G.RN
                    from GEOGRAFY G
                   where G.VERSION = NVERSION
                     and ((SADDR_LOCALITY is null) or ((SADDR_LOCALITY is not null) and
                         (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_LOCALITY || '%'))))
                     and G.GEOGRTYPE in (8, 4, 3, 2)
                     and G.RN in (select GG.RN
                                    from GEOGRAFY GG
                                   where GG.GEOGRTYPE in (8, 4, 3, 2)
                                  connect by prior GG.RN = GG.PRN
                                   start with GG.RN = R.RN)
                  
                  )
        loop
          /* ������ - ����� */
          for S in (select G.RN
                      from GEOGRAFY G
                     where G.VERSION = NVERSION
                       and ((SADDR_STREET is null) or
                           ((SADDR_STREET is not null) and (LOWER(G.GEOGRNAME) like LOWER('%' || SADDR_STREET || '%'))))
                       and G.GEOGRTYPE = 5
                       and G.RN in (select GG.RN
                                      from GEOGRAFY GG
                                     where GG.GEOGRTYPE = 5
                                    connect by prior GG.RN = GG.PRN
                                     start with GG.RN = L.RN)
                    
                    )
          loop
            /* ������� ���������� */
            return S.RN;
          end loop;
        end loop;
      end loop;
    end loop;
    /* ����� ������ ��������� - ���� �������� ������ ���� ������ �� ����� */
    return NRES;
  end UTL_GEOGRAFY_FIND_BY_HIER_ITEM;
  
  /* �������� �������������� ���������� */
  procedure UTL_CHECK_DEVICEID
  (
    SDEVICEID               in varchar2                 -- ������������� ����������
  )
  is
    SLIC_DEVICEIDS          LICCTRLSPEC.SERIAL_NO%type; -- ������ ��������������� ��������� � ��������
  begin
    /* ������� �������������� ��������� �� �������� */
    begin
      select LS.SERIAL_NO
        into SLIC_DEVICEIDS
        from LICCTRL     L,
             LICCTRLSPEC LS
       where L.LICENSE_TYPE = 0
         and L.RN = LS.PRN
         and LS.APPLICATION = 'Account'
         and ROWNUM <= 1;
    exception
      when NO_DATA_FOUND then
        SLIC_DEVICEIDS := null;
    end;
    /* ���� � ������� �������� ��� ����������� �������������� */
    if (SLIC_DEVICEIDS like '%' || SDEVICEID || '%') then
      /* ������ �� ���� */
      P_EXCEPTION(0,
                  '������������� ����������� "%s" �� �������� � ��������.',
                  SDEVICEID);
    end if;
  end UTL_CHECK_DEVICEID;
  
  /* ��������� ��������� �������� ���� �� ��������� ������� ������ */
  procedure UTL_EXSQUEUE_MSG_GET_BODY_ROOT
  (
    NEXSQUEUE               in number,               -- ��������������� ����� �������������� ������� ������� ������
    XNODE_ROOT              out DBMS_XMLDOM.DOMNODE  -- �������� ������� ������ ����� ���� ���������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;        -- ������ ������� �������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XMLPARCER               DBMS_XMLPARSER.PARSER;   -- ������
    XENVELOPE               DBMS_XMLDOM.DOMNODE;     -- �������
    XBODY                   DBMS_XMLDOM.DOMNODE;     -- ���� ���������
    XNODELIST               DBMS_XMLDOM.DOMNODELIST; -- ����� ���� ���������
    CREQ                    clob;                    -- ����� ��� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������� ����� ������� */
    CREQ := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ������� ������� XML ������� */
    XMLPARCER := DBMS_XMLPARSER.NEWPARSER;
    /* ��������� XML �� ������� */
    DBMS_XMLPARSER.PARSECLOB(P => XMLPARCER, DOC => CREQ);
    /* ����� XML �������� �� ������������ */
    XDOC := DBMS_XMLPARSER.GETDOCUMENT(P => XMLPARCER);
    /* ��������� �������� ������� */
    XENVELOPE := DBMS_XMLDOM.MAKENODE(ELEM => DBMS_XMLDOM.GETDOCUMENTELEMENT(DOC => XDOC));
    /* ��������� ������� ���� */
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => STAG_BODY);
    /* ��������� �������� �������� ���� */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* ����� ������ �������� ������� */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
  end UTL_EXSQUEUE_MSG_GET_BODY_ROOT;
  
  /* ��������� ������ � ��������������� ������� ��������� �������������� */
  function UTL_ELINVOBJECT_DICPLACE_GET
  (
    NELINVOBJECT            in number,       -- ���. ����� ������ ��������� ��������������
    SRESULT_TYPE            in varchar2      -- ��� ���������� (��. ��������� SRESULT_TYPE*)
  ) return                  varchar2         -- �����-��� ��
  is
    SRES                    PKG_STD.TSTRING; -- ��������� ������
  begin
    /* ������ ������� �������� ��������� ��������������� */
    begin
      select DECODE(SRESULT_TYPE,
                    SRESULT_TYPE_MNEMO,
                    DECODE(T.INVPACK, null, O.PLACE_MNEMO, OP.PLACE_MNEMO),
                    SRESULT_TYPE_BARCODE,
                    DECODE(T.INVPACK, null, O.BARCODE, OP.BARCODE),
                    null)
        into SRES
        from ELINVOBJECT T,
             INVENTORY   I,
             DICPLACE    O,
             DICPLACE    OP,
             INVPACK     P
       where T.RN = NELINVOBJECT
         and T.INVENTORY = I.RN
         and I.OBJECT_PLACE = O.RN(+)
         and T.INVPACK = P.RN(+)
         and P.OBJECT_PLACE = OP.RN(+);
    exception
      when NO_DATA_FOUND then
        SRES := null;
    end;
    /* ����� ��������� */
    return SRES;
  end UTL_ELINVOBJECT_DICPLACE_GET;
  
  /* ��������� �����-���� ������� ��������� �������������� */
  function UTL_ELINVOBJECT_BARCODE_GET
  (
    NELINVOBJECT            in number        -- ���. ����� ������ ��������� ��������������
  ) return                  varchar2         -- �����-��� ��
  is
    SRES                    PKG_STD.TSTRING; -- ��������� ������
  begin
    /* ������� �����-��� ������� ��������� �������������� */
    begin
      select DECODE(PS.RN,
                    null,
                    DECODE(T.INVPACK, null, DECODE(T.INVSUBST, null, I.BARCODE, U.BARCODE), P.BARCODE),
                    PS.BARCODE)
        into SRES
        from ELINVOBJECT T,
             INVENTORY   I,
             INVPACK     P,
             INVPACKPOS  PS,
             INVSUBST    U
       where T.RN = NELINVOBJECT
         and T.INVENTORY = I.RN
         and T.INVPACK = P.RN(+)
         and T.INVPACK = PS.PRN(+)
         and T.INVSUBST = PS.INVSUBST(+)
         and T.INVSUBST = U.RN(+);
    exception
      when NO_DATA_FOUND then
        SRES := null;
    end;
    /* ����� ��������� */
    return SRES;
  end UTL_ELINVOBJECT_BARCODE_GET;

  /* ����������� �������������� - �������������� */
  procedure CHECKAUTH
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    XCHECKAUTHRESPONSE      DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XRESULT                 DBMS_XMLDOM.DOMNODE;     -- ��������� ��������������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* �.�. ���� �������� ��� ������� - ������ ���������� ������������� ����� */
      XCHECKAUTHRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CHECKAUTHRSPNS, SNS => SNS_TSD);
      XRESULT            := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_RESULT, SNS => SNS_TSD, SVAL => 'true');
      XNODE              := DBMS_XMLDOM.APPENDCHILD(N => XCHECKAUTHRESPONSE, NEWCHILD => XRESULT);
      /* ����������� ��� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XCHECKAUTHRESPONSE);
    exception
      /* ������������� ��������� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end CHECKAUTH;

  /* ����������� �������������� - ���������� ������������� */
  procedure GETUSERS
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    XGETUSERSRESPONSE       DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- ��� �������� ��������� ������
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- ����������� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETUSERSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETUSERSRSPNS, SNS => SNS_TSD);
      /* ������� �����������-���������������� */
      for REC in (select T.RN,
                         A.AGNABBR
                    from INVPERSONS T,
                         AGNLIST    A
                   where T.COMPANY = 136018
                     and T.AGNLIST = A.RN)
      loop
        /* �������� ���������� �� ���������� � ����� */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NAME, SNS => SNS_TSD, SVAL => REC.AGNABBR);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETUSERSRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETUSERSRESPONSE);
    exception
      /* ������������� ��������� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETUSERS;

  /* ����������� �������������� - ���������� ����� ���������� */
  procedure GETSHEETTYPES
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  ) 
  is
    XGETSHEETTYPESRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- ��� �������� ��������� ������
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- ����������� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETSHEETTYPESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETTYPESRSPNS, SNS => SNS_TSD);
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
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.RN);
        XNAME := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NAME, SNS => SNS_TSD, SVAL => REC.DOCCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XCODE);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XNAME);
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETTYPESRESPONSE, NEWCHILD => XITEM);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETTYPESRESPONSE);
    exception
      /* ������������� ��������� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETTYPES;
  
  /* ����������� �������������� - ���������� ���������� ���������� �������������� */
  procedure GETSHEETS
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
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
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQ_TYPECODE           PKG_STD.TREF;            -- ��� ��������� �� ������� (�������� ������)
    SREQ_PREFIX             PKG_STD.TSTRING;         -- ������� ��������� �� ������� (�������� ������)
    SREQ_NUMBER             PKG_STD.TSTRING;         -- ����� ��������� �� ������� (�������� ������)
    DREQ_DATE               PKG_STD.TLDATE;          -- ���� ��������� �� ������� (�������� ������)
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��� ���������" (�������� ������) */
      NREQ_TYPECODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_TYPECODE));
      /* ��������� "�������" (�������� ������) */
      SREQ_PREFIX := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_PREFIX);
      /* ��������� "�����" (�������� ������) */
      SREQ_NUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_NUMBER);
      /* ��������� "����" (�������� ������) */
      DREQ_DATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DATE), 'YYYY-MM-DD');
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETSHEETSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETSRSPNS, SNS => SNS_TSD);
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
                     and (NREQ_TYPECODE is null or (NREQ_TYPECODE is not null and T.DOC_TYPE = NREQ_TYPECODE))
                     and (SREQ_PREFIX is null or (SREQ_PREFIX is not null and trim(T.DOC_PREF) = SREQ_PREFIX))
                     and (SREQ_NUMBER is null or (SREQ_NUMBER is not null and trim(T.DOC_NUMB) = SREQ_NUMBER))
                     and (DREQ_DATE is null or (DREQ_DATE is not null and T.DOC_DATE = DREQ_DATE)))
      loop
        /* �������� ���������� �� ��������� � ����� */
        XITEM     := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE     := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.RN);
        XNAME     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => STAG_NAME,
                                    SNS  => SNS_TSD,
                                    SVAL => REC.DOC_TYPE_CODE || ', ' || REC.DOC_PREF || '-' || REC.DOC_NUMB || ', ' ||
                                            TO_CHAR(REC.DOC_DATE, 'dd.mm.yyyy'));
        XTYPECODE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_TYPECODE, SNS => SNS_TSD, SVAL => REC.DOC_TYPE);
        XPREFIX   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_PREFIX, SNS => SNS_TSD, SVAL => REC.DOC_PREF);
        XNUMBER   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NUMBER, SNS => SNS_TSD, SVAL => REC.DOC_NUMB);
        XDATE     := UTL_CREATENODE(XDOC => XDOC,
                                    STAG => STAG_DATE,
                                    SNS  => SNS_TSD,
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
    exception
      /* ������������� ��������� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETS;
  
  /* ����������� �������������� - ���������� ������� ���������� �������������� */
  procedure GETSHEETITEMS
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    XGETSHEETITEMSRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XSTORAGEMNEMOCODE       DBMS_XMLDOM.DOMNODE;     -- �������� ��������������� ��� �������� ��������� ������
    XUSERCODE               DBMS_XMLDOM.DOMNODE;     -- ��� ��� �������� ��������� ������
    XITEMCODE               DBMS_XMLDOM.DOMNODE;     -- ������������� �� ��� �������� ��������� ������
    XITEMNAME               DBMS_XMLDOM.DOMNODE;     -- ������������ �� ��� �������� ��������� ������
    XITEMMNEMOCODE          DBMS_XMLDOM.DOMNODE;     -- ��� �� ��� �������� ��������� ������
    XITEMNUMBER             DBMS_XMLDOM.DOMNODE;     -- ����� �� ��� �������� ��������� ������
    XQUANTITY               DBMS_XMLDOM.DOMNODE;     -- ���������� �� ��� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQ_SHEET_CODE         PKG_STD.TREF;            -- ��������� �� ������� (�������� ������)
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��������������� ����� ���������" (�������� ������) */
      NREQ_SHEET_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETSHEETITEMSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETITEMSRSPNS, SNS => SNS_TSD);
      /* ������� ���� ���������� ��������� � �������� "����������� ��������������" */
      for REC in (select T.RN NRN,
                         T.COMPANY NCOMPANY,
                         T.BARCODE SBARCODE,
                         T.IS_LOADED NIS_LOADED,
                         UTL_ELINVOBJECT_DICPLACE_GET(T.RN, SRESULT_TYPE_MNEMO) SSTORAGEMNEMOCODE,
                         UTL_ELINVOBJECT_DICPLACE_GET(T.RN, SRESULT_TYPE_BARCODE) SOBARCODE,
                         T.INVPERSONS NINVPERSONS,
                         UTL_ELINVOBJECT_BARCODE_GET(T.RN) SIBARCODE,
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
                     and T.PRN = NREQ_SHEET_CODE
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
        XITEM             := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XSTORAGEMNEMOCODE := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_STORAGEMNEMOCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => REC.SSTORAGEMNEMOCODE);
        XUSERCODE         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_USERCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.NINVPERSONS));
        XITEMCODE         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SIBARCODE));
        XITEMNAME         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMNAME,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SNOM_NAME));
        XITEMMNEMOCODE    := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMMNEMOCODE,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SNOM_CODE));
        XITEMNUMBER       := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_ITEMNUMBER,
                                            SNS  => SNS_TSD,
                                            SVAL => trim(REC.SINV_NUMBER));
        XQUANTITY         := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_QUANTITY, SNS => SNS_TSD, SVAL => REC.SQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XSTORAGEMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XUSERCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNAME);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMMNEMOCODE);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XITEMNUMBER);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XITEM, NEWCHILD => XQUANTITY);
        XNODE             := DBMS_XMLDOM.APPENDCHILD(N => XGETSHEETITEMSRESPONSE, NEWCHILD => XITEM);
        /* �������� ���� �������� � �������� ��� ������� ��������� �������������� */
        P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => REC.NCOMPANY,
                                  NRN          => REC.NRN,
                                  DUNLOAD_DATE => sysdate,
                                  DINV_DATE    => null,
                                  NINVPERSONS  => REC.NINVPERSONS,
                                  SBARCODE     => REC.SBARCODE,
                                  NIS_LOADED   => REC.NIS_LOADED);
      end loop;
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XGETSHEETITEMSRESPONSE);
    exception
      /* ������������� ��������� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSHEETITEMS;
  
  /* ����������� �������������� - ���������� ��������������� */
  procedure GETSTORAGES
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    XGETSTORAGESRESPONSE    DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XCODE                   DBMS_XMLDOM.DOMNODE;     -- ��� �������� ��������� ������
    XNAME                   DBMS_XMLDOM.DOMNODE;     -- ����������� �������� ��������� ������
    XMNEMOCODE              DBMS_XMLDOM.DOMNODE;     -- �������� ��������������� ��� �������� ��������� ������
    XLATITUDE               DBMS_XMLDOM.DOMNODE;     -- ������ ��������������� ��� �������� ��������� ������
    XLONGITUDE              DBMS_XMLDOM.DOMNODE;     -- ������� ��������������� ��� �������� ��������� ������
    XPOSTCODE               DBMS_XMLDOM.DOMNODE;     -- �������� ������ ��������������� ��� �������� ��������� ������
    XCOUNTRY                DBMS_XMLDOM.DOMNODE;     -- ������ ��������������� ��� �������� ��������� ������
    XREGION                 DBMS_XMLDOM.DOMNODE;     -- ������ ��������������� ��� �������� ��������� ������
    XLOCALITY               DBMS_XMLDOM.DOMNODE;     -- ��������� ����� ��������������� ��� �������� ��������� ������
    XSTREET                 DBMS_XMLDOM.DOMNODE;     -- ����� ��������������� ��� �������� ��������� ������
    XHOUSENUMBER            DBMS_XMLDOM.DOMNODE;     -- ����� ���� ��������������� ��� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQ_SHEET_CODE         PKG_STD.TREF;            -- ��������� �� ������� (�������� ������)
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��������������� ����� ���������" (�������� ������) */
      NREQ_SHEET_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETSTORAGESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSTORAGESRSPNS, SNS => SNS_TSD);
      /* ������� ��������������� */
      for REC in (select T.RN NRN,
                         T.PLACE_MNEMO SMNEMOCODE,
                         T.PLACE_NAME SNAME,
                         UDO_F_GET_DOC_PROP_VAL_STR('LATITUDE', 'ObjPlace', T.RN) SLATITUDE,
                         UDO_F_GET_DOC_PROP_VAL_STR('LONGITUDE', 'ObjPlace', T.RN) SLONGITUDE,
                         NVL(T.ADDR_POST, G.POSTAL_CODE) SPOSTCODE,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 1) SCOUNTRY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2) SREGION,
                         NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 8),
                             NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 4),
                                 NVL(UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 3), UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 2)))) SLOCALITY,
                         UTL_GEOGRAFY_GET_HIER_ITEM(G.RN, 5) SSTREET,
                         T.ADDR_HOUSE SHOUSENUMBER,
                         T.BARCODE SBARCODE
                    from DICPLACE T,
                         GEOGRAFY G
                   where T.COMPANY = 136018
                     and T.GEOGRAFY = G.RN(+)
                     and ((NREQ_SHEET_CODE is null) or
                         ((NREQ_SHEET_CODE is not null) and
                         (T.RN in (select DECODE(EO.INVPACK, null, INV.OBJECT_PLACE, P.OBJECT_PLACE)
                                       from ELINVOBJECT EO,
                                            INVENTORY   INV,
                                            INVPACK     P
                                      where EO.PRN = NREQ_SHEET_CODE
                                        and EO.INVENTORY = INV.RN
                                        and EO.INVPACK = P.RN(+))))))
      loop
        /* �������� ���������� �� ��������������� � ����� */
        XITEM        := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_ITEM, SNS => SNS_TSD);
        XCODE        := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_CODE, SNS => SNS_TSD, SVAL => REC.SBARCODE);
        XNAME        := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_NAME, SNS => SNS_TSD, SVAL => REC.SNAME);
        XMNEMOCODE   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_MNEMOCODE, SNS => SNS_TSD, SVAL => REC.SMNEMOCODE);
        XLATITUDE    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_LATITUDE, SNS => SNS_TSD, SVAL => REC.SLATITUDE);
        XLONGITUDE   := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_LONGITUDE, SNS => SNS_TSD, SVAL => REC.SLONGITUDE);
        XPOSTCODE    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_POSTCODE, SNS => SNS_TSD, SVAL => REC.SPOSTCODE);
        XCOUNTRY     := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_COUNTRY, SNS => SNS_TSD, SVAL => REC.SCOUNTRY);
        XREGION      := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_REGION, SNS => SNS_TSD, SVAL => REC.SREGION);
        XLOCALITY    := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_LOCALITY, SNS => SNS_TSD, SVAL => REC.SLOCALITY);
        XSTREET      := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_STREET, SNS => SNS_TSD, SVAL => REC.SSTREET);
        XHOUSENUMBER := UTL_CREATENODE(XDOC => XDOC,
                                       STAG => STAG_HOUSENUMBER,
                                       SNS  => SNS_TSD,
                                       SVAL => REC.SHOUSENUMBER);
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
    exception
      /* ������������� ��������� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end GETSTORAGES;

  /* ����������� �������������� - ���������� ����������� �������������� �������� �������� */
  procedure SAVESHEETITEM
  (
    NIDENT                  in number,               -- ������������� ��������
    NEXSQUEUE               in number                -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    XSAVESHEETITEMRESPONSE  DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������
    XNODE                   DBMS_XMLDOM.DOMNODE;     -- ����� ��� ����� ������
    XITEM                   DBMS_XMLDOM.DOMNODE;     -- ������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQ_DEVICEID           PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQ_SHEET_CODE         PKG_STD.TREF;            -- ��������� �� ������� (�������� ����������)
    NREQ_USER_CODE          PKG_STD.TREF;            -- ��������������� ����� ��� �� ������� (�������� ����������)
    SREQ_STORAGE_MNEMOCODE  PKG_STD.TSTRING;         -- �������� ��������������� �� ������� (�������� ����������)
    NREQ_STORAGE_ISNEW      PKG_STD.TNUMBER;         -- ������� ������ ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_CODE       PKG_STD.TSTRING;         -- �����-��� ��������������� �� ������� (�������� ����������)
    SREQ_STORAGE_NAME       PKG_STD.TSTRING;         -- ������������ ��������������� �� ������� (�������� ����������)
    SREQ_STORAGE_POSTCODE   PKG_STD.TSTRING;         -- �������� ������ ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_COUNTRY    PKG_STD.TSTRING;         -- ������ ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_REGION     PKG_STD.TSTRING;         -- ������ ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_LOCALITY   PKG_STD.TSTRING;         -- ���������� ����� ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_STREET     PKG_STD.TSTRING;         -- ����� ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_HOUSE      PKG_STD.TSTRING;         -- ����� ���� ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_LATITUDE   PKG_STD.TSTRING;         -- ������ ��������������� �� ������� (�������� ����������)    
    SREQ_STORAGE_LONGITUDE  PKG_STD.TSTRING;         -- ������� ��������������� �� ������� (�������� ����������) 
    SREQ_ITEM_CODE          PKG_STD.TSTRING;         -- �����-��� �� �� ������� (�������� ����������)  
    SREQ_ITEM_NAME          PKG_STD.TSTRING;         -- ������������ ������������ �� �� ������� (�������� ����������)
    SREQ_ITEM_MNEMOCODE     PKG_STD.TSTRING;         -- �������� ������������ �� �� ������� (�������� ����������)
    SREQ_ITEM_NUMBER        PKG_STD.TSTRING;         -- ����������� ����� �� �� ������� (�������� ����������)
    NREQ_ITEM_QUANTITY      PKG_STD.TQUANT;          -- ���������� �� �� ������� (�������� ����������)    
    DREQ_ITEM_CHECKDATE     PKG_STD.TLDATE;          -- ���� ���������� �������������� �� �� ������� (�������� ����������)  
    SREQ_ITEM_COMMENT       PKG_STD.TLSTRING;        -- ����������� ��� �� �� ������� (�������� ����������)
    SREQ_ITEM_LATITUDE      PKG_STD.TSTRING;         -- ������ �� �� ������� (�������� ����������) 
    SREQ_ITEM_LONGITUDE     PKG_STD.TSTRING;         -- ������� �� �� ������� (�������� ����������)    
    NREQ_ITEM_DISTANCE      PKG_STD.TLNUMBER;        -- ���������� �� ��������������� �� �� ������� (�������� ����������)    
    RELINVENTORY            ELINVENTORY%rowtype;     -- ������ �������������� ��������� ��������������
    NELINVOBJECT            PKG_STD.TREF;            -- ���. ����� ������� ��������� ��������������
    SDICPLACE_BARCODE       PKG_STD.TSTRING;         -- �����-��� ��������������� �� (��� ������� ��������� ��������������)
    SERR_ELINVOBJECT        PKG_STD.TSTRING;         -- ����� ��� ������ ��������� ����������� ��������
    SERR_DICPLACE           PKG_STD.TSTRING;         -- ����� ��� ������ ��������� ���������������

    /* ����� ��������������� ������� �� ���������� */
    function FIND_GEOGRAFY
    (
      NCOMPANY              in number,    -- ���. ����� �����������
      SADDR_COUNTRY         in varchar2,  -- ������ ���������������
      SADDR_REGION          in varchar2,  -- ������ ���������������
      SADDR_LOCALITY        in varchar2,  -- ��������� ����� ���������������
      SADDR_STREET          in varchar2   -- ����� ���������������
    ) return                number        -- �������������� �������
    is
    begin
      return UTL_GEOGRAFY_FIND_BY_HIER_ITEM(NCOMPANY       => NCOMPANY,
                                            SADDR_COUNTRY  => SADDR_COUNTRY,
                                            SADDR_REGION   => SADDR_REGION,
                                            SADDR_LOCALITY => SADDR_LOCALITY,
                                            SADDR_STREET   => SADDR_STREET);
    end FIND_GEOGRAFY;
    
    /* ��������� ��������������� - ����� � ��� ������������� ���������� ��������������� �� */
    procedure PROCESS_DICPLACE
    (
      NCOMPANY              in number,    -- ���. ����� �����������
      NIS_NEW               in number,    -- ������� ������ �������������� (0 - ������, 1 - �����)
      SMNEMO                in varchar2,  -- �������� ���������������
      SNAME                 in varchar2,  -- ������������ ���������������
      SBARCODE              in varchar2,  -- ������-��� ���������������
      SADDR_POSTCODE        in varchar2,  -- �������� ������ ���������������
      SADDR_COUNTRY         in varchar2,  -- ������ ���������������
      SADDR_REGION          in varchar2,  -- ������ ���������������
      SADDR_LOCALITY        in varchar2,  -- ��������� ����� ���������������
      SADDR_STREET          in varchar2,  -- ����� ���������������
      SADDR_HOUSE           in varchar2,  -- ��� ���������������
      SLATITUDE             in varchar2,  -- ������ ���������������
      SLONGITUDE            in varchar2,  -- ������� ���������������
      SDICPLACE_BARCODE     out varchar2  -- �������� ������������� ����������������
    )
    is
      NPROP_LATITUDE        PKG_STD.TREF; -- ���. ����� �� ��� �������� ������ ���������������
      NPROP_LONGITUDE       PKG_STD.TREF; -- ���. ����� �� ��� �������� ������� ���������������      
      NDICPLACE             PKG_STD.TREF; -- ���. ����� ���������������
      NDICPLACE_CRN         PKG_STD.TREF; -- ���. ����� �������� ���������������
      NTMP                  PKG_STD.TREF; -- ����� ��� ���. �������      
    begin
      /* �������������� �� ��� �������� ������ */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0, NCOMPANY => NCOMPANY, SCODE => 'LATITUDE', NRN => NPROP_LATITUDE);
      /* �������������� �� ��� �������� ������� */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0, NCOMPANY => NCOMPANY, SCODE => 'LONGITUDE', NRN => NPROP_LONGITUDE);
      /* ��������� ������� ��������������� �� ����������� ��������� */
      begin
        select T.RN
          into NDICPLACE
          from DICPLACE T
         where T.COMPANY = NCOMPANY
           and T.BARCODE = SBARCODE;
      exception
        when NO_DATA_FOUND then
          /* ������� ����� �� ��������� */
          begin
            select T.RN
              into NDICPLACE
              from DICPLACE T
             where T.COMPANY = NCOMPANY
               and T.PLACE_MNEMO = SMNEMO;
          exception
            when NO_DATA_FOUND then
              /* �����, �� ���� ��� ����� - ��������� */
              if (NIS_NEW = 1) then
                /* ��������� ������� ���������� */
                FIND_ROOT_CATALOG(NCOMPANY => NCOMPANY, SCODE => 'ObjPlace', NCRN => NDICPLACE_CRN);
                /* ������� ������ */
                P_DICPLACE_BASE_INSERT(NCOMPANY        => NCOMPANY,
                                       NCRN            => NDICPLACE_CRN,
                                       SMNEMO          => SMNEMO,
                                       SNAME           => SNAME,
                                       SBARCODE        => NVL(SBARCODE, GEN_BARCODE_EX()),
                                       DLABEL_DATE     => sysdate,
                                       SCAD_NUMB       => null,
                                       NGEOGRAFY       => null,
                                       SADDR_HOUSE     => SADDR_HOUSE,
                                       SADDR_BLOCK     => null,
                                       SADDR_BUILDING  => null,
                                       SADDR_FLAT      => null,
                                       SADDR_POST      => SADDR_POSTCODE,
                                       SPLACE_DESCRIPT => SADDR_COUNTRY || '/' || SADDR_REGION || '/' || SADDR_LOCALITY || '/' ||
                                                          SADDR_STREET,
                                       SAOID           => null,
                                       SAOGUID         => null,
                                       SHOUSEID        => null,
                                       SHOUSEGUID      => null,
                                       NRN             => NDICPLACE);
              else
                P_EXCEPTION(0,
                            '��������������� ����������� �������� � �����-����� "%s" ��� ���������� "%s" �� �������.',
                            NVL(SBARCODE, '<�� ������>'),
                            NVL(SMNEMO, '<�� �������>'));
              end if;
          end;
        when TOO_MANY_ROWS then
          P_EXCEPTION(0,
                      '��������������� ����������� �������� � �����-����� "%s" ���������� ������������.',
                      SBARCODE);
      end;
      /* �������� ��� ����� ��������������� */
      if (NDICPLACE is null) then
        P_EXCEPTION(0,
                    '�� ������� ���������� ����������� ��������������� �� ��������� "%s" � ��������� "%s".',
                    NVL(SBARCODE, '<�� ������>'),
                    NVL(SMNEMO, '<�� ������>'));
      end if;
      /* ������������� ��� */
      for C in (select T.* from DICPLACE T where T.RN = NDICPLACE)
      loop
        /* �������� ���� �����-���� */
        if (NVL(SBARCODE, C.BARCODE) is not null) then
          if (SBARCODE = C.BARCODE) then
            C.LABEL_DATE := NVL(C.LABEL_DATE, sysdate);
          else
            C.LABEL_DATE := sysdate;
          end if;
        else
          C.LABEL_DATE := null;
        end if;
        /* ������������� ������ */
        P_DICPLACE_BASE_UPDATE(NCOMPANY        => C.COMPANY,
                               NRN             => C.RN,
                               SMNEMO          => NVL(SMNEMO, C.PLACE_MNEMO),
                               SNAME           => NVL(SNAME, C.PLACE_NAME),
                               SBARCODE        => NVL(SBARCODE, C.BARCODE),
                               DLABEL_DATE     => C.LABEL_DATE,
                               SCAD_NUMB       => C.CAD_NUMB,
                               NGEOGRAFY       => NVL(FIND_GEOGRAFY(NCOMPANY       => C.COMPANY,
                                                                    SADDR_COUNTRY  => SADDR_COUNTRY,
                                                                    SADDR_REGION   => SADDR_REGION,
                                                                    SADDR_LOCALITY => SADDR_LOCALITY,
                                                                    SADDR_STREET   => SADDR_STREET),
                                                      C.GEOGRAFY),
                               SADDR_HOUSE     => SADDR_HOUSE,
                               SADDR_BLOCK     => C.ADDR_BLOCK,
                               SADDR_BUILDING  => C.ADDR_BUILDING,
                               SADDR_FLAT      => C.ADDR_FLAT,
                               SADDR_POST      => SADDR_POSTCODE,
                               SPLACE_DESCRIPT => C.PLACE_DESCRIPT,
                               SAOID           => null,
                               SAOGUID         => null,
                               SHOUSEID        => null,
                               SHOUSEGUID      => null);
        /* �������� �� � ������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ObjPlace',
                                      NPROPERTY   => NPROP_LATITUDE,
                                      SSTR_VALUE  => SLATITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* �������� �� � �������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ObjPlace',
                                      NPROPERTY   => NPROP_LONGITUDE,
                                      SSTR_VALUE  => SLONGITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
      end loop;
      /* ��������� ��������� �����-��� ��������������� */
      begin
        select T.BARCODE into SDICPLACE_BARCODE from DICPLACE T where T.RN = NDICPLACE;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NDICPLACE, SUNIT_TABLE => 'DICPLACE');
      end;
    end PROCESS_DICPLACE;
    
    /* ������������ �� - ����� � ��� ������������� ���������� ������� ��������� �������������� � ������������� �� */
    procedure PROCESS_INVENTORY
    (
      RELINVENTORY          in ELINVENTORY%rowtype, -- ������ �������������� ���������
      SBARCODE              in varchar2,            -- �����-��� ��
      SINV_NUMBER           in varchar2,            -- ����������� ����� ��
      NELINVOBJECT          out number              -- ���. ����� ������� ��������� ��������������
    )
    is
      NINVENTORY            PKG_STD.TREF;           -- ���. ����� �� (�������� "����������� ���������")    
    begin
      /* ���� ������� ��������� �� �����-���� �� */
      begin
        select T.RN
          into NELINVOBJECT
          from ELINVOBJECT T
         where T.COMPANY = RELINVENTORY.COMPANY
           and T.PRN = RELINVENTORY.RN
           and UTL_ELINVOBJECT_BARCODE_GET(T.RN) = SBARCODE;
      exception
        when NO_DATA_FOUND then
          /* �� ����� ������� ��������� �������������� */
          begin
            /* ���� ���. ����� �� �� �����-���� */
            select T.RN
              into NINVENTORY
              from INVENTORY T
             where T.BARCODE = SBARCODE
               and T.COMPANY = RELINVENTORY.COMPANY;
            /* ��������� � � ��������� �������������� */
            P_ELINVOBJECT_BASE_INSERT(NCOMPANY     => RELINVENTORY.COMPANY,
                                      NPRN         => RELINVENTORY.RN,
                                      NINVENTORY   => NINVENTORY,
                                      NINVSUBST    => null,
                                      NINVPACK     => null,
                                      DUNLOAD_DATE => null,
                                      DINV_DATE    => null,
                                      NINVPERSONS  => null,
                                      SBARCODE     => null,
                                      NIS_LOADED   => 1,
                                      NRN          => NELINVOBJECT);
          exception
            when NO_DATA_FOUND then
              begin
                /* ���� ���. ����� �� �� ������������ ������ */
                select T.RN
                  into NINVENTORY
                  from INVENTORY T
                 where trim(T.INV_NUMBER) = trim(SINV_NUMBER)
                   and T.COMPANY = RELINVENTORY.COMPANY;
                /* ��������� � � ��������� �������������� */
                P_ELINVOBJECT_BASE_INSERT(NCOMPANY     => RELINVENTORY.COMPANY,
                                          NPRN         => RELINVENTORY.RN,
                                          NINVENTORY   => NINVENTORY,
                                          NINVSUBST    => null,
                                          NINVPACK     => null,
                                          DUNLOAD_DATE => null,
                                          DINV_DATE    => null,
                                          NINVPERSONS  => null,
                                          SBARCODE     => null,
                                          NIS_LOADED   => 1,
                                          NRN          => NELINVOBJECT);
              exception
                when NO_DATA_FOUND then
                  P_EXCEPTION(0,
                              '����������� �������� � �����-����� "%s" �� �������.',
                              SBARCODE);
              end;
          end;
      end;
    end PROCESS_INVENTORY;
    
    /* ������������ ������� ��������� */
    procedure PROCESS_ELINVOBJECT
    (
      RELINVENTORY          in ELINVENTORY%rowtype, -- ������ �������������� ���������
      NELINVOBJECT          in number,              -- ���. ����� �������� ��������� ��������������
      NINVPERSONS           in number,              -- ���. ����� ������������������ ����
      DINV_DATE             in date,                -- ���� ���������� ��������������
      SBARCODE              in varchar2,            -- �����-��� ���������������
      SITEM_COMMENT         in varchar2,            -- ����������� ������������������ ����
      NITEM_DISTANCE        in number,              -- ���������� �� �� ���������������
      SITEM_LATITUDE        in varchar2,            -- ������ ��
      SITEM_LONGITUDE       in varchar2,            -- ������� ��
      NITEM_QUANTITY        in number               -- ���������� ��
    )
    is
      NPROP_COMMENT         PKG_STD.TREF;           -- ���. ����� �� ��� �������� �����������
      NPROP_DISTANCE        PKG_STD.TREF;           -- ���. ����� �� ��� �������� ���������� �� ��������������� (������)
      NPROP_LATITUDE        PKG_STD.TREF;           -- ���. ����� �� ��� �������� ������
      NPROP_LONGITUDE       PKG_STD.TREF;           -- ���. ����� �� ��� �������� �������
      NPROP_QUANTITY        PKG_STD.TREF;           -- ���. ����� �� ��� �������� ����������
      NTMP                  PKG_STD.TREF;           -- ����� ��� ���. �������
    begin
      /* �������������� �� ��� �������� ���������� */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'COMMENT',
                           NRN         => NPROP_COMMENT);
      /* �������������� �� ��� �������� ���������� �� ��������������� */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'DISTANCE',
                           NRN         => NPROP_DISTANCE);
      /* �������������� �� ��� �������� ������ */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'LATITUDE',
                           NRN         => NPROP_LATITUDE);
      /* �������������� �� ��� �������� ������� */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'LONGITUDE',
                           NRN         => NPROP_LONGITUDE);
      /* �������������� �� ��� �������� ���������� */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0,
                           NCOMPANY    => RELINVENTORY.COMPANY,
                           SCODE       => 'QUANTITY',
                           NRN         => NPROP_QUANTITY);
      /* ��������� � �������������� ������� ��������� �������������� */
      for C in (select T.* from ELINVOBJECT T where T.RN = NELINVOBJECT)
      loop
        /* ������� ������� ��������� �������������� */        
        P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => C.COMPANY,
                                  NRN          => C.RN,
                                  DUNLOAD_DATE => C.UNLOAD_DATE,
                                  DINV_DATE    => DINV_DATE,
                                  NINVPERSONS  => NINVPERSONS,
                                  SBARCODE     => SBARCODE,
                                  NIS_LOADED   => C.IS_LOADED);
        /* �������� �� � ����������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_COMMENT,
                                      SSTR_VALUE  => SITEM_COMMENT,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* �������� �� � ���������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_DISTANCE,
                                      SSTR_VALUE  => null,
                                      NNUM_VALUE  => NITEM_DISTANCE,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* �������� �� � ������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_LATITUDE,
                                      SSTR_VALUE  => SITEM_LATITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* �������� �� � �������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_LONGITUDE,
                                      SSTR_VALUE  => SITEM_LONGITUDE,
                                      NNUM_VALUE  => null,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
        /* �������� �� � ����������� */
        P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                      SUNITCODE   => 'ElectronicInventoriesObjects',
                                      NPROPERTY   => NPROP_QUANTITY,
                                      SSTR_VALUE  => null,
                                      NNUM_VALUE  => NITEM_QUANTITY,
                                      DDATE_VALUE => null,
                                      NRN         => NTMP);
      end loop;
    end PROCESS_ELINVOBJECT;

  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQ_DEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��������������� ����� ���������" (�������� ����������) */
      NREQ_SHEET_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* ��������� "��������������� ����� ���" (�������� ����������) */
      NREQ_USER_CODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_USERCODE));
      /* ��������� "�������� ���������������" (�������� ����������) */
      SREQ_STORAGE_MNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEMNEMOCODE);
      /* ��������� "������� ������ ���������������" (�������� ����������) */
      NREQ_STORAGE_ISNEW := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEISNEW));
      /* ��������� "�����-��� ���������������" (�������� ����������) */
      SREQ_STORAGE_CODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECODE);
      /* ��������� "������������ ���������������" (�������� ����������) */
      SREQ_STORAGE_NAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGENAME);
      /* ��������� "�������� ������ ���������������" (�������� ����������) */
      SREQ_STORAGE_POSTCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEPOSTCODE);
      /* ��������� "������ ���������������" (�������� ����������) */
      SREQ_STORAGE_COUNTRY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECOUNTRY);
      /* ��������� "������ ���������������" (�������� ����������) */
      SREQ_STORAGE_REGION := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEREGION);
      /* ��������� "���������� ����� ���������������" (�������� ����������) */
      SREQ_STORAGE_LOCALITY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELOCALITY);
      /* ��������� "����� ���������������" (�������� ����������) */
      SREQ_STORAGE_STREET := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGESTREET);
      /* ��������� "����� ���� ���������������" (�������� ����������) */
      SREQ_STORAGE_HOUSE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEHOUSENUMBER);
      /* ��������� "������ ���������������" (�������� ����������) */
      SREQ_STORAGE_LATITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELATITUDE);
      /* ��������� "������� ���������������" (�������� ����������) */
      SREQ_STORAGE_LONGITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELONGITUDE);
      /* ��������� "�����-��� ��" (�������� ����������) */
      SREQ_ITEM_CODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMCODE);
      /* ��������� "������������ ������������ ��" (�������� ����������) */
      SREQ_ITEM_NAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNAME);
      /* ��������� "�������� ������������ ��" (�������� ����������) */
      SREQ_ITEM_MNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMMNEMOCODE);
      /* ��������� "����������� ����� ��" (�������� ����������) */
      SREQ_ITEM_NUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNUMBER);
      /* ��������� "���������� ��" (�������� ����������) */
      NREQ_ITEM_QUANTITY := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_QUANTITY));
      /* ��������� "���� ���������� �������������� ��" (�������� ����������) */
      DREQ_ITEM_CHECKDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_CHECKDATE),
                                     'YYYY-MM-DD"T"HH24:MI:SS');
      /* ��������� "����������� ��� ��" (�������� ����������) */
      SREQ_ITEM_COMMENT := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_COMMENT);
      /* ��������� "������ ��" (�������� ����������) */
      SREQ_ITEM_LATITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LATITUDE);
      /* ��������� "������� ��" (�������� ����������) */
      SREQ_ITEM_LONGITUDE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LONGITUDE);
      /* ��������� "���������� �� ��������������� ��" (�������� ����������) */
      NREQ_ITEM_DISTANCE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DISTANCETOSTORAGE));
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQ_DEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* �������� ������ ���� ������ ��������������� ����� ��������� */
      if (NREQ_SHEET_CODE is not null) then
        /* ������� ������ ��������� �������������� */
        begin
          select T.* into RELINVENTORY from ELINVENTORY T where T.RN = NREQ_SHEET_CODE;
        exception
          when NO_DATA_FOUND then
            PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NREQ_SHEET_CODE, SUNIT_TABLE => 'ELINVENTORY');
        end;
        /* ������������ ��������������� */
        begin
          PROCESS_DICPLACE(NCOMPANY          => RELINVENTORY.COMPANY,
                           NIS_NEW           => NREQ_STORAGE_ISNEW,
                           SMNEMO            => SREQ_STORAGE_MNEMOCODE,
                           SNAME             => SREQ_STORAGE_NAME,
                           SBARCODE          => SREQ_STORAGE_CODE,
                           SADDR_POSTCODE    => SREQ_STORAGE_POSTCODE,
                           SADDR_COUNTRY     => SREQ_STORAGE_COUNTRY,
                           SADDR_REGION      => SREQ_STORAGE_REGION,
                           SADDR_LOCALITY    => SREQ_STORAGE_LOCALITY,
                           SADDR_STREET      => SREQ_STORAGE_STREET,
                           SADDR_HOUSE       => SREQ_STORAGE_HOUSE,
                           SLATITUDE         => SREQ_STORAGE_LATITUDE,
                           SLONGITUDE        => SREQ_STORAGE_LONGITUDE,
                           SDICPLACE_BARCODE => SDICPLACE_BARCODE);
        exception
          when others then
            SERR_DICPLACE := sqlerrm;
        end;
        /* ���� �������������� ���������� ������� */
        if (SERR_DICPLACE is null) then
          begin
            /* ������������ �� */
            PROCESS_INVENTORY(RELINVENTORY => RELINVENTORY,
                              SBARCODE     => SREQ_ITEM_CODE,
                              SINV_NUMBER  => SREQ_ITEM_NUMBER,
                              NELINVOBJECT => NELINVOBJECT);
            /* ������������ ������� ��������� */
            PROCESS_ELINVOBJECT(RELINVENTORY    => RELINVENTORY,
                                NELINVOBJECT    => NELINVOBJECT,
                                NINVPERSONS     => NREQ_USER_CODE,
                                DINV_DATE       => DREQ_ITEM_CHECKDATE,
                                SBARCODE        => SDICPLACE_BARCODE,
                                SITEM_COMMENT   => SREQ_ITEM_COMMENT,
                                NITEM_DISTANCE  => NREQ_ITEM_DISTANCE,
                                SITEM_LATITUDE  => SREQ_ITEM_LATITUDE,
                                SITEM_LONGITUDE => SREQ_ITEM_LONGITUDE,
                                NITEM_QUANTITY  => NREQ_ITEM_QUANTITY);
          exception
            when others then
              SERR_ELINVOBJECT := sqlerrm;
          end;
        else
          SERR_ELINVOBJECT := '�������� ������ ��� ��������� ����� ��������';
        end if;
      else
        P_EXCEPTION(0, '� ������� �� ������ ������������� ���������.');
      end if;
      /* ���� ������ ��� - ���������� ������������� ����� */
      if ((SERR_ELINVOBJECT is null) and (SERR_DICPLACE is null)) then
        /* ������ ������������ ��� ��� ������ */
        XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_SAVESHEETITEMRSPNS, SNS => SNS_TSD);
        /* ��������� ��������� */
        XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_RESULT, SNS => SNS_TSD, SVAL => 'true');
        XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
        /* ����������� ����� � ������� */
        CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
      else
        /* ���� ������ - ����� �� */
        CRESPONSE := UTL_CREATEERRORRESPONSE_SSITEM(SMSG_ELINVOBJECT => UTL_CORRECT_ERR(SERR => SERR_ELINVOBJECT),
                                                    SMSG_DICPLACE    => UTL_CORRECT_ERR(SERR => SERR_DICPLACE));
      end if;
    exception
      /* ������������� ��������� �������������� ����� ������ */
      when others then
        CRESPONSE := UTL_CREATEERRORRESPONSE(SMSG => UTL_CORRECT_ERR(SERR => sqlerrm));
    end;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT  => NIDENT,
                                SRESULT => PKG_EXS.SPRC_RESP_RESULT_OK,
                                BRESP   => CLOB2BLOB(LCDATA => CRESPONSE, SCHARSET => 'UTF8'));
  exception
    when others then
      /* ����� ������ - ��� ��������� */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end SAVESHEETITEM;
  
end;
/
