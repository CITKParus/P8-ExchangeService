create or replace procedure UDO_P_FISCDOCS_BASE_SEND
(
  NRN                       in number,                 -- ��������������� �����
  NCOMPANY                  in number                  -- �����������
)
as
  NEXSQUEUE                 PKG_STD.TREF;              -- ��������������� ����� ������ ������� ������
  SPRC_NAME                 varchar2(60);              -- ������������ ��������� �������� ��������
  PRMS                      PKG_CONTPRMLOC.TCONTAINER; -- ��������� ��� ���������� ��������� ���������
begin
  /* �������� ���������� ������������ ��������� */
  UDO_P_FISCDOCSPROP_CHECK_REQ(NCOMPANY => NCOMPANY, NPRN => NRN);

  /* ����������� ��������� �������� �������� */
  for REC in (select V.PKG_CHECK,
                     V.PRC_CHECK
                from UDO_FISCDOCS  T,
                     UDO_FDKNDVERS V
               where T.RN = NRN
                 and T.COMPANY = NCOMPANY
                 and T.TYPE_VERSION = V.RN)
  loop
    /* ������������ ��������� */
    SPRC_NAME := NULLIF(REC.PKG_CHECK || '.', '.') || REC.PRC_CHECK;
  end loop;

  /* ���� ���� ��������� ��������� �������� */
  if (SPRC_NAME is not null) then
    /* ��������� �������� ������������� ������� ���������� */
    PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS, SNAME => 'NRN', NVALUE => NRN, NIN_OUT => PKG_STD.IPARAM_TYPE_IN);
    PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS,
                           SNAME      => 'NCOMPANY',
                           NVALUE     => NCOMPANY,
                           NIN_OUT    => PKG_STD.IPARAM_TYPE_IN);
    /* ���������� ��������� */
    begin
      PKG_SQL_CALL.EXECUTE_STORED(SSTORED_NAME => SPRC_NAME, RPARAM_CONTAINER => PRMS);
    exception
      when others then
        P_EXCEPTION(0,
                    '������ ���������� ��������� "%s".' || CR || '����� ������: %s',
                    SPRC_NAME,
                    sqlerrm);
    end;
  end if;

  /* ������������ � �������� ��������� ��� ����-������ */
  UDO_P_FISCDOCS_MAKE_MSG_ATOL(NCOMPANY => NCOMPANY, NFISCDOC => NRN, NEXSQUEUE => NEXSQUEUE);

  /* �������� ����� ����� ����� � �������� ������ */
  PKG_DOCLINKS.LINK(NFLAG_SMART   => 0,
                    NCOMPANY      => NCOMPANY,
                    SIN_UNITCODE  => 'UDO_FiscalDocuments',
                    NIN_DOCUMENT  => NRN,
                    SOUT_UNITCODE => 'EXSQueue',
                    NOUT_DOCUMENT => NEXSQUEUE);

  /* ��������� ������� */
  UDO_P_FISCDOCS_BASE_SET_STATUS(NRN => NRN, NCOMPANY => NCOMPANY, NSTATUS => 1);

  /* ��������� ���� � ������� �������� */
  update UDO_FISCDOCS
     set SEND_TIME = sysdate
   where RN = NRN
     and COMPANY = NCOMPANY;

  if (sql%notfound) then
    PKG_MSG.RECORD_NOT_FOUND(NDOCUMENT => NRN, SUNIT_TABLE => 'UDO_FiscalDocuments');
  end if;
end;
/
