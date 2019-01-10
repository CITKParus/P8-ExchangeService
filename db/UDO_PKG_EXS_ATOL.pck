create or replace package UDO_PKG_EXS_ATOL as

  /* ��������� - ���� ������� ��������� */
  SFN_TYPE_REG_BILL         constant varchar2(20) := 'REG_BILL';     -- ������� ������� ����������� ����
  SFN_TYPE_GET_BILL_INF     constant varchar2(20) := 'GET_BILL_INF'; -- ������� ������� ��������� ��������� � ����������� ����

  /* ��������� ���. ������ ������� ������� ������ ��� ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_REG_EXSFN
  (
    NFISCDOC                in number   -- ���. ����� ����������� ���������
  ) return                  number;     -- ���. ����� ������� ����������� ���� � ������� ����-������

  /* ��������� ���. ������ ������� ������� ������ ��� ������� ���������� � ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_INF_EXSFN
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
    NFISCDOC                in number               -- ���. ����� ����������� ���������
  ) return                  UDO_V_FISCDOCS%rowtype  -- ��������� ������ ����������� ���������
  is
    RRES                    UDO_V_FISCDOCS%rowtype; -- ����� ��� ����������
  begin
    /* ������� ������ */
    select T.* into RRES from UDO_V_FISCDOCS T where T.NRN = NFISCDOC;
    /* ����� ��������� */
    return RRES;
  exception
    when NO_DATA_FOUND then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NFISCDOC, SUNIT_TABLE => 'UDO_FISCDOCS');
  end UTL_FISCDOC_GET;
  
  /* ��������� ��������� ������� ������ � ��������� ��� ������� �� ���� ������� ��������� � ������ ��� */
  procedure UTL_FISCDOC_GET_EXSFN_BY_FFD
  (
    SFN_TYPE                in varchar2, -- ��� ������� ��������� (��. ��������� SFN_TYPE_*)
    SFFD_VERSION            in varchar2, -- ������ ���    
    SEXSSERVICE             out varchar2, -- ��� �������-�����������
    SEXSSERVICEFN           out varchar2 -- ��� �������-�����������    
  )
  is
  begin
    /* �������� �� ������� ������� */
    case SFN_TYPE
      /* ����������� ���� */
      when SFN_TYPE_REG_BILL then
        begin
          /* �������� API ������ � ����������� �� ������ ����������� ��������� */
          case SFFD_VERSION
            /* ��� 1.05 */
            when '1.05' then
              begin
                SEXSSERVICE   := '����_V4_���';
                SEXSSERVICEFN := 'V4_���1.05_������������������';
              end;
            /* ����������� ������ ��� */
            else
              begin
                P_EXCEPTION(0,
                            '������ ����������� ��������� "%s" �� ��������������!',
                            SFFD_VERSION);
              end;
          end case;
        end;
      /* ��������� ��������� � ����������� ���� */
      when SFN_TYPE_GET_BILL_INF then
        begin
          /* �������� API ������ � ����������� �� ������ ����������� ��������� */
          case SFFD_VERSION
            /* ��� 1.05 */
            when '1.05' then
              begin
                SEXSSERVICE   := '����_V4_���';
                SEXSSERVICEFN := 'V4_���1.05_������������';
              end;
            /* ����������� ������ ��� */
            else
              begin
                P_EXCEPTION(0,
                            '������ ����������� ��������� "%s" �� ��������������!',
                            SFFD_VERSION);
              end;
          end case;
        end;
      /* ����������� ������� ������� */
      else
        begin
          P_EXCEPTION(0, '������� ������� "%s" �� ��������������!', SFN_TYPE);
        end;
    end case;
  end UTL_FISCDOC_GET_EXSFN_BY_FFD;
  
  /* ��������� ���. ������ ������� ������� ������ ��� ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_REG_EXSFN
  (
    NFISCDOC                in number               -- ���. ����� ����������� ���������
  ) return                  number                  -- ���. ����� ������� ����������� ���� � ������� ����-������
  is
    NRES                    PKG_STD.TREF;           -- ����� ��� ����������
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- ������ ����������� ���������
    NEXSSERVICE             EXSSERVICEFN.RN%type;   -- ���. ����� �������-�����������
    SEXSSERVICE             EXSSERVICEFN.CODE%type; -- ��� �������-�����������
    SEXSSERVICEFN           EXSSERVICEFN.CODE%type; -- ��� �������-�����������    
  begin
    /* ������� ������ ����������� ��������� */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => NFISCDOC);
    /* ��������� ��������� ������� � ������� ��� ��������� */
    UTL_FISCDOC_GET_EXSFN_BY_FFD(SFN_TYPE      => SFN_TYPE_REG_BILL,
                                 SFFD_VERSION  => RFISCDOC.STYPE_VERSION,
                                 SEXSSERVICE   => SEXSSERVICE,
                                 SEXSSERVICEFN => SEXSSERVICEFN);
    /* ������� ���. ����� ������� */
    FIND_EXSSERVICE_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICE, NRN => NEXSSERVICE);
    /* ������� ���. ����� ������� ������� */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART  => 0,
                           NFLAG_OPTION => 0,
                           NEXSSERVICE  => NEXSSERVICE,
                           SCODE        => SEXSSERVICEFN,
                           NRN          => NRES);
    /* ����� ��������� */
    return NRES;
  end UTL_FISCDOC_GET_REG_EXSFN;
  
  /* ��������� ���. ������ ������� ������� ������ ��� ������� ���������� � ����������� ���� �� ���. ������ ����������� ��������� */
  function UTL_FISCDOC_GET_INF_EXSFN
  (
    NFISCDOC                in number               -- ���. ����� ����������� ���������
  ) return                  number                  -- ���. ����� ������� ������� ���������� � ����������� ���� � ������� ����-������
  is
    NRES                    PKG_STD.TREF;           -- ����� ��� ����������
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- ������ ����������� ���������
    NEXSSERVICE             EXSSERVICEFN.RN%type;   -- ���. ����� �������-�����������
    SEXSSERVICE             EXSSERVICEFN.CODE%type; -- ��� �������-�����������
    SEXSSERVICEFN           EXSSERVICEFN.CODE%type; -- ��� �������-�����������    
  begin
    /* ������� ������ ����������� ��������� */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => NFISCDOC);
    /* ��������� ��������� ������� � ������� ��� ��������� */
    UTL_FISCDOC_GET_EXSFN_BY_FFD(SFN_TYPE      => SFN_TYPE_GET_BILL_INF,
                                 SFFD_VERSION  => RFISCDOC.STYPE_VERSION,
                                 SEXSSERVICE   => SEXSSERVICE,
                                 SEXSSERVICEFN => SEXSSERVICEFN);
    /* ������� ���. ����� ������� */
    FIND_EXSSERVICE_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICE, NRN => NEXSSERVICE);
    /* ������� ���. ����� ������� ������� */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART  => 0,
                           NFLAG_OPTION => 0,
                           NEXSSERVICE  => NEXSSERVICE,
                           SCODE        => SEXSSERVICEFN,
                           NRN          => NRES);
    /* ����� ��������� */
    return NRES;
  end UTL_FISCDOC_GET_INF_EXSFN;     

  /* ��������� ������� ���� (v4) �� ����������� ���� �� ������, ������, ������� (��� 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,              -- ������������� ��������
    NEXSQUEUE               in number               -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;       -- ������ ������� �������
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- ������ ����������� ���������
    CTMP                    clob;                   -- ����� ��� �������� ������ ������ �������
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ��� ������� ������� ��������� */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* ������� ������ ����������� ��������� */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* ��������, ��� �� ������� ������� */
    if (RFISCDOC.STYPE_VERSION <> '1.05') then
      P_EXCEPTION(0,
                  '������ ������� ����������� ��������� (%s) �� ��������������. ��������� ������ - 1.05.',
                  RFISCDOC.STYPE_VERSION);
    end if;
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
    NIDENT                  in number,              -- ������������� ��������
    NEXSQUEUE               in number               -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;       -- ������ ������� �������
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- ������ ����������� ���������
    RDOC                    PKG_XPATH.TDOCUMENT;    -- ����������� XML-��������
    RROOT_NODE              PKG_XPATH.TNODE;        -- �������� ��� XML-���������
    SSTATUS                 PKG_STD.TSTRING;        -- ����� ��� �������� "������ ��������� ���������"
    STIMESTAMP              PKG_STD.TSTRING;        -- ����� ��� �������� "���� � ����� ��������� ������� �������" (��������� �������������)
    DTIMESTAMP              PKG_STD.TLDATE;         -- ����� ��� �������� "���� � ����� ��������� ������� �������"
    STAG1012                PKG_STD.TSTRING;        -- ����� ��� �������� "���� � ����� ��������� �� ��" (��� 1012)
    STAG1040                PKG_STD.TSTRING;        -- ����� ��� �������� "���������� ����� ���������" (��� 1040)
    STAG1041                PKG_STD.TSTRING;        -- ����� ��� �������� "����� ��" (��� 1041)
    STAG1077                PKG_STD.TSTRING;        -- ����� ��� �������� "���������� ������� ���������" (��� 1077)
    SERR_CODE               PKG_STD.TSTRING;        -- ����� ��� �������� "��� ������"
    SERR_TEXT               PKG_STD.TSTRING;        -- ����� ��� �������� "����� ������"
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ��� ������� ������� ��������� */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* ������� ������ ����������� ��������� */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* ��������, ��� �� ������� ������� */
    if (RFISCDOC.STYPE_VERSION <> '1.05') then
      P_EXCEPTION(0,
                  '������ ������� ����������� ��������� (%s) �� ��������������. ��������� ������ - 1.05.',
                  RFISCDOC.STYPE_VERSION);
    end if;
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
    STIMESTAMP := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/TIMESTAMP'));
    STAG1012   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1012'));
    STAG1040   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1040'));
    STAG1041   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1041'));
    STAG1077   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1077'));
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
           where T.RN = RFISCDOC.NRN;
          /* ������������� �������� ����� */
          begin
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.NRN,
                                       NCOMPANY   => RFISCDOC.NCOMPANY,
                                       SATTRIBUTE => '1040',
                                       NVAL_NUMB  => TO_NUMBER(STAG1040));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.NRN,
                                       NCOMPANY   => RFISCDOC.NCOMPANY,
                                       SATTRIBUTE => '1041',
                                       SVAL_STR   => STAG1041);
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.NRN,
                                       NCOMPANY   => RFISCDOC.NCOMPANY,
                                       SATTRIBUTE => '1077',
                                       SVAL_STR   => STAG1077);
          exception
            when others then
              P_EXCEPTION(0,
                          '������ ��������� �������� �������� ����������� ���������: %s',
                          sqlerrm);
          end;
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
           where T.RN = RFISCDOC.NRN;
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
  
end;
/
