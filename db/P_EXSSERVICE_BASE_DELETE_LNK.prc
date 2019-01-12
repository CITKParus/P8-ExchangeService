create or replace procedure P_EXSSERVICE_BASE_DELETE_LNK
(
  NRN                       in number,          -- Регистрационный номер
  NDLT_LINK_SIGN            in number           -- Удалить связанные записи журнала работы сервиса интеграции и очереди обмена
)
as
begin
  /* Удаление связанных записей очереди обмена */
  for REC in (select T.RN
                from EXSQUEUE T
               where T.EXSSERVICEFN in (select T1.RN from EXSSERVICEFN T1 where T1.PRN = NRN)
                 and NDLT_LINK_SIGN = 1)
  loop
    /* Проверка на существование записи */
    for REC_CHECK in (select 1 from EXSQUEUE T1 where T1.RN = REC.RN)
    loop
      /* Базовое удаление с зависимостями */
      P_EXSQUEUE_BASE_DELETE_LNK(NRN => REC.RN, NDLT_LINK_SIGN => NDLT_LINK_SIGN);
    end loop;
  end loop;

  /* Удаление связанных записей журнала работы */
  for REC in (select T.RN
                from EXSLOG T
               where T.EXSSERVICE = NRN
                 and NDLT_LINK_SIGN = 1)
  loop
    P_EXSLOG_BASE_DELETE(NRN => REC.RN);
  end loop;

  /* Удаление функций с зависимостями */
  for REC in (select T.RN from EXSSERVICEFN T where T.PRN = NRN)
  loop
    P_EXSSERVICEFN_BASE_DELETE_LNK(NRN => REC.RN, NDLT_LINK_SIGN => NDLT_LINK_SIGN);
  end loop;

  /* Базовое удаление */
  P_EXSSERVICE_BASE_DELETE(NRN => NRN);
end;
/
