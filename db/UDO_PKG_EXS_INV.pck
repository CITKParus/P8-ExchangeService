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
  STAG_FLOOR                constant varchar2(40) := 'Floor';
  STAG_ROOM                 constant varchar2(40) := 'Room';
  STAG_RACK                 constant varchar2(40) := 'Rack'; 
  STAG_FAULT                constant varchar2(40) := 'Fault';
  STAG_DETAIL               constant varchar2(40) := 'detail';
  STAG_MESSAGE              constant varchar2(40) := 'Message';
  STAG_ERRORMESSAGE         constant varchar2(40) := 'ErrorMessage';
   
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
      /*
      TODO: owner="mikha" created="16.01.2019"
      text="�������� ��� �������� � �����"
      */
      null;
      /* ������ �� ���� */
      /*P_EXCEPTION(0,
                  '������������� ����������� "%s" �� �������� � ��������.',
                  SDEVICEID);*/
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
    XBODY := DBMS_XSLPROCESSOR.SELECTSINGLENODE(N => XENVELOPE, PATTERN => STAG_BODY);
    /* ��������� �������� �������� ���� */
    XNODELIST := DBMS_XMLDOM.GETCHILDNODES(N => XBODY);
    /* ����� ������ �������� ������� */
    XNODE_ROOT := DBMS_XMLDOM.ITEM(NL => XNODELIST, IDX => 0);
  end UTL_EXSQUEUE_MSG_GET_BODY_ROOT;

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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
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
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQTYPECODE            PKG_STD.TREF;            -- ��� ��������� �� ������� (�������� ������)
    SREQPREFIX              PKG_STD.TSTRING;         -- ������� ��������� �� ������� (�������� ������)
    SREQNUMBER              PKG_STD.TSTRING;         -- ����� ��������� �� ������� (�������� ������)
    DREQDATE                PKG_STD.TLDATE;          -- ���� ��������� �� ������� (�������� ������)
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��� ���������" (�������� ������) */
      NREQTYPECODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_TYPECODE));
      /* ��������� "�������" (�������� ������) */
      SREQPREFIX := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_PREFIX);
      /* ��������� "�����" (�������� ������) */
      SREQNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_NUMBER);
      /* ��������� "����" (�������� ������) */
      DREQDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DATE), 'YYYY-MM-DD');
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
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
                     and (NREQTYPECODE is null or (NREQTYPECODE is not null and T.DOC_TYPE = NREQTYPECODE))
                     and (SREQPREFIX is null or (SREQPREFIX is not null and trim(T.DOC_PREF) = SREQPREFIX))
                     and (SREQNUMBER is null or (SREQNUMBER is not null and trim(T.DOC_NUMB) = SREQNUMBER))
                     and (DREQDATE is null or (DREQDATE is not null and T.DOC_DATE = DREQDATE)))
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
    XSTORAGEMNEMOCODE       DBMS_XMLDOM.DOMNODE;     -- �������� �������������� ��� �������� ��������� ������
    XUSERCODE               DBMS_XMLDOM.DOMNODE;     -- ��� ��� �������� ��������� ������
    XITEMCODE               DBMS_XMLDOM.DOMNODE;     -- ������������� �� ��� �������� ��������� ������
    XITEMNAME               DBMS_XMLDOM.DOMNODE;     -- ������������ �� ��� �������� ��������� ������
    XITEMMNEMOCODE          DBMS_XMLDOM.DOMNODE;     -- ��� �� ��� �������� ��������� ������
    XITEMNUMBER             DBMS_XMLDOM.DOMNODE;     -- ����� �� ��� �������� ��������� ������
    XQUANTITY               DBMS_XMLDOM.DOMNODE;     -- ���������� �� ��� �������� ��������� ������
    XDOC                    DBMS_XMLDOM.DOMDOCUMENT; -- ��������
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQSHEETCODE           PKG_STD.TREF;            -- ��������� �� ������� (�������� ������)
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��������������� ����� ���������" (�������� ������) */
      NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETSHEETITEMSRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSHEETITEMSRSPNS, SNS => SNS_TSD);
      /* ������� ���� ���������� ��������� � �������� "����������� ��������������" */
      for REC in (select T.RN NRN,
                         T.COMPANY NCOMPANY,
                         T.BARCODE SBARCODE,
                         T.IS_LOADED NIS_LOADED,
                         DECODE(T.INVPACK, null, O.PLACE_MNEMO, OP.PLACE_MNEMO) SSTORAGEMNEMOCODE,
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
        XQUANTITY         := UTL_CREATENODE(XDOC => XDOC,
                                            STAG => STAG_QUANTITY,
                                            SNS  => SNS_TSD,
                                            SVAL => REC.SQUANTITY);
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
  
  /* ����������� �������������� - ���������� ���� �������� */
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
    XNODE_ROOT              DBMS_XMLDOM.DOMNODE;     -- �������� ������� ������ ����� ���� ���������
    CRESPONSE               clob;                    -- ����� ��� ������
    SREQDEVICEID            PKG_STD.TSTRING;         -- ������������� ���������� �� �������
    NREQSHEETCODE           PKG_STD.TREF;            -- ��������� �� ������� (�������� ������)
  begin
    begin
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��������������� ����� ���������" (�������� ������) */
      NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* ������ ������������ ��� ��� ������ */
      XGETSTORAGESRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_GETSTORAGESRSPNS, SNS => SNS_TSD);
      /* ������� ����� �������� */
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

  /* ����������� �������������� - ���������� ����������� �������������� */
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
    NREQLATITUDE            PKG_STD.TLNUMBER;        -- ������ �� �� ������� (�������� ����������) 
    NREQLONGITUDE           PKG_STD.TLNUMBER;        -- ������� �� �� ������� (�������� ����������)    
    NREQDISTANCETOSTORAGE   PKG_STD.TLNUMBER;        -- ���������� �� ����� �������� �� �� ������� (�������� ����������)    
    SREQFLOOR               PKG_STD.TSTRING;         -- ���� ������������ �� �� ������� (�������� ����������)
    SREQROOM                PKG_STD.TSTRING;         -- ��������� ������������ �� �� ������� (�������� ����������)
    SREQRACK                PKG_STD.TSTRING;         -- ������� ������������ �� �� ������� (�������� ����������)
    NELINVOBJECT            PKG_STD.TREF;            -- ���. ����� ������� ��������� ��������������
    SDICPLACEBARCODE        PKG_STD.TSTRING;         -- �����-��� ����� �������� g�������� ���������
    NINVENTORY              PKG_STD.TREF;            -- ���. ����� �� (�������� "����������� ���������")
    NCOMPANY                PKG_STD.TREF;            -- ���. ����� �����������
    NPROPERTY               PKG_STD.TREF;            -- ���. ����� �� ������� ��������� �������������� ��� �������� �����������
    NTMP                    PKG_STD.TREF;            -- ����� ��� ���. �������
  begin
    begin
      /* �������������� ����������� */
      NCOMPANY := 136018;
      /* �������������� �� ��� �������� ���������� */
      FIND_DOCS_PROPS_CODE(NFLAG_SMART => 0, NCOMPANY => NCOMPANY, SCODE => 'COMMENT', NRN => NPROPERTY);
      /* ��������� �������� ������� ���� ������� */
      UTL_EXSQUEUE_MSG_GET_BODY_ROOT(NEXSQUEUE => NEXSQUEUE, XNODE_ROOT => XNODE_ROOT);
      /* ��������� ������������� ���������� */
      SREQDEVICEID := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DEVICEID);
      /* ��������� "��������������� ����� ���������" (�������� ����������) */
      NREQSHEETCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_SHEETCODE));
      /* ��������� "��������������� ����� ���" (�������� ����������) */
      NREQUSERCODE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_USERCODE));
      /* ��������� "�������� ����� ��������" (�������� ����������) */
      SREQSTORAGEMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEMNEMOCODE);
      /* ��������� "������� ������ ����� ��������" (�������� ����������) */
      NREQSTORAGEISNEW := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEISNEW));
      /* ��������� "�����-��� ����� ��������" (�������� ����������) */
      SREQSTORAGECODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECODE);
      /* ��������� "������������ ����� ��������" (�������� ����������) */
      SREQSTORAGENAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGENAME);
      /* ��������� "�������� ������ ����� ��������" (�������� ����������) */
      SREQSTORAGEPOSTCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEPOSTCODE);
      /* ��������� "������ ����� ��������" (�������� ����������) */
      SREQSTORAGECOUNTRY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGECOUNTRY);
      /* ��������� "������ ����� ��������" (�������� ����������) */
      SREQSTORAGEREGION := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEREGION);
      /* ��������� "���������� ����� ����� ��������" (�������� ����������) */
      SREQSTORAGELOCALITY := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELOCALITY);
      /* ��������� "����� ����� ��������" (�������� ����������) */
      SREQSTORAGESTREET := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGESTREET);
      /* ��������� "����� ���� ����� ��������" (�������� ����������) */
      SREQSTORAGEHOUSENUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGEHOUSENUMBER);
      /* ��������� "������ ����� ��������" (�������� ����������) */
      NREQSTORAGELATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELATITUDE));
      /* ��������� "������� ����� ��������" (�������� ����������) */
      NREQSTORAGELONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_STORAGELONGITUDE));
      /* ��������� "�����-��� ��" (�������� ����������) */
      SREQITEMCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMCODE);
      /* ��������� "������������ ������������ ��" (�������� ����������) */
      SREQITEMNAME := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNAME);
      /* ��������� "�������� ������������ ��" (�������� ����������) */
      SREQITEMMNEMOCODE := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMMNEMOCODE);
      /* ��������� "����������� ����� ��" (�������� ����������) */
      SREQITEMNUMBER := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ITEMNUMBER);
      /* ��������� "���������� ��" (�������� ����������) */
      NREQQUANTITY := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_QUANTITY));
      /* ��������� "���� ���������� �������������� ��" (�������� ����������) */
      DREQCHECKDATE := TO_DATE(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_CHECKDATE),
                               'YYYY-MM-DD"T"HH24:MI:SS');
      /* ��������� "����������� ��� ��" (�������� ����������) */
      SREQCOMMENT := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_COMMENT);
      /* ��������� "������ ��" (�������� ����������) */
      NREQLATITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LATITUDE));
      /* ��������� "������� ��" (�������� ����������) */
      NREQLONGITUDE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_LONGITUDE));
      /* ��������� "���������� �� ����� �������� ��" (�������� ����������) */
      NREQDISTANCETOSTORAGE := TO_NUMBER(UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_DISTANCETOSTORAGE));
      /* ��������� "���� ������������ ��" (�������� ����������) */
      SREQFLOOR := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_FLOOR);
      /* ��������� "��������� ������������ ��" (�������� ����������) */
      SREQROOM := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_ROOM);
      /* ��������� "������� ������������ ��" (�������� ����������) */
      SREQRACK := UTL_GETNODEVAL(XROOTNODE => XNODE_ROOT, SPATTERN => STAG_RACK);
      /* �������� �������������� ���������� �� �������� */
      UTL_CHECK_DEVICEID(SDEVICEID => SREQDEVICEID);
      /* �������������� �������� ��� ������ */
      UTL_CREATERESPONSEDOC(XDOC => XDOC);
      /* �������� ������ ���� ������ ��������������� ����� ��������� */
      if (NREQSHEETCODE is not null) then
        /*
        TODO: owner="root" created="14.01.2019"
        text="������ ����� �� ��� ������ (������ ���������� �������� �� ����).
              ���� ����������� ���������� ������ ��������������� + ����� ��������"
        */
        /* ���� ����� �����-��� �������������� �� */
        if (SREQSTORAGECODE is not null) then
          /* ��������� ������� ���������������� */
          begin
            select T.BARCODE
              into SDICPLACEBARCODE
              from DICPLACE T
             where T.COMPANY = NCOMPANY
               and T.BARCODE = SREQSTORAGECODE;
          exception
            when NO_DATA_FOUND then
              P_EXCEPTION(0,
                          '��������������� ����������� �������� � �����-����� "%s" �� �������',
                          SREQSTORAGECODE);
          end;
        end if;
        /* ������� ����� ������� ��������� �������������� �� �����-���� (���� ������� ���. ����� ��������� � ���� ��� ������) */
        if (NREQSHEETCODE is not null) then
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
                  P_EXCEPTION(0,
                              '����������� �������� � �����-����� "%s" �� �������',
                              SREQITEMCODE);
              end;
          end;
        end if;
        /* � � ��� ���� �������� ������������ ��������������� */
        if (SDICPLACEBARCODE is not null) then
          /* ���� ������� ��������� �������������� ������� */
          if (NELINVOBJECT is not null) then
            /* ������� � */
            for C in (select T.* from ELINVOBJECT T where T.RN = NELINVOBJECT)
            loop
              P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => C.RN,
                                            SUNITCODE   => 'ElectronicInventoriesObjects',
                                            NPROPERTY   => NPROPERTY,
                                            SSTR_VALUE  => SREQCOMMENT,
                                            NNUM_VALUE  => null,
                                            DDATE_VALUE => null,
                                            NRN         => NTMP);
              P_ELINVOBJECT_BASE_UPDATE(NCOMPANY     => C.COMPANY,
                                        NRN          => C.RN,
                                        DUNLOAD_DATE => C.UNLOAD_DATE,
                                        DINV_DATE    => NVL(DREQCHECKDATE, sysdate),
                                        NINVPERSONS  => NREQUSERCODE,
                                        SBARCODE     => SDICPLACEBARCODE,
                                        NIS_LOADED   => C.IS_LOADED);
            end loop;
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
                                      SBARCODE     => SDICPLACEBARCODE,
                                      NIS_LOADED   => 1,
                                      NRN          => NELINVOBJECT);
            P_DOCS_PROPS_VALS_BASE_MODIFY(NDOCUMENT   => NELINVOBJECT,
                                          SUNITCODE   => 'ElectronicInventoriesObjects',
                                          NPROPERTY   => NPROPERTY,
                                          SSTR_VALUE  => SREQCOMMENT,
                                          NNUM_VALUE  => null,
                                          DDATE_VALUE => null,
                                          NRN         => NTMP);
          end if;
        else
          P_EXCEPTION(0,
                      '�� ������� ���������� ����������� ���������������');
        end if;
      end if;
      /* ������ ������������ ��� ��� ������ */
      XSAVESHEETITEMRESPONSE := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_SAVESHEETITEMRSPNS, SNS => SNS_TSD);
      /* ��������� ��������� */
      XITEM := UTL_CREATENODE(XDOC => XDOC, STAG => STAG_RESULT, SNS => SNS_TSD, SVAL => 'true');
      XNODE := DBMS_XMLDOM.APPENDCHILD(N => XSAVESHEETITEMRESPONSE, NEWCHILD => XITEM);
      /* ����������� ����� � ������� */
      CRESPONSE := UTL_CREATERESPONSE(XDOC => XDOC, XCONTENT => XSAVESHEETITEMRESPONSE);
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
  end SAVESHEETITEM;
  
end;
/
