create or replace package UDO_PKG_EXS_ATOL as

  /* ��������� - �������� ��������� ������� ����-������ */
  STEST_SRV_ROOT_PATTERN    constant varchar2(80) := '%testonline.atol.ru%';      -- ������ ������ ��������� �������
  STEST_INN                 constant varchar2(80) := '5544332219';                -- �������� ���
  STEST_ADDR                constant varchar2(80) := 'https://v4.online.atol.ru'; -- �������� ����� ��������
  
  /* ��������� - ���� ������� ��������� */
  SFN_TYPE_REG_BILL         constant varchar2(20) := 'REG_BILL';     -- ������� ������� ����������� ����
  SFN_TYPE_GET_BILL_INF     constant varchar2(20) := 'GET_BILL_INF'; -- ������� ������� ��������� ��������� � ����������� ����
  
  /* ��������� - ������ ��� (��������� �������������) */
  SFFD105                   constant varchar2(20) := '1.05'; -- ������ ��� 1.05
  SFFD110                   constant varchar2(20) := '1.10'; -- ������ ��� 1.10

  /* ��������� - �������� ���� "����� ������ ���" (1209) ��� ������ ������� */
  NTAG1209_FFD105           constant number(2) := 2; -- �������� ����  1209 ��� ������ ��� 1.05
  NTAG1209_FFD110           constant number(2) := 3; -- �������� ����  1209 ��� ������ ��� 1.10

  /* �������� ������� �� ��, ��� �� �������� �������� */
  function UTL_EXSSERVICE_IS_TEST
  (
    NEXSSERVICE             in number   -- ��������������� ����� ������� ������
  ) return                  boolean;    -- ������� ��������� ������� (true - ��������, false - �� ��������)
  
  /* ��������� ���. ������ ������� ������� ������ ��� ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_EXSFN_REG
  (
    NFISCDOC                in number   -- ���. ����� ����������� ���������
  ) return                  number;     -- ���. ����� ������� ����������� ���� � ������� ����-������

  /* ��������� ���. ������ ������� ������� ������ ��� ������� ���������� � ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_EXSFN_INF
  (
    NFISCDOC                in number   -- ���. ����� ����������� ���������
  ) return                  number;     -- ���. ����� ������� ������� ���������� � ����������� ���� � ������� ����-������    
  
  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ��������� ������� ���� (v4) �� ������ �������� � ������������������ ��������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_GET_BILL_INF
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ��������� ������� ��� �� ������ ���� */
  procedure OFD_PROCESS_GET_BILL_DOC
  (
    NIDENT                  in number,  -- ������������� ��������
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* ��������� - ��������� ��������� � ���� */
  SSTATUS_DONE              constant varchar2(10) := 'done'; -- ������
  SSTATUS_FAIL              constant varchar2(10) := 'fail'; -- ������
  SSTATUS_WAIT              constant varchar2(10) := 'wait'; -- ��������
  
  /* ������ URL ��� ���� ��� */
  SBILL_OFD_UTL             constant varchar2(80) := 'https://ofd.ru/rec/<1041>/<1040>/<1077>?format=pdf';

  /* �������� ������������ ��������� ������� ������� */
  procedure UTL_EXSQUEUE_CHECK_ATTRS
  (
    REXSQUEUE               in EXSQUEUE%rowtype -- ����������� ������ ������� �������
  )
  is
  begin
    /* ������ ���� ����������� */
    if (REXSQUEUE.LNK_COMPANY is null) then
      P_EXCEPTION(0, '��� ������� ������� �� ������� ��������� �����������.');
    end if;
    /* ������ ���� ����� � ���������� */
    if (REXSQUEUE.LNK_DOCUMENT is null) then
      P_EXCEPTION(0, '��� ������� ������� �� ������ ��������� ��������.');
    end if;
    /* ������ ���� ����� � �������� */
    if (REXSQUEUE.LNK_UNITCODE is null) then
      P_EXCEPTION(0, '��� ������� ������� �� ������ ��������� ������.');
    end if;
    /* ������ ���� ����� ������ � �������� "���������� ���������" */    
    if (REXSQUEUE.LNK_UNITCODE <> 'UDO_FiscalDocuments') then
      P_EXCEPTION(0,
                  '��������� ������ "%s", ��������� � ������� �������, �� ��������������.',
                  REXSQUEUE.LNK_UNITCODE);
    end if;
  end UTL_EXSQUEUE_CHECK_ATTRS;
  
  /* ���������� ������ ����������� ��������� */
  function UTL_FISCDOC_GET
  (
    NFISCDOC                in number             -- ���. ����� ����������� ���������
  ) return                  UDO_FISCDOCS%rowtype  -- ��������� ������ ����������� ���������
  is
    RRES                    UDO_FISCDOCS%rowtype; -- ����� ��� ����������
  begin
    /* ������� ������ */
    select T.* into RRES from UDO_FISCDOCS T where T.RN = NFISCDOC;
    /* ����� ��������� */
    return RRES;
  exception
    when NO_DATA_FOUND then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NFISCDOC, SUNIT_TABLE => 'UDO_FISCDOCS');
  end UTL_FISCDOC_GET;
  
  /* ��������� ��������� ������� ������ ��� ����������� ��������� �� ��� �������������� � ����������� */
  function UTL_FISCDOC_GET_EXS_POSTFIX
  (
    NFISCDOC                in number            -- ���. ����� ����������� ���������
  ) return                  varchar2             -- �������� ������� ������
  is
    SRES                    COMPANIES.NAME%type; -- ��������� ������
  begin
    /* ������� ������� ������� ������ (��� ������������ ����������� ����������� ���������) */
    select C.NAME
      into SRES
      from UDO_FISCDOCS  FD,
           COMPANIES C
     where FD.RN = NFISCDOC
       and FD.COMPANY = C.RN;
    /* ���������� ��������� */
    return SRES;
  exception
    when others then
      P_EXCEPTION(0, 
                  '��� ����������� ��������� (RN: %s) �� ��������� �������� ������� ������.',
                  TO_CHAR(NFISCDOC));
  end UTL_FISCDOC_GET_EXS_POSTFIX;
  
  /* ��������� ��������� ������� ������ � ��������� ��� ������� �� ���� ������� ��������� � ������ ��� */
  procedure UTL_FISCDOC_GET_EXSFN
  (
    NFISCDOC                in number,   -- ���. ����� ����������� ���������
    SFN_TYPE                in varchar2, -- ��� ������� ��������� (��. ��������� SFN_TYPE_*)
    NEXSSERVICEFN           out number   -- ���. ����� �������-�����������    
  )
  is
    SEXSRV                  EXSSERVICE.CODE%type;   -- �������� ���������� ������� ������ �� �������� ����������� ���������
    SEXSRVFN                EXSSERVICEFN.CODE%type; -- �������� ��������� ������� ������ �� �������� ����������� ���������
  begin
    begin
      /* ������� �������� ��������� ������� � ������� �� �������� ����������� ��������� */
      select DECODE(SFN_TYPE, SFN_TYPE_REG_BILL, SREG.CODE, SFN_TYPE_GET_BILL_INF, SINF.CODE),
             DECODE(SFN_TYPE, SFN_TYPE_REG_BILL, SFNREG.CODE, SFN_TYPE_GET_BILL_INF, SFNINF.CODE)
        into SEXSRV,
             SEXSRVFN
        from UDO_FISCDOCS  FD,
             UDO_FDKNDVERS TV,
             EXSSERVICEFN  SFNREG,
             EXSSERVICEFN  SFNINF,
             EXSSERVICE    SREG,
             EXSSERVICE    SINF
       where FD.RN = NFISCDOC
         and FD.TYPE_VERSION = TV.RN
         and TV.FUNCTION_SEND = SFNREG.RN(+)
         and SFNREG.PRN = SREG.RN(+)
         and TV.FUNCTION_RESP = SFNINF.RN(+)
         and SFNINF.PRN = SINF.RN(+);
    exception
      when others then
        SEXSRV   := null;
        SEXSRVFN := null;
    end;
    /* ���� ������� ��������� ������ ������ � ������� - ��������� �� ��� ����� �� ������������� ����������� ��������� � ����������� */
    if ((SEXSRV is not null) and (SEXSRVFN is not null)) then
      NEXSSERVICEFN := PKG_EXS.SERVICEFN_FIND_BY_SRVCODE(NFLAG_SMART => 0,
                                                         SEXSSERVICE => SEXSRV || '_' || UTL_FISCDOC_GET_EXS_POSTFIX(NFISCDOC => NFISCDOC),
                                                         SEXSSERVICEFN => SEXSRVFN);
    else
      /* ������� �� ������� - ������ ���������� ������ �������� ������� */
      P_EXCEPTION(0,
                  '��� ����������� ��������� (RN: %s) �� ����������� ������� ������� "%s".',
                  TO_CHAR(NFISCDOC),
                  SFN_TYPE);
    end if;
  end UTL_FISCDOC_GET_EXSFN;
  
  /* ��������� ���. ������ ������� ������� ������ ��� ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_EXSFN_REG
  (
    NFISCDOC                in number     -- ���. ����� ����������� ���������
  ) return                  number        -- ���. ����� ������� ����������� ���� � ������� ����-������
  is
    NRES                    PKG_STD.TREF; -- ����� ��� ����������
  begin
    /* ��������� ��������� ������� � ������� ��� ��������� */
    UTL_FISCDOC_GET_EXSFN(NFISCDOC => NFISCDOC, SFN_TYPE => SFN_TYPE_REG_BILL, NEXSSERVICEFN => NRES);
    /* ����� ��������� */
    return NRES;
  end UTL_FISCDOC_GET_EXSFN_REG;
  
  /* ��������� ���. ������ ������� ������� ������ ��� ������� ���������� � ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_EXSFN_INF
  (
    NFISCDOC                in number     -- ���. ����� ����������� ���������
  ) return                  number        -- ���. ����� ������� ������� ���������� � ����������� ���� � ������� ����-������
  is
    NRES                    PKG_STD.TREF; -- ����� ��� ����������
  begin
    /* ��������� ��������� ������� � ������� ��� ��������� */
    UTL_FISCDOC_GET_EXSFN(NFISCDOC => NFISCDOC, SFN_TYPE => SFN_TYPE_GET_BILL_INF, NEXSSERVICEFN => NRES);
    /* ����� ��������� */
    return NRES;
  end UTL_FISCDOC_GET_EXSFN_INF;

  /* �������� ������ ��� */
  procedure UTL_FISCDOC_CHECK_FFD_VERS
  (
    NCOMPANY                in number,  -- ���. ����� �����������
    NFISCDOC                in number,  -- ���. ����� ����������� ���������    
    NEXPECTED_VERS          in number,  -- ��������� ������ ��� (�� �������� ���� 1209, ��. ��������� NTAG1209_FFD*)
    SEXPECTED_VERS          in varchar2 -- ��������� ������ ��� (��������� �������������)
  )
  is
  begin
    /* ������� ��� 1209 (� ��� �������� ����� ������ ���) � ������ ��������, ����������� � ��������� ���������� */
    if (UDO_F_FISCDOCS_GET_NUMB(NRN => NFISCDOC, NCOMPANY => NCOMPANY, SATTRIBUTE => '1209') != NEXPECTED_VERS) then
      P_EXCEPTION(0,
                  '������ ������� ����������� ��������� (�������� ���� 1209 - %s) �� ��������������. ��������� ������ - %s (�������� ���� 1209 - %s).',
                  NVL(TO_CHAR(UDO_F_FISCDOCS_GET_NUMB(NRN => NFISCDOC, NCOMPANY => NCOMPANY, SATTRIBUTE => '1209')),
                      '<�� �������>'),
                  NVL(SEXPECTED_VERS, '<�� �������>'),
                  NVL(TO_CHAR(NEXPECTED_VERS), '<�� �������>'));
    end if;
  end UTL_FISCDOC_CHECK_FFD_VERS;
  
  /* �������� ������� �� ��, ��� �� �������� �������� */
  function UTL_EXSSERVICE_IS_TEST
  (
    NEXSSERVICE             in number           -- ��������������� ����� ������� ������
  ) return                  boolean             -- ������� ��������� ������� (true - ��������, false - �� ��������)
  is
    REXSSERVICE             EXSSERVICE%rowtype; -- ������ ������� ������
  begin
    /* ������� ������ ������� ������ */
    REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => NEXSSERVICE);
    /* �������� ��� �� ������ */
    if (REXSSERVICE.SRV_ROOT like STEST_SRV_ROOT_PATTERN) then
      return true;
    else
      return false;
    end if;
  end;

  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,            -- ������������� ��������
    NEXSQUEUE               in number             -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    RFISCDOC                UDO_FISCDOCS%rowtype; -- ������ ����������� ���������
    CTMP                    clob;                 -- ����� ��� �������� ������ ������ �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ��� ������� ������� ��������� */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* ������� ������ ����������� ��������� */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* ��������, ��� �� ������� ������� */
    UTL_FISCDOC_CHECK_FFD_VERS(NCOMPANY       => RFISCDOC.COMPANY,
                               NFISCDOC       => RFISCDOC.RN,
                               NEXPECTED_VERS => NTAG1209_FFD105,
                               SEXPECTED_VERS => SFFD105);
    /* ��������� ����� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    if (CTMP is null) then
      P_EXCEPTION(0, '��� ������ �� �������.');
    end if;
    /* ���������� ������������� ���� � �� */
    update UDO_FISCDOCS T set T.NUMB_FD = CTMP where T.RN = REXSQUEUE.LNK_DOCUMENT;
    /* �� ������ ������� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end V4_FFD105_PROCESS_REG_BILL_SIR;
  
  /* ��������� ������� ���� (v4) �� ������ �������� � ������������������ ��������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_GET_BILL_INF
  (
    NIDENT                  in number,            -- ������������� ��������
    NEXSQUEUE               in number             -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- ������ ������� �������
    RFISCDOC                UDO_FISCDOCS%rowtype; -- ������ ����������� ���������
    RDOC                    PKG_XPATH.TDOCUMENT;  -- ����������� XML-��������
    RROOT_NODE              PKG_XPATH.TNODE;      -- �������� ��� XML-���������
    SSTATUS                 PKG_STD.TSTRING;      -- ����� ��� �������� "������ ��������� ���������"
    STIMESTAMP              PKG_STD.TSTRING;      -- ����� ��� �������� "���� � ����� ��������� ������� �������" (��������� �������������)
    DTIMESTAMP              PKG_STD.TLDATE;       -- ����� ��� �������� "���� � ����� ��������� ������� �������"
    STAG1012                PKG_STD.TSTRING;      -- ����� ��� �������� "���� � ����� ��������� �� ��" (��� 1012)
    STAG1038                PKG_STD.TSTRING;      -- ����� ��� �������� "����� �����" (��� 1038)
    STAG1040                PKG_STD.TSTRING;      -- ����� ��� �������� "���������� ����� ���������" (��� 1040)
    STAG1041                PKG_STD.TSTRING;      -- ����� ��� �������� "����� ��" (��� 1041)
    STAG1042                PKG_STD.TSTRING;      -- ����� ��� �������� "����� ���� � �����" (��� 1042)
    STAG1077                PKG_STD.TSTRING;      -- ����� ��� �������� "���������� ������� ���������" (��� 1077)
    SERR_CODE               PKG_STD.TSTRING;      -- ����� ��� �������� "��� ������"
    SERR_TEXT               PKG_STD.TSTRING;      -- ����� ��� �������� "����� ������"
    NNEW_EXSQUEUE           PKG_STD.TREF;         -- ���. ����� ������ ������� ������ (��� ���������� �������� ����)
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ��� ������� ������� ��������� */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* ������� ������ ����������� ��������� */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* ��������, ��� �� ������� ������� */
    UTL_FISCDOC_CHECK_FFD_VERS(NCOMPANY       => RFISCDOC.COMPANY,
                               NFISCDOC       => RFISCDOC.RN,
                               NEXPECTED_VERS => NTAG1209_FFD105,
                               SEXPECTED_VERS => SFFD105);
    /* ��������� ����� */
    begin
      RDOC := PKG_XPATH.PARSE_FROM_BLOB(LBXML => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    exception
      when others then
        P_EXCEPTION(0, '������ ������� XML - ����������� ����� �������.');
    end;
    /* ������� �������� ������� */
    RROOT_NODE := PKG_XPATH.ROOT_NODE(RDOCUMENT => RDOC);
    /* �������� �������� ��������� */
    SSTATUS    := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/STATUS'));
    STAG1012   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1012'));
    STAG1038   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1038'));
    STAG1040   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1040'));
    STAG1041   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1041'));
    STAG1042   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1042'));
    STAG1077   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1077'));
    STIMESTAMP := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/TIMESTAMP'));
    SERR_CODE  := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/ERROR/CODE'));
    SERR_TEXT  := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/ERROR/TEXT'));
    /* ����������� ������ */
    PKG_XPATH.FREE(RDOCUMENT => RDOC);
    /* ��������, ��� ������ ������ ��������� */
    if (SSTATUS is null) then
      P_EXCEPTION(0, '�� ������ ������ ��������� ���������.');
    end if;
    /* ������������ ����� � ����������� �� ������� */
    case SSTATUS
      /* �������������� */
      when SSTATUS_WAIT then
        begin
          /* �������� ��� �� ���������, ������� �����������, ������� ���� ������ �� ������ */
          null;
        end;
      /* ����� */
      when SSTATUS_DONE then
        begin
          /* �������� ������� ������ � ����� � ���� ������ ���� */
          if (STIMESTAMP is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "���� � ����� ��������� ������� �������".',
                        SSTATUS);
          end if;
          if (STAG1012 is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "���� � ����� ��������� �� ��" (��� 1012).',
                        SSTATUS);
          end if;
          if (STAG1038 is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "����� �����" (��� 1038).',
                        SSTATUS);
          end if;
          if (STAG1040 is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "���������� ����� ���������" (��� 1040).',
                        SSTATUS);
          end if;
          if (STAG1041 is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "����� ��" (��� 1041).',
                        SSTATUS);
          end if;
          if (STAG1042 is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "����� ���� � �����" (��� 1042).',
                        SSTATUS);
          end if;
          if (STAG1077 is null) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������� �������� "���������� ������� ���������" (��� 1077).',
                        SSTATUS);
          end if;
          /* ��������� ������������ ���� ������������� */
          begin
            DTIMESTAMP := TO_DATE(STIMESTAMP, 'dd.mm.yyyy hh24:mi:ss');
          exception
            when others then
              P_EXCEPTION(0,
                          '�������� ���� "���� � ����� ��������� ������� �������" (%s) �� �������� ����� � ������� "��.��.���� ��:��:CC"',
                          STIMESTAMP);
          end;
          /* ���������� �������� "���� �������������" � "������ �� ���������� �������� � ���" ��� ����������� ��������� */
          update UDO_FISCDOCS T
             set T.CONFIRM_DATE = DTIMESTAMP,
                 T.DOC_URL      = replace(replace(replace(SBILL_OFD_UTL, '<1040>', STAG1040), '<1041>', STAG1041),
                                          '<1077>',
                                          STAG1077)
           where T.RN = RFISCDOC.RN;
          /* ������������� �������� ����� */
          begin
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN          => RFISCDOC.RN,
                                       NCOMPANY      => RFISCDOC.COMPANY,
                                       SATTRIBUTE    => '1012',
                                       DVAL_DATETIME => TO_DATE(STAG1012, 'dd.mm.yyyy hh24:mi:ss'));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1038',
                                       NVAL_NUMB  => TO_NUMBER(STAG1038));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1040',
                                       NVAL_NUMB  => TO_NUMBER(STAG1040));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1041',
                                       SVAL_STR   => STAG1041);
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1042',
                                       NVAL_NUMB  => TO_NUMBER(STAG1042));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1077',
                                       SVAL_STR   => STAG1077);
          exception
            when others then
              P_EXCEPTION(0,
                          '������ ��������� �������� �������� ����������� ���������: %s',
                          sqlerrm);
          end;
          /* ������ ������ �� ��������� ���� �� ��� */
          PKG_EXS.QUEUE_PUT(SEXSSERVICE   => '���_���������',
                            SEXSSERVICEFN => '���������',
                            BMSG          => CLOB2BLOB(LCDATA   => STAG1041 || '/' || STAG1040 || '/' || STAG1077,
                                                       SCHARSET => 'UTF8'),
                            NLNK_COMPANY  => RFISCDOC.COMPANY,
                            NLNK_DOCUMENT => RFISCDOC.RN,
                            SLNK_UNITCODE => 'UDO_FiscalDocuments',
                            NNEW_EXSQUEUE => NNEW_EXSQUEUE);
        end;
      /* ������ ��������� */
      when SSTATUS_FAIL then
        begin
          /* ��������, ��� ������ ��� � ����� ������ */
          if ((SERR_CODE is null) or (SERR_TEXT is null)) then
            P_EXCEPTION(0,
                        '�������� � ������� "%s", �� �� ������ ��� ��� ����� ������.',
                        SSTATUS);
          end if;
          /* �������� ��� � ����� � ���������� ��������� */
          update UDO_FISCDOCS T
             set T.SEND_ERROR = SUBSTR(SERR_CODE || ': ' ||
                                       REGEXP_REPLACE(replace(SERR_TEXT, CHR(10), ''), '[[:space:]]+', ' '),
                                       1,
                                       4000)
           where T.RN = RFISCDOC.RN;
        end;
      /* ����������� ������ */
      else
        P_EXCEPTION(0, 'C����� �������� "%s" �� ��������������.', SSTATUS);
    end case;
    /* �� ������ ������� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end V4_FFD105_PROCESS_GET_BILL_INF;
  
  /* ��������� ������� ��� �� ������ ���� */
  procedure OFD_PROCESS_GET_BILL_DOC
  (
    NIDENT                  in number,        -- ������������� ��������
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ��� ������� ������� ��������� */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* �������� ���������� ��� � �� */
    UDO_P_FISCDOCS_PUT_BILL(NRN => REXSQUEUE.LNK_DOCUMENT, NCOMPANY => REXSQUEUE.LNK_COMPANY, BDATA => REXSQUEUE.RESP);
    /* �� ������ ������� */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* ����� ������ */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end OFD_PROCESS_GET_BILL_DOC;
      
end;
/
