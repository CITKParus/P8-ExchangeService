create or replace procedure P_EXSQUEUE_BASE_REPEAT
(
  NRN                       in number     -- ��������������� �����
)
as
  NRN_NEW                   PKG_STD.TREF; -- ��������������� ����� ������������ ���������
begin
  /* ����� ������ */
  for REC in (select T.*,
                     S.SRV_TYPE
                from EXSQUEUE     T,
                     EXSSERVICEFN F,
                     EXSSERVICE   S
               where T.RN = NRN
                 and T.EXSSERVICEFN = F.RN
                 and F.PRN = S.RN)
  loop
    /* ���� ��� �� �������� ��������� */
    if (REC.SRV_TYPE != PKG_EXS.NSRV_TYPE_SEND) then
      P_EXCEPTION(0,
                  '��������� �������� ����� ������ ��� ���������� ���������.');
    end if;
    /* ��������� ��������� ������ � ������� */
    PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => REC.EXSSERVICEFN,
                      BMSG          => REC.MSG_ORIGINAL,
                      NEXSQUEUE     => REC.RN,
                      NLNK_COMPANY  => REC.LNK_COMPANY,
                      NLNK_DOCUMENT => REC.LNK_DOCUMENT,
                      SLNK_UNITCODE => REC.LNK_UNITCODE,
                      SOPTIONS      => REC.OPTIONS,
                      NNEW_EXSQUEUE => NRN_NEW);
  end loop;
end;
/
