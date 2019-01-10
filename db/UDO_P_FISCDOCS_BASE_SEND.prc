create or replace procedure UDO_P_FISCDOCS_BASE_SEND
(
  NRN                       in number,                 -- Регистрационный номер
  NCOMPANY                  in number                  -- Организация
)
as
  NEXSQUEUE                 PKG_STD.TREF;              -- Регистрационный номер записи очереди обмена
  SPRC_NAME                 varchar2(60);              -- Наименование процедуры проверки значений
  PRMS                      PKG_CONTPRMLOC.TCONTAINER; -- Контейнер для параметров процедуры обработки
begin
  /* Проверка заполнения обязательных атрибутов */
  UDO_P_FISCDOCSPROP_CHECK_REQ(NCOMPANY => NCOMPANY, NPRN => NRN);

  /* Определение процедуры проверки значений */
  for REC in (select V.PKG_CHECK,
                     V.PRC_CHECK
                from UDO_FISCDOCS  T,
                     UDO_FDKNDVERS V
               where T.RN = NRN
                 and T.COMPANY = NCOMPANY
                 and T.TYPE_VERSION = V.RN)
  loop
    /* Наименование процедуры */
    SPRC_NAME := NULLIF(REC.PKG_CHECK || '.', '.') || REC.PRC_CHECK;
  end loop;

  /* Если есть заполнена процедура проверки */
  if (SPRC_NAME is not null) then
    /* Установка значений фиксированных входных параметров */
    PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS, SNAME => 'NRN', NVALUE => NRN, NIN_OUT => PKG_STD.IPARAM_TYPE_IN);
    PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS,
                           SNAME      => 'NCOMPANY',
                           NVALUE     => NCOMPANY,
                           NIN_OUT    => PKG_STD.IPARAM_TYPE_IN);
    /* Выполнение процедуры */
    begin
      PKG_SQL_CALL.EXECUTE_STORED(SSTORED_NAME => SPRC_NAME, RPARAM_CONTAINER => PRMS);
    exception
      when others then
        P_EXCEPTION(0,
                    'Ошибка выполнения процедуры "%s".' || CR || 'Текст ошибки: %s',
                    SPRC_NAME,
                    sqlerrm);
    end;
  end if;

  /* Формирование и отправка сообщения для АТОЛ-Онлайн */
  UDO_P_FISCDOCS_MAKE_MSG_ATOL(NCOMPANY => NCOMPANY, NFISCDOC => NRN, NEXSQUEUE => NEXSQUEUE);

  /* Создание связи между чеком и очередью обмена */
  PKG_DOCLINKS.LINK(NFLAG_SMART   => 0,
                    NCOMPANY      => NCOMPANY,
                    SIN_UNITCODE  => 'UDO_FiscalDocuments',
                    NIN_DOCUMENT  => NRN,
                    SOUT_UNITCODE => 'EXSQueue',
                    NOUT_DOCUMENT => NEXSQUEUE);

  /* Изменение статуса */
  UDO_P_FISCDOCS_BASE_SET_STATUS(NRN => NRN, NCOMPANY => NCOMPANY, NSTATUS => 1);

  /* Установка даты и времени отправки */
  update UDO_FISCDOCS
     set SEND_TIME = sysdate
   where RN = NRN
     and COMPANY = NCOMPANY;

  if (sql%notfound) then
    PKG_MSG.RECORD_NOT_FOUND(NDOCUMENT => NRN, SUNIT_TABLE => 'UDO_FiscalDocuments');
  end if;
end;
/
