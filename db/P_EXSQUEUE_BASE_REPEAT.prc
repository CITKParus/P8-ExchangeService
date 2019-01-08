create or replace procedure P_EXSQUEUE_BASE_REPEAT
(
  NRN                       in number     -- Регистрационный номер
)
as
  NRN_NEW                   PKG_STD.TREF; -- Регистрационный номер добавленного сообщения
begin
  /* Отбор записи */
  for REC in (select T.*,
                     S.SRV_TYPE
                from EXSQUEUE     T,
                     EXSSERVICEFN F,
                     EXSSERVICE   S
               where T.RN = NRN
                 and T.EXSSERVICEFN = F.RN
                 and F.PRN = S.RN)
  loop
    /* Если это не отправка сообщения */
    if (REC.SRV_TYPE != PKG_EXS.NSRV_TYPE_SEND) then
      P_EXCEPTION(0,
                  'Повторить отправку можно только для исходящего сообщения.');
    end if;
    /* Помещение сообщения обмена в очередь */
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
