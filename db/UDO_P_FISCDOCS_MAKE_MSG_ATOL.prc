create or replace procedure UDO_P_FISCDOCS_MAKE_MSG_ATOL
(
  NCOMPANY                  in number,            -- �����������
  NFISCDOC                  in number,            -- ��������������� ����� ����������� ���������
  NEXSQUEUE                 out number            -- ��������������� ����� ����������� ������� ������� ������
)
as
  /* ��������� ���������� */
  CDATA                     clob;                 -- ����� ��� XML-�������
  NTMP_RN                   PKG_STD.TREF;         -- ����� ��� ����������  
  REXSSERVICEFN             EXSSERVICEFN%rowtype; -- ������ ������� ������� ����������
  BTEST_SRV                 boolean := false;     -- ������� ��������� �������

  /* ���������� ������ �������� ����� */
  procedure NODE
  (
    SNAME                   varchar2              -- ��� �����
  )
  as
  begin
    /* ��������� ����� */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* ��������� � */
    PKG_XMLFAST.NODE;
  end NODE;
  
  /* ���������� ����� �� ��������� (������) */
  procedure NODE
  (
    SNAME                   varchar2,             -- ��� �����
    SVALUE                  varchar2              -- �������� ����� (������)
  )
  as
  begin
    /* ��������� ����� */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* ��������� � */
    PKG_XMLFAST.NODE;
    /* ���������� �������� */
    PKG_XMLFAST.VALUE(SVALUE => SVALUE);
    /* ��������� ����� */
    PKG_XMLFAST.UP;
  end NODE;  

  /* ���������� ����� �� ��������� (�����) */
  procedure NODE
  (
    SNAME                   varchar2,             -- ��� �����
    NVALUE                  number                -- �������� ����� (�����)
  )
  as
  begin
    /* ��������� ����� */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* ��������� � */
    PKG_XMLFAST.NODE;
    /* ���������� �������� */
    PKG_XMLFAST.VALUE(NVALUE => NVALUE);
    /* ��������� ����� */
    PKG_XMLFAST.UP;
  end NODE;  

  /* ���������� ����� �� ��������� (����) */
  procedure NODE
  (
    SNAME                   varchar2,             -- ��� �����
    DVALUE                  date                  -- �������� ����� (����)
  )
  as
  begin
    /* ��������� ����� */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* ��������� � */
    PKG_XMLFAST.NODE;
    /* ���������� �������� */
    PKG_XMLFAST.VALUE(DVALUE => DVALUE);
    /* ��������� ����� */
    PKG_XMLFAST.UP;
  end NODE;  

begin
  /* �������� ������� ��������� */
  UDO_P_FISCDOCS_EXISTS(NRN => NFISCDOC, NCOMPANY => NCOMPANY, NCRN => NTMP_RN, NJUR_PERS => NTMP_RN);
  /* ��������� ������ ���������� � ��� �������, ����� ������� ����� ���������� ��������� */
  REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 0,
                                       NRN         => UDO_PKG_EXS_ATOL.UTL_FISCDOC_GET_EXSFN_REG(NFISCDOC => NFISCDOC));
  /* �������� ���� ��������� ������� */
  BTEST_SRV := UDO_PKG_EXS_ATOL.UTL_EXSSERVICE_IS_TEST(NEXSSERVICE => REXSSERVICEFN.PRN);
  /* �������������� ������ ��������� ��� �������� */
  PKG_XMLFAST.PROLOGUE(NENCODING   => PKG_XMLFAST.ENCODING_UTF8_,
                       NSTANDALONE => PKG_XMLFAST.STANDALONE_YES_,
                       BALINE      => true);
  /* ��������� ������ XML ��������� */
  NODE(SNAME => 'FISCDOC');
  /* ��������� ���� ��� ������� � ������ ����������� ��������� */
  for D in (select T.*
              from UDO_FISCDOCS T
             where T.RN = NFISCDOC
               and T.COMPANY = NCOMPANY)
  loop
    /* ������ ��������� ����������� ��������� */
    NODE(SNAME => 'NRN', NVALUE => D.RN);
    NODE(SNAME => 'DDOC_DATE', DVALUE => D.DOC_DATE);
    NODE(SNAME => 'SDDOC_DATE', SVALUE => TO_CHAR(D.DOC_DATE, 'dd.mm.yyyy hh24:mi:ss'));
    /* ������ ������� ����������� ��������� */
    NODE('FISCDOC_PROPS');
    for SP in (select A.CODE SCODE,
                      A.NAME SNAME,
                      UDO_GET_FISCDOCSPROP_VALUE(T.RN) SVALUE,
                      T.VAL_STR SVAL_STR,
                      T.VAL_NUMB NVAL_NUMB,
                      T.VAL_DATE DVAL_DATE,
                      T.VAL_DATETIME DVAL_DATETIME
                 from UDO_FISCDOCSPROP T,
                      UDO_FDKNDATT     P,
                      UDO_FISCDOCATT   A
                where T.PRN = D.RN
                  and T.PROP = P.RN
                  and P.ATTRIBUTE = A.RN)
    loop
      /* �������� ����������� ��������� */
      NODE(SNAME => 'FISCDOC_PROP');
      /* ��� ��������� ����� ��������� �������� ����� ������, ���� ��� �������� ������ */
      if (BTEST_SRV) then
        /* ��������� �������� ��� */
        if (SP.SCODE = '1018') then
          SP.SVALUE   := UDO_PKG_EXS_ATOL.STEST_INN;
          SP.SVAL_STR := UDO_PKG_EXS_ATOL.STEST_INN;
        end if;
        /* ��������� �������� ����� �������� */
        if (SP.SCODE = '1187') then
          SP.SVALUE   := UDO_PKG_EXS_ATOL.STEST_ADDR;
          SP.SVAL_STR := UDO_PKG_EXS_ATOL.STEST_ADDR;
        end if;
      end if;
      /* ������ �������� ����������� ��������� */
      NODE(SNAME => 'SCODE', SVALUE => SP.SCODE);
      NODE(SNAME => 'SNAME', SVALUE => SP.SNAME);
      NODE(SNAME => 'VALUE', SVALUE => SP.SVALUE);
      NODE(SNAME => 'SVALUE', SVALUE => SP.SVAL_STR);
      NODE(SNAME => 'NVALUE', NVALUE => SP.NVAL_NUMB);
      NODE(SNAME => 'DVALUE', DVALUE => SP.DVAL_DATE);
      NODE(SNAME => 'DTVALUE', DVALUE => SP.DVAL_DATETIME);
      /* ��������� �������� ����������� ��������� */
      PKG_XMLFAST.UP;
    end loop;
    /* ��������� ������ ������� ����������� ��������� */
    PKG_XMLFAST.UP;
  end loop;
  /* ��������� �������� ��� XML-��������� */
  PKG_XMLFAST.UP;
  /* ������������ ������ XML-��������� */
  PKG_XMLFAST.EPILOGUE(LDATA => CDATA);
  /* ���������� �������������� �������� */
  PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => REXSSERVICEFN.RN,
                    BMSG          => CLOB2BLOB(LCDATA => CDATA, SCHARSET => 'UTF8'),
                    NLNK_COMPANY  => NCOMPANY,
                    NLNK_DOCUMENT => NFISCDOC,
                    SLNK_UNITCODE => 'UDO_FiscalDocuments',
                    NNEW_EXSQUEUE => NEXSQUEUE);
end;
/
