create or replace package UDO_PKG_EXS_ATOL as

  /* Отработка ответов АТОЛ (v4) на регистрацию чека на приход, расход, возврат (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* Отработка ответов АТОЛ (v4) на регистрацию чека на приход, расход, возврат (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для хранения данных ответа сервера
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Проверим что позиция очереди корректна */
    if (REXSQUEUE.LNK_DOCUMENT is null) then
      P_EXCEPTION(0, 'Для позиции очереди не указан связанный документ.');
    end if;
    if (REXSQUEUE.LNK_UNITCODE is null) then
      P_EXCEPTION(0, 'Для позиции очереди не указан связанный раздел.');
    end if;
    if (REXSQUEUE.LNK_UNITCODE <> 'UDO_FiscalDocuments') then
      P_EXCEPTION(0,
                  'Связанный раздел "%s", указанный в позиции очереди, не поддерживается.',
                  REXSQUEUE.LNK_UNITCODE);
    end if;
    /* Разбираем ответ */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    if (CTMP is null) then
      P_EXCEPTION(0, 'Нет ответа от сервера.');
    end if;
    /* Выставляем идентификатор АТОЛ в ФД */
    update UDO_FISCDOCS T set T.NUMB_FD = CTMP where T.RN = REXSQUEUE.LNK_DOCUMENT;
    /* Всё прошло успешно */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end V4_FFD105_PROCESS_REG_BILL_SIR;

end;
/
