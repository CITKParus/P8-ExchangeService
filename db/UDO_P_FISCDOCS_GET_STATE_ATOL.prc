create or replace procedure UDO_P_FISCDOCS_GET_STATE_ATOL
as
  NEXSQUEUE                 PKG_STD.TREF; -- Регистрационный номер добавленной позиции очереди обмена
begin
  /* Обходим фискальные документы, успешно отправленные в АТОЛ, но по которым ещё нет проставленного статуса */
  for C in (select T.COMPANY,
                   T.RN,
                   Q.RESP BUUID
              from UDO_FISCDOCS T,
                   EXSQUEUE     Q
             where ((T.SEND_ERROR is null) and (T.CONFIRM_DATE is null))
               and Q.LNK_COMPANY = T.COMPANY
               and Q.LNK_UNITCODE = 'UDO_FiscalDocuments'
               and Q.LNK_DOCUMENT = T.RN
               and Q.EXEC_STATE = PKG_EXS.NQUEUE_EXEC_STATE_OK
               and Q.EXSSERVICEFN = UDO_PKG_EXS_ATOL.UTL_FISCDOC_GET_REG_EXSFN(T.RN))
  loop
    /* Ставим запрос на получение статуса документа в очередь */
    PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => UDO_PKG_EXS_ATOL.UTL_FISCDOC_GET_INF_EXSFN(NFISCDOC => C.RN),
                      BMSG          => C.BUUID,
                      NLNK_COMPANY  => C.COMPANY,
                      NLNK_DOCUMENT => C.RN,
                      SLNK_UNITCODE => 'UDO_FiscalDocuments',
                      NNEW_EXSQUEUE => NEXSQUEUE);
  end loop;
end;
/
