create or replace package UDO_PKG_EXS_ALICE as

  /* ��������� ������� �� ����� ����������� */
  procedure FIND_AGENT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

  /* ��������� ������� �� ����� �������� */
  procedure FIND_CONTRACT
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );  

  /* ��������� ������� �� ����� ������ ����������� */
  procedure FIND_CONSUMERORD
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );  

end;
/
create or replace package body UDO_PKG_EXS_ALICE as

  /* ��������� - ������� ��� ������ ������ */
  SSEARCH_CATALOG_NAME      constant ACATALOG.NAME%type := '������� 20_12_2018';
  
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
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�������';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '���';    
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '��������%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '������%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '���';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '���';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '���';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�����%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '��';
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

  /* ��������� ������� �� ����� ����������� */
  procedure FIND_AGENT
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
                       T.AGNTYPE NAGNTYPE,
                       (select count(CN.RN) from CONTRACTS CN where CN.AGENT = T.RN) NCNT_CONTRACTS,
                       (select sum(CN.DOC_SUM) from CONTRACTS CN where CN.AGENT = T.RN) NSUM_CONTRACTS,
                       T.PHONE SPHONE,
                       T.MAIL SMAIL,
                       T.AGN_COMMENT SCONTACT_PERSON,
                       NVL((select 1 from DUAL where LOWER(T.AGN_COMMENT) like LOWER(CTMP)), 0) NLINKED_SIGN
                  from AGNLIST  T,
                       ACATALOG CAT
                 where ((LOWER(T.AGNABBR) like LOWER(CTMP)) or (LOWER(T.AGNNAME) like LOWER(CTMP)) or
                       (LOWER(T.AGN_COMMENT) like LOWER(CTMP)))
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* �������� ���������� */
        if (C.NLINKED_SIGN = 1) then
          CRESP := '�� �������� ���������������, ������ �� ���������� � �������������� ���������� � �����������:' ||
                   CHR(10) || CHR(10) || C.SAGENT;
        else
          CRESP := C.SAGENT;
        end if;
        /* ����� - � ����������� �� ����, ��� �� - �������� � ��������� � ���������� ���� */
        if (C.NAGNTYPE = 0) then
          if (C.NCNT_CONTRACTS = 0) then
            CRESP := CRESP || ', �� ����� ������������������ � ������� ���������';
          else
            CRESP := CRESP || ', ���������������� ���������: ' || TO_CHAR(C.NCNT_CONTRACTS);
            if (C.NSUM_CONTRACTS <> 0) then
              CRESP := CRESP || ', �� ����� �����: ' || TO_CHAR(C.NSUM_CONTRACTS) || ' ���.';
            end if;
          end if;
          if (C.SCONTACT_PERSON is not null) then
            CRESP := CRESP || ', ���������� ����: ' || C.SCONTACT_PERSON;
          end if;
        end if;
        /* �������� ����������� - ������� */
        if (C.SPHONE is not null) then
          CRESP := CRESP || ', �������: ' || C.SPHONE;
        end if;
        /* �������� ����������� - e-mail */
        if (C.SMAIL is not null) then
          CRESP := CRESP || ', e-mail: ' || C.SMAIL;
        end if;
      end loop;
    else
      CRESP := '�� ������ ��������� ������';
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end FIND_AGENT;

  /* ��������� ������� �� ����� �������� */
  procedure FIND_CONTRACT
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
      /* �������������� ����� */
      CRESP := '������� �� ������';
      /* ���� ����������� ������� */
      for C in (select DECODE(T.INOUT_SIGN, 0, '��������', '���������') || ' ������� �' ||
                       NVL(T.EXT_NUMBER, trim(T.DOC_NUMB)) || ' �� ' || TO_CHAR(T.DOC_DATE, 'dd.mm.yyyy') ||
                       ' � ������������ ' || AG.AGNNAME SDOC,
                       T.SUBJECT SSUBJECT,
                       T.DOC_SUM NDOC_SUM,
                       T.DOC_INPAY_SUM NDOC_INPAY_SUM,
                       T.DOC_OUTPAY_SUM NDOC_OUTPAY_SUM,
                       T.END_DATE DEND_DATE,
                       CN.ALTNAME10 SCUR
                  from CONTRACTS T,
                       AGNLIST   AG,
                       CURNAMES  CN,
                       ACATALOG  CAT
                 where ((LOWER(T.EXT_NUMBER) like LOWER(CTMP)) or
                       (LOWER(trim(T.DOC_NUMB)) like LOWER(CTMP)))
                   and T.AGENT = AG.RN
                   and T.CURRENCY = CN.RN
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* �������� �������� */
        CRESP := C.SDOC;
        /* ������� �������� */
        if (C.SSUBJECT is not null) then
          CRESP := CRESP || ', ������� ��������: ' || C.SSUBJECT;
        end if;
        /* ����� �������� */
        if (C.NDOC_SUM <> 0) then
          CRESP := CRESP || CHR(10) || '����� ��������: ' || TO_CHAR(C.NDOC_SUM) || ' ' || C.SCUR;
          /* ��������� ������ ��� ����������� �� */
          if (C.NDOC_INPAY_SUM <> 0) then
            if (C.NDOC_INPAY_SUM = C.NDOC_SUM) then
              CRESP := CRESP || ', ������� ��������� ���������';
            else
              CRESP := CRESP || ', �������� �� ���������: ' || TO_CHAR(C.NDOC_INPAY_SUM) || ' ' || C.SCUR;
              if (C.NDOC_SUM - C.NDOC_INPAY_SUM > 0) then
                CRESP := CRESP || ', ������� � ���������: ' || TO_CHAR(C.NDOC_SUM - C.NDOC_INPAY_SUM) || ' ' || C.SCUR;
                if (C.DEND_DATE is not null) then
                  CRESP := CRESP || ', ������� �������� ' || TO_CHAR(C.DEND_DATE, 'dd.mm.yyyy');
                end if;
              end if;
            end if;
          end if;
          /* ��������� ������ ��� ������� �� */
          if (C.NDOC_OUTPAY_SUM <> 0) then
            if (C.NDOC_OUTPAY_SUM = C.NDOC_SUM) then
              CRESP := CRESP || ', ��������� ������� ��������';
            else
              CRESP := CRESP || ', �������� ��������� ' || TO_CHAR(C.NDOC_OUTPAY_SUM) || ' ' || C.SCUR;
              if (C.NDOC_SUM - C.NDOC_OUTPAY_SUM > 0) then
                CRESP := CRESP || ', ������� � ������ ' || TO_CHAR(C.NDOC_SUM - C.NDOC_OUTPAY_SUM) || ' ' || C.SCUR;
                if (C.DEND_DATE is not null) then
                  CRESP := CRESP || ', ������� �������� ' || TO_CHAR(C.DEND_DATE, 'dd.mm.yyyy');
                end if;
              end if;
            end if;
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
  end FIND_CONTRACT;
  
  /* ��������� ������� �� ����� ������ ����������� */
  procedure FIND_CONSUMERORD
  (
    NIDENT                  in number,        -- ������������� ��������
    NSRV_TYPE               in number,        -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- ��������������� ����� �������������� ������� ������� ������
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- ��������� �������� ��������������� ���� ������
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    NSTATE_PROP             PKG_STD.TREF;     -- ���. ����� �� ��� �������� ��������� ������
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
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '�����%';
    /* �������� ������ ��������� � ������������ � ��������� �� */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* ����� ���������������� ������� (������ ��� �������� �����������) */
    PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
    /* ���� ���� ��� ������ */
    if (CTMP is not null) then
      /* ���������� ��������� ����� */
      CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
      /* �������������� ����� */
      CRESP := '����� �� ������';
      /* ���� ����������� ����� */
      for C in (select '����� �' || trim(T.ORD_NUMB) || ' �� ' || TO_CHAR(T.ORD_DATE, 'dd.mm.yyyy') SDOC,
                       T.PSUMWTAX NSUM,
                       T.RELEASE_DATE DRELEASE_DATE,
                       (select V.STR_VALUE
                          from DOCS_PROPS_VALS V,
                               DOCS_PROPS      DP
                         where V.UNIT_RN = T.RN
                           and V.DOCS_PROP_RN = DP.RN
                           and DP.CODE = '�������������������') SSTATE,
                       CN.ALTNAME10 SCUR
                  from CONSUMERORD T,
                       AGNLIST     AG,
                       CURNAMES    CN,
                       ACATALOG    CAT
                 where (LOWER(trim(T.ORD_NUMB)) like LOWER(CTMP))
                   and T.AGENT = AG.RN
                   and T.CURRENCY = CN.RN
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* �������� �������� */
        CRESP := C.SDOC;
        /* ��������� */
        if (C.SSTATE is not null) then
          CRESP := CRESP || ', ��������� � ��������� "' || C.SSTATE || '"';
        else
          CRESP := CRESP || ', � ��������� �� ������� ���������� ��������� ������, �� �� ����� ������� ���';
        end if;
        /* ����� ������ */
        if (C.NSUM <> 0) then
          CRESP := CRESP || ', ����� ������ ���������� ' || TO_CHAR(C.NSUM) || ' ' || C.SCUR;
        end if;
        /* �������� ���� ���������� */
        CRESP := CRESP || ', �������� ���� ���������� ������ ' || TO_CHAR(C.DRELEASE_DATE, 'dd.mm.yyyy');
      end loop;
    else
      CRESP := '�� ������ ��������� ������';
    end if;
    /* ���������� ����� */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end FIND_CONSUMERORD;

end;
/
