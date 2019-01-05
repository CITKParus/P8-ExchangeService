create or replace procedure P_EXSSERVICEFN_BASE_CHECK
(
  SMODE                     in varchar2,              -- ��� �������� ('I' - ����������, 'U' - �����������, 'D' - ��������)
  REXSSERVICEFN             in EXSSERVICEFN%rowtype   -- ������ ������� ������� ������
)
as
  /* ��������� �������� ��������, ������� ������� �� ���� ������� ������*/
  procedure CHECK_SRV_TYPE
  (
    NPRN                    in number,                -- ��������������� ����� ������� ������
    NRETRY_SCHEDULE         in number,                -- ���������� ���������� ����������
    NRETRY_STEP             in number,                -- ��� ���������� ���������� ����������
    NRETRY_ATTEMPTS         in number                 -- ���������� ������� ���������� ����������
  )
  as
    NSRV_TYPE               EXSSERVICE.SRV_TYPE%type; -- ��� ������� ������
  begin
    /* ����������� ���� ������ ������ */
    begin
      select SRV_TYPE into NSRV_TYPE from EXSSERVICE where RN = NPRN;
    exception
      when NO_DATA_FOUND then
        PKG_MSG.RECORD_NOT_FOUND(NDOCUMENT => NPRN, SUNIT_TABLE => 'EXSService');
    end;
    /* ���� ��� ������� ������ "��������� ���������" */
    if (NSRV_TYPE = 1) then
      /* �������� ���������� ���������� ���������� */
      if (NRETRY_SCHEDULE != 0) then
        P_EXCEPTION(0,
                    '������������ �������� ���������� ���������� ���������� ������� ������� ������.');
      end if;
      /* �������� ���� ���������� ���������� ���������� */
      if (NRETRY_STEP != 0) then
        P_EXCEPTION(0,
                    '������������ �������� ���� ���������� ���������� ���������� ������� ������� ������.');
      end if;
      /* �������� ���������� ������� ���������� ���������� */
      if (NRETRY_ATTEMPTS != 0) then
        P_EXCEPTION(0,
                    '������������ �������� ���������� ������� ���������� ���������� ������� ������� ������.');
      end if;
    end if;
  end CHECK_SRV_TYPE;

  /* ��������� �������� ��������, ������� ������� �� ���������� ���������� ���������� ������� ������� ������ */
  procedure CHECK_RETRY_SCHEDULE
  (
    NRETRY_SCHEDULE         in number,                -- ���������� ���������� ����������
    NRETRY_STEP             in number,                -- ��� ���������� ���������� ����������
    NRETRY_ATTEMPTS         in number                 -- ���������� ������� ���������� ����������
  )
  as
  begin
    /* ���� ���������� ���������� ���������� �� ���������� */
    if (NRETRY_SCHEDULE = 0) then
      /* �������� ���� ���������� ���������� ���������� */
      if (NRETRY_STEP != 0) then
        P_EXCEPTION(0,
                    '������������ �������� ���� ���������� ���������� ���������� ������� ������� ������.');
      end if;
      /* �������� ���������� ������� ���������� ���������� */
      if (NRETRY_ATTEMPTS != 0) then
        P_EXCEPTION(0,
                    '������������ �������� ���������� ������� ���������� ���������� ������� ������� ������.');
      end if;
    end if;
  end CHECK_RETRY_SCHEDULE;

  /* �������� ������� ���� "������ ������" � "���������� ������" */
  procedure CHECK_FN_TYPE
  (
    NRN                     in number,                -- ��������������� ����� ����������� ������
    NPRN                    in number,                -- ��������������� ����� ������� ������
    NFN_TYPE                in number                 -- ������� �������
  )
  as
    REXSSERVICEFN           EXSSERVICEFN%rowtype;     -- ������� ������   
    NCOUNT                  PKG_STD.TNUMBER;          -- ���������� ��������� �������
  begin
    /* ������� ������� ������ */
    REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 1, NRN => NRN);
    /* ���� ������� ������� "������ ������" ��� "���������� ������" */
    if (NFN_TYPE in (1, 2)) then
      /* ����������� ���������� ������� */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and FN_TYPE = NFN_TYPE
         and ((NRN is null) or ((NRN is not null) and (RN <> NRN)));
      /* ���� ���� ������ � ����� �� ������� �������� */
      if (NCOUNT > 0) then
        P_EXCEPTION(0,
                    '������ �� ����� ��������� ����� ����� ������� ������/���������� ������.');
      end if;
    end if;
    /* ���� ������ ������� ���� ������� ������, � ������ ��� */
    if ((REXSSERVICEFN.FN_TYPE = 1) and (NFN_TYPE <> 1)) then
      /* �������� �� ������������� ������� � ������������� ��������� "��������� ��������������" */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and AUTH_ONLY = 1
         and ((NRN is not null and RN != NRN) or (NRN is null));
      /* ���� ���� ������� � ������������� ��������� "��������� ��������������" */
      if (NCOUNT > 0) then
        P_EXCEPTION(0,
                    '��������� ���� ������� "������ �������" ����������, �.�. ������� ������� � ������������� ��������� "��������� ��������������".');
      end if;
    end if;
  end CHECK_FN_TYPE;

  /* �������� ���������� ������� ���������� */
  procedure CHECK_ACTIVE_APPSRV
  (
    SMODE                   in varchar2               -- ��� �������� ('I' - ����������, 'U' - �����������, 'D' - ��������)
  )
  as
    SACTION                 PKG_STD.TSTRING;          -- ������������ ��������
  begin
    /* ���� ������ ���������� ������� - �� ��������� ����������, �����������, �������� ������� ������� ������ */
    if (PKG_EXS.UTL_APPSRV_IS_ACTIVE) then
      /* ��� �������� */
      case SMODE
        /* ���������� */
        when 'I' then
          SACTION := '����������';
        /* ����������� */
        when 'U' then
          SACTION := '�����������';
        /* �������� */
        when 'D' then
          SACTION := '��������';
        /* ����� */
        else
          return;
      end case;
      P_EXCEPTION(0,
                  '������ ���������� �������, ' || SACTION || ' ������� ������� ������ �����������.');
    end if;
  end CHECK_ACTIVE_APPSRV;

  /* �������� ������ ������� E-Mail ��� ����������� �� ������� ��������� */
  procedure CHECK_ERR_NTF_MAIL
  (
    SERR_NTF_MAIL           in varchar2               -- ������ ������� E-Mail ��� �����������
  )
  as
    SSEQSYMB                PKG_STD.TSTRING;          -- ������-����������� ��������� ������
    SREG_EXP_EMAIL          PKG_STD.TSTRING;          -- ����� ��� ����������� ���������
    NCOUNT_SEQSYMB          PKG_STD.TNUMBER;          -- ���������� ��������� ������� ������������� ������������ � ������ ������ ������� E-Mail
    NREG                    PKG_STD.TNUMBER;          -- ��������� ���������� REGEXP_LIKE
  begin
    /* ����������� �������-����������� ��������� ������ */
    SSEQSYMB := ',';
    /* ����������� ���������� ��������� ������� ������������� ������������ � ������ ������ ������� E-Mail */
    NCOUNT_SEQSYMB := LENGTH(SERR_NTF_MAIL) - LENGTH(replace(SERR_NTF_MAIL, SSEQSYMB));
    /* ����������� ����� */
    SREG_EXP_EMAIL := '^((([a-z0-9_-]+\.)*[a-z0-9_-]+@[a-z0-9_-]+(\.[a-z0-9_-]+)*\.[a-z]+)\' || SSEQSYMB || '?){' ||
                      TO_CHAR(NCOUNT_SEQSYMB + 1) || '}[a-z]*$';
    /* �������� ������ ������� */
    begin
      select 1 into NREG from DUAL where REGEXP_LIKE(LOWER(SERR_NTF_MAIL), SREG_EXP_EMAIL);
    exception
      when NO_DATA_FOUND then
        P_EXCEPTION(0,
                    '�������� ������ ���� "������ ������� E-Mail ��� ����������� �� ������� ���������".' || CR ||
                    '������: example@mail.ru' || CR ||
                    '��� �������� ���������� ������� ������� ������������ ������� � �������� ����������� (��� ��������).' || CR ||
                    '������: example@mail.ru' || SSEQSYMB || 'e-mail@gmail.com');
    end;
  end CHECK_ERR_NTF_MAIL;

  /* �������� �������� "��������� ��������������" */
  procedure CHECK_AUTH_ONLY
  (
    NRN                     in number,       -- ��������������� �����
    NPRN                    in number,       -- ��������������� ����� ������� ������
    NAUTH_ONLY              in number        -- ��������� ��������������
  )
  as
    NCOUNT                  PKG_STD.TNUMBER; -- ���������� ������� � ����� "������ ������"
  begin
    /* ���� ������ ������� */
    if (NAUTH_ONLY = 1) then
      /* �������� �� ������������� ������� � ����� "������ ������" */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and FN_TYPE = 1
         and ((NRN is not null and RN != NRN) or (NRN is null));
      /* ���� ��� ������� � ����� "������ ������" */
      if (NCOUNT < 1) then
        P_EXCEPTION(0,
                    '��� ��������� �������� "��������� ��������������" ���������� ������� � ����� "������ ������".');
      end if;
    end if;
  end CHECK_AUTH_ONLY;

  /* �������� �������� "��������� ��������������" ��� �������� */
  procedure CHECK_AUTH_ONLY_DELETE
  (
    NRN                     in number,       -- ��������������� �����
    NPRN                    in number,       -- ��������������� ����� ������� ������
    NFN_TYPE                in number        -- ������� �������
  )
  as
    NCOUNT                  PKG_STD.TNUMBER; -- ���������� ������� � ������������� ��������� "��������� ��������������"
  begin
    /* ���� ��������� ������� "������ ������" */
    if (NFN_TYPE = 1) then
      /* �������� �� ������������� ������� � ������������� ��������� "��������� ��������������" */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and AUTH_ONLY = 1
         and ((NRN is not null and RN != NRN) or (NRN is null));
      /* ���� ���� ������� � ������������� ��������� "��������� ��������������" */
      if (NCOUNT > 0) then
        P_EXCEPTION(0,
                    '�������� ������� � ����� "������ �������" ����������, �.�. ������� ������� � ������������� ��������� "��������� ��������������".');
      end if;
    end if;
  end CHECK_AUTH_ONLY_DELETE;

begin
  /* �������� ���������� ������� ���������� */
  CHECK_ACTIVE_APPSRV(SMODE => SMODE);
  /* ��� �������� */
  case SMODE
    /* ���������� */
    when 'I' then
      /* �������� �������� ������� ������� ������ */
      CHECK_SRV_TYPE(NPRN            => REXSSERVICEFN.PRN,
                     NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                     NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                     NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_RETRY_SCHEDULE(NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                           NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                           NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_FN_TYPE(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NFN_TYPE => REXSSERVICEFN.FN_TYPE);
      if (REXSSERVICEFN.ERR_NTF_MAIL is not null) then
        CHECK_ERR_NTF_MAIL(SERR_NTF_MAIL => REXSSERVICEFN.ERR_NTF_MAIL);
      end if;
      CHECK_AUTH_ONLY(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NAUTH_ONLY => REXSSERVICEFN.AUTH_ONLY);
    /* ����������� */
    when 'U' then
      /* �������� �������� ������� ������� ������ */
      CHECK_SRV_TYPE(NPRN            => REXSSERVICEFN.PRN,
                     NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                     NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                     NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_RETRY_SCHEDULE(NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                           NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                           NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_FN_TYPE(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NFN_TYPE => REXSSERVICEFN.FN_TYPE);
      if (REXSSERVICEFN.ERR_NTF_MAIL is not null) then
        CHECK_ERR_NTF_MAIL(SERR_NTF_MAIL => REXSSERVICEFN.ERR_NTF_MAIL);
      end if;
      CHECK_AUTH_ONLY(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NAUTH_ONLY => REXSSERVICEFN.AUTH_ONLY);
    /* �������� */
    when 'D' then
      /* �������� �������� ������� ������� ������ */
      CHECK_AUTH_ONLY_DELETE(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NFN_TYPE => REXSSERVICEFN.FN_TYPE);
    else
      P_EXCEPTION(0, '��� �������� ��������� �������.');
  end case;
end;
/
