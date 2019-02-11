create or replace procedure P_EXSSERVICEFN_FORM_EDIT
(
  NMODE                     in number,                -- ��� �������� (0 - ����������, 1 - �����������)
  NFIRST                    in out number,            -- ������� ������� ��������� (0 - ��������� ���������, 1 - ������ ���������)
  SATTRIB                   in varchar2,              -- ���������� �������
  NRN                       in number,                -- ��������������� ����� ������� ������� ������
  NPRN                      in number,                -- ��������������� ����� ������� ������
  NFN_TYPE                  in number,                -- ������� �������
  NRETRY_SCHEDULE           in out number,            -- ���������� ���������� ����������
  NRETRY_STEP               in out number,            -- ��� ���������� ���������� ����������
  NRETRY_ATTEMPTS           in out number,            -- ���������� ������� ���������� ����������
  NERR_NTF_SIGN             in out number,            -- ���������� �� ������� ���������
  SERR_NTF_MAIL             in out varchar2,          -- ������ ������� E-Mail ��� ����������� �� ������� ���������
  NAUTH_ONLY                in out number,            -- ��������� ��������������
  NE_RETRY_SCHEDULE         in out number,            -- ������� ����������� �������� "NRETRY_SCHEDULE" (���������� ���������� ����������)
  NE_RETRY_STEP             in out number,            -- ������� ����������� �������� "NRETRY_STEP" (��� ���������� ���������� ����������)
  NE_RETRY_ATTEMPTS         in out number,            -- ������� ����������� �������� "NRETRY_ATTEMPTS" (���������� ������� ���������� ����������)
  NE_ERR_NTF_MAIL           in out number,            -- ������� ����������� �������� "SERR_NTF_MAIL" (������ ������� E-Mail ��� ����������� �� ������� ���������)
  NE_AUTH_ONLY              in out number,            -- ������� ����������� �������� "NAUTH_ONLY" (��������� ��������������)
  NR_ERR_NTF_MAIL           in out number             -- ������� �������������� �������� "SERR_NTF_MAIL" (������ ������� E-Mail ��� ����������� �� ������� ���������)
)
as
  /* ��������� ����������� � �������� ���������, ������� ������� �� ���� ������� ������ */
  procedure SET_ENABLED_SRV_TYPE
  as
    NSRV_TYPE               EXSSERVICE.SRV_TYPE%type; -- ��� ������� ������
  begin
    /* ����������� ���� ������� ������ */
    begin
      select SRV_TYPE into NSRV_TYPE from EXSSERVICE where RN = NPRN;
    exception
      when NO_DATA_FOUND then
        PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NPRN, SUNIT_TABLE => 'EXSService');
    end;
    /* ���� ��� ������� ������ "��������� ���������" */
    if (NSRV_TYPE = 1) then
      NE_RETRY_SCHEDULE := 0;
      NE_RETRY_STEP     := 0;
      NE_RETRY_ATTEMPTS := 0;
      NRETRY_SCHEDULE   := 0;
      NRETRY_STEP       := 0;
      NRETRY_ATTEMPTS   := 0;
    else
      NE_RETRY_SCHEDULE := 1;
      NE_RETRY_STEP     := 1;
      NE_RETRY_ATTEMPTS := 1;
    end if;
  end SET_ENABLED_SRV_TYPE;

  /* ��������� ����������� � �������� ���������, ������� ������� �� ���������� ���������� ���������� ������� ������� ������ */
  procedure SET_ENABLED_RETRY_SCHEDULE
  as
  begin
    /* ���� ���������� ���������� ���������� �� ���������� */
    if (NRETRY_SCHEDULE = 0) then
      NE_RETRY_STEP     := 0;
      NE_RETRY_ATTEMPTS := 0;
      NRETRY_STEP       := 0;
      NRETRY_ATTEMPTS   := 0;
    else
      NE_RETRY_STEP     := 1;
      NE_RETRY_ATTEMPTS := 1;
    end if;
  end SET_ENABLED_RETRY_SCHEDULE;

  /* ��������� �����������, �������������� � �������� ���������, ������� ������� �� �������� "���������� �� ������� ���������" */
  procedure SET_ENABLED_ERR_NTF_SIGN
  as
  begin
    /* ���� �� ���������� ������� "���������� �� ������� ���������" */
    if (NERR_NTF_SIGN = 0) then
      NE_ERR_NTF_MAIL := 0;
      NR_ERR_NTF_MAIL := 0;
      SERR_NTF_MAIL   := null;
    else
      NE_ERR_NTF_MAIL := 1;
      NR_ERR_NTF_MAIL := 1;
      /* ���� �������� �� ������ */
      if (SERR_NTF_MAIL is null) then
        /* ����������� ������ ������� �� ��������� */
        begin
          select T.UNAVLBL_NTF_MAIL into SERR_NTF_MAIL from EXSSERVICE T where T.RN = NPRN;
        exception
          when NO_DATA_FOUND then
            PKG_MSG.RECORD_NOT_FOUND(NDOCUMENT => NPRN, SUNIT_TABLE => 'EXSService');
        end;
      end if;
    end if;
  end SET_ENABLED_ERR_NTF_SIGN;

  /* ��������� ����������� � �������� �������� "��������� ��������������" */
  procedure SET_ENABLED_AUTH_ONLY
  as
    NCOUNT                  PKG_STD.TNUMBER; -- ���������� ������� � ����� "������ ������"
  begin
    /* �������� �� ������������� ������� � ����� "������ ������" */
    select count(*)
      into NCOUNT
      from EXSSERVICEFN
     where PRN = NPRN
       and FN_TYPE = 1;
    /* ���� ���� ������� � ����� "������ ������" */
    if (NCOUNT > 0) then
      /* ���� ������� "����� �������" */
      if (NFN_TYPE = 0) then
        NE_AUTH_ONLY := 1;
      /* ���� ������� "������ ������" */
      elsif (NFN_TYPE = 1) then
        NAUTH_ONLY   := 0;
        NE_AUTH_ONLY := 0;
      /* ���� ������� "���������� ������" */
      elsif (NFN_TYPE = 2) then
        NAUTH_ONLY   := 1;
        NE_AUTH_ONLY := 0;
      end if;
    /* ���� ��� ������� � ����� "������ ������" */
    else
      NAUTH_ONLY   := 0;
      NE_AUTH_ONLY := 0;
    end if;
  end;

begin
  /* ���� ��� ������ ��������� */
  if (NFIRST = 1) then
    /* ��������� ����������� � �������� ��������� */
    SET_ENABLED_SRV_TYPE;
    SET_ENABLED_RETRY_SCHEDULE;
    SET_ENABLED_ERR_NTF_SIGN;
    SET_ENABLED_AUTH_ONLY;
  end if;

  /* ���� ���������� ������� "NRETRY_SCHEDULE" (���������� ���������� ����������) */
  if (SATTRIB = 'NRETRY_SCHEDULE') then
    /* ��������� ����������� � �������� ��������� */
    SET_ENABLED_RETRY_SCHEDULE;
  end if;

  /* ���� ���������� ������� "NERR_NTF_SIGN" (���������� �� ������� ���������) ��� ��� ������ ��������� */
  if (SATTRIB = 'NERR_NTF_SIGN') then
    /* ��������� �����������, �������������� � �������� ��������� */
    SET_ENABLED_ERR_NTF_SIGN;
  end if;

  /* ���� ���������� ������� "NFN_TYPE" (������� �������) */
  if (SATTRIB = 'NFN_TYPE') then
    /* ��������� ����������� � �������� �������� "��������� ��������������" */
    SET_ENABLED_AUTH_ONLY;
  end if;

  /* ��������� �������� ������� ��������� */
  NFIRST := 0;
end;
/
