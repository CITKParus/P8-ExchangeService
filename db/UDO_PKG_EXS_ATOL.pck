create or replace package UDO_PKG_EXS_ATOL as

  /* Константы - типы функций обработки */
  SFN_TYPE_REG_BILL         constant varchar2(20) := 'REG_BILL';     -- Типовая функция регистрации чека
  SFN_TYPE_GET_BILL_INF     constant varchar2(20) := 'GET_BILL_INF'; -- Типовая функция получения иформации о регистрации чека

  /* Получение рег. номера функции сервиса обмена для регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_REG_EXSFN
  (
    NFISCDOC                in number   -- Рег. номер фискального документа
  ) return                  number;     -- Рег. номер функции регистрации чека в сервисе АТОЛ-Онлайн

  /* Получение рег. номера функции сервиса обмена для запроса информации о регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_INF_EXSFN
  (
    NFISCDOC                in number   -- Рег. номер фискального документа
  ) return                  number;     -- Рег. номер функции запроса информации о регистрации чека в сервисе АТОЛ-Онлайн    
  
  /* Отработка ответов АТОЛ (v4) на регистрацию чека на приход, расход, возврат (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Отработка ответов АТОЛ (v4) на запрос сведений о зарегистрированном документе (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_GET_BILL_INF
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_ATOL as

  /* Константы - состояния документа в АТОЛ */
  SSTATUS_DONE              constant varchar2(10) := 'done'; -- Готово
  SSTATUS_FAIL              constant varchar2(10) := 'fail'; -- Ошибка
  SSTATUS_WAIT              constant varchar2(10) := 'wait'; -- Ожидание
  
  /* Шаблон URL для чека ОФД */
  SBILL_OFD_UTL             constant varchar2(80) := 'https://ofd.ru/rec/<1041>/<1040>/<1077>?format=pdf';

  /* Проверка корректности атрибутов позиции очереди */
  procedure UTL_EXSQUEUE_CHECK_ATTRS
  (
    REXSQUEUE               in EXSQUEUE%rowtype -- Проверяемая запись позиции очереди
  )
  is
  begin
    /* Должна быть организация */
    if (REXSQUEUE.LNK_COMPANY is null) then
      P_EXCEPTION(0, 'Для позиции очереди не указана связанная организация.');
    end if;
    /* Должна быть связь с документом */
    if (REXSQUEUE.LNK_DOCUMENT is null) then
      P_EXCEPTION(0, 'Для позиции очереди не указан связанный документ.');
    end if;
    /* Должна быть связь с разделом */
    if (REXSQUEUE.LNK_UNITCODE is null) then
      P_EXCEPTION(0, 'Для позиции очереди не указан связанный раздел.');
    end if;
    /* Должна быть связь именно с разделом "Фискальные документы" */    
    if (REXSQUEUE.LNK_UNITCODE <> 'UDO_FiscalDocuments') then
      P_EXCEPTION(0,
                  'Связанный раздел "%s", указанный в позиции очереди, не поддерживается.',
                  REXSQUEUE.LNK_UNITCODE);
    end if;
  end UTL_EXSQUEUE_CHECK_ATTRS;
  
  /* Считывание записи фискального документа */
  function UTL_FISCDOC_GET
  (
    NFISCDOC                in number               -- Рег. номер фискального документа
  ) return                  UDO_V_FISCDOCS%rowtype  -- Найденная запись фискального документа
  is
    RRES                    UDO_V_FISCDOCS%rowtype; -- Буфер для результата
  begin
    /* Считаем запись */
    select T.* into RRES from UDO_V_FISCDOCS T where T.NRN = NFISCDOC;
    /* Вернём результат */
    return RRES;
  exception
    when NO_DATA_FOUND then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NFISCDOC, SUNIT_TABLE => 'UDO_FISCDOCS');
  end UTL_FISCDOC_GET;
  
  /* Получение мнемокода сервиса обмена и мнемокода его функции по типу функции обработки и версии ФФД */
  procedure UTL_FISCDOC_GET_EXSFN_BY_FFD
  (
    SFN_TYPE                in varchar2, -- Тип функции обработки (см. константы SFN_TYPE_*)
    SFFD_VERSION            in varchar2, -- Версия ФФД    
    SEXSSERVICE             out varchar2, -- Код сервиса-обработчика
    SEXSSERVICEFN           out varchar2 -- Код функции-обработчика    
  )
  is
  begin
    /* Работаем от типовой функции */
    case SFN_TYPE
      /* Регистрация чека */
      when SFN_TYPE_REG_BILL then
        begin
          /* Выбираем API обмена в зависимости от версии фискального документа */
          case SFFD_VERSION
            /* ФФД 1.05 */
            when '1.05' then
              begin
                SEXSSERVICE   := 'АТОЛ_V4_ИСХ';
                SEXSSERVICEFN := 'V4_ФФД1.05_РегистрацияЧекаРПВ';
              end;
            /* Неизвестная версия ФФД */
            else
              begin
                P_EXCEPTION(0,
                            'Версия фискального документа "%s" не поддерживается!',
                            SFFD_VERSION);
              end;
          end case;
        end;
      /* Получение иформации о регистрации чека */
      when SFN_TYPE_GET_BILL_INF then
        begin
          /* Выбираем API обмена в зависимости от версии фискального документа */
          case SFFD_VERSION
            /* ФФД 1.05 */
            when '1.05' then
              begin
                SEXSSERVICE   := 'АТОЛ_V4_ИСХ';
                SEXSSERVICEFN := 'V4_ФФД1.05_РезОбрабЧека';
              end;
            /* Неизвестная версия ФФД */
            else
              begin
                P_EXCEPTION(0,
                            'Версия фискального документа "%s" не поддерживается!',
                            SFFD_VERSION);
              end;
          end case;
        end;
      /* Неизвестная типовая функция */
      else
        begin
          P_EXCEPTION(0, 'Типовая функция "%s" не поддерживается!', SFN_TYPE);
        end;
    end case;
  end UTL_FISCDOC_GET_EXSFN_BY_FFD;
  
  /* Получение рег. номера функции сервиса обмена для регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_REG_EXSFN
  (
    NFISCDOC                in number               -- Рег. номер фискального документа
  ) return                  number                  -- Рег. номер функции регистрации чека в сервисе АТОЛ-Онлайн
  is
    NRES                    PKG_STD.TREF;           -- Буфер для результата
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- Запись фискального документа
    NEXSSERVICE             EXSSERVICEFN.RN%type;   -- Рег. номер сервиса-обработчика
    SEXSSERVICE             EXSSERVICEFN.CODE%type; -- Код сервиса-обработчика
    SEXSSERVICEFN           EXSSERVICEFN.CODE%type; -- Код функции-обработчика    
  begin
    /* Считаем запись фискального документа */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => NFISCDOC);
    /* Определим мнемокоды сервиса и функции для обработки */
    UTL_FISCDOC_GET_EXSFN_BY_FFD(SFN_TYPE      => SFN_TYPE_REG_BILL,
                                 SFFD_VERSION  => RFISCDOC.STYPE_VERSION,
                                 SEXSSERVICE   => SEXSSERVICE,
                                 SEXSSERVICEFN => SEXSSERVICEFN);
    /* Находим рег. номер сервиса */
    FIND_EXSSERVICE_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICE, NRN => NEXSSERVICE);
    /* Находим рег. номер функции сервиса */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART  => 0,
                           NFLAG_OPTION => 0,
                           NEXSSERVICE  => NEXSSERVICE,
                           SCODE        => SEXSSERVICEFN,
                           NRN          => NRES);
    /* Вернём результат */
    return NRES;
  end UTL_FISCDOC_GET_REG_EXSFN;
  
  /* Получение рег. номера функции сервиса обмена для запроса информации о регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_INF_EXSFN
  (
    NFISCDOC                in number               -- Рег. номер фискального документа
  ) return                  number                  -- Рег. номер функции запроса информации о регистрации чека в сервисе АТОЛ-Онлайн
  is
    NRES                    PKG_STD.TREF;           -- Буфер для результата
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- Запись фискального документа
    NEXSSERVICE             EXSSERVICEFN.RN%type;   -- Рег. номер сервиса-обработчика
    SEXSSERVICE             EXSSERVICEFN.CODE%type; -- Код сервиса-обработчика
    SEXSSERVICEFN           EXSSERVICEFN.CODE%type; -- Код функции-обработчика    
  begin
    /* Считаем запись фискального документа */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => NFISCDOC);
    /* Определим мнемокоды сервиса и функции для обработки */
    UTL_FISCDOC_GET_EXSFN_BY_FFD(SFN_TYPE      => SFN_TYPE_GET_BILL_INF,
                                 SFFD_VERSION  => RFISCDOC.STYPE_VERSION,
                                 SEXSSERVICE   => SEXSSERVICE,
                                 SEXSSERVICEFN => SEXSSERVICEFN);
    /* Находим рег. номер сервиса */
    FIND_EXSSERVICE_CODE(NFLAG_SMART => 0, NFLAG_OPTION => 0, SCODE => SEXSSERVICE, NRN => NEXSSERVICE);
    /* Находим рег. номер функции сервиса */
    FIND_EXSSERVICEFN_CODE(NFLAG_SMART  => 0,
                           NFLAG_OPTION => 0,
                           NEXSSERVICE  => NEXSSERVICE,
                           SCODE        => SEXSSERVICEFN,
                           NRN          => NRES);
    /* Вернём результат */
    return NRES;
  end UTL_FISCDOC_GET_INF_EXSFN;     

  /* Отработка ответов АТОЛ (v4) на регистрацию чека на приход, расход, возврат (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,              -- Идентификатор процесса
    NEXSQUEUE               in number               -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;       -- Запись позиции очереди
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- Запись фискального документа
    CTMP                    clob;                   -- Буфер для хранения данных ответа сервера
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Проверим что позиция очереди корректна */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* Считаем запись фискального документа */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* Проверим, что он верного формата */
    if (RFISCDOC.STYPE_VERSION <> '1.05') then
      P_EXCEPTION(0,
                  'Версия формата фискального документа (%s) не поддерживается. Ожидаемая версия - 1.05.',
                  RFISCDOC.STYPE_VERSION);
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
  
  /* Отработка ответов АТОЛ (v4) на запрос сведений о зарегистрированном документе (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_GET_BILL_INF
  (
    NIDENT                  in number,              -- Идентификатор процесса
    NEXSQUEUE               in number               -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;       -- Запись позиции очереди
    RFISCDOC                UDO_V_FISCDOCS%rowtype; -- Запись фискального документа
    RDOC                    PKG_XPATH.TDOCUMENT;    -- Разобранный XML-документ
    RROOT_NODE              PKG_XPATH.TNODE;        -- Корневой тэг XML-документа
    SSTATUS                 PKG_STD.TSTRING;        -- Буфер для значения "Статус обработки документа"
    STIMESTAMP              PKG_STD.TSTRING;        -- Буфер для значения "Дата и время документа внешней системы" (строковое представление)
    DTIMESTAMP              PKG_STD.TLDATE;         -- Буфер для значения "Дата и время документа внешней системы"
    STAG1012                PKG_STD.TSTRING;        -- Буфер для значения "Дата и время документа из ФН" (тэг 1012)
    STAG1040                PKG_STD.TSTRING;        -- Буфер для значения "Фискальный номер документа" (тэг 1040)
    STAG1041                PKG_STD.TSTRING;        -- Буфер для значения "Номер ФН" (тэг 1041)
    STAG1077                PKG_STD.TSTRING;        -- Буфер для значения "Фискальный признак документа" (тэг 1077)
    SERR_CODE               PKG_STD.TSTRING;        -- Буфер для значения "Код ошибки"
    SERR_TEXT               PKG_STD.TSTRING;        -- Буфер для значения "Текст ошибки"
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Проверим что позиция очереди корректна */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* Считаем запись фискального документа */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* Проверим, что он верного формата */
    if (RFISCDOC.STYPE_VERSION <> '1.05') then
      P_EXCEPTION(0,
                  'Версия формата фискального документа (%s) не поддерживается. Ожидаемая версия - 1.05.',
                  RFISCDOC.STYPE_VERSION);
    end if;
    /* Разбираем ответ */
    begin
      RDOC := PKG_XPATH.PARSE_FROM_BLOB(LBXML => REXSQUEUE.RESP, SCHARSET => 'UTF8');
    exception
      when others then
        P_EXCEPTION(0, 'Ошибка разбора XML - неожиданный ответ сервера.');
    end;
    /* Находим корневой элемент */
    RROOT_NODE := PKG_XPATH.ROOT_NODE(RDOCUMENT => RDOC);
    /* Забираем значения документа */
    SSTATUS    := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/STATUS'));
    STIMESTAMP := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/TIMESTAMP'));
    STAG1012   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1012'));
    STAG1040   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1040'));
    STAG1041   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1041'));
    STAG1077   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1077'));
    SERR_CODE  := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/ERROR/CODE'));
    SERR_TEXT  := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/ERROR/TEXT'));
    /* Освобождаем память */
    PKG_XPATH.FREE(RDOCUMENT => RDOC);
    /* Проверим, что указан статус документа */
    if (SSTATUS is null) then
      P_EXCEPTION(0, 'Не указан статус обработки документа.');
    end if;
    /* Обрабатываем ответ в зависимости от статуса */
    case SSTATUS
      /* Обрабатывается */
      when SSTATUS_WAIT then
        begin
          /* Документ ещё не обработан, ожидаем результатов, поэтому пока ничего не делаем */
          null;
        end;
      /* Готов */
      when SSTATUS_DONE then
        begin
          /* Проверим наличие данных в тэгах и дату ответа АТОЛ */
          if (STIMESTAMP is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Дата и время документа внешней системы".',
                        SSTATUS);
          end if;
          if (STAG1040 is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Фискальный номер документа" (тэг 1040).',
                        SSTATUS);
          end if;
          if (STAG1041 is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Номер ФН" (тэг 1041).',
                        SSTATUS);
          end if;
          if (STAG1077 is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Фискальный признак документа" (тэг 1077).',
                        SSTATUS);
          end if;
          /* Проверяем корректность даты подтверждения */
          begin
            DTIMESTAMP := TO_DATE(STIMESTAMP, 'dd.mm.yyyy hh24:mi:ss');
          exception
            when others then
              P_EXCEPTION(0,
                          'Значение поля "Дата и время документа внешней системы" (%s) не является датой в формате "ДД.ММ.ГГГГ ЧЧ:МИ:CC"',
                          STIMESTAMP);
          end;
          /* Выставляем значение "Дата подтверждения" и "Ссылка на фискальный документ в ОФД" для фискального документа */
          update UDO_FISCDOCS T
             set T.CONFIRM_DATE = DTIMESTAMP,
                 T.DOC_URL      = replace(replace(replace(SBILL_OFD_UTL, '<1040>', STAG1040), '<1041>', STAG1041),
                                          '<1077>',
                                          STAG1077)
           where T.RN = RFISCDOC.NRN;
          /* Устанавливаем значения тэгов */
          begin
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.NRN,
                                       NCOMPANY   => RFISCDOC.NCOMPANY,
                                       SATTRIBUTE => '1040',
                                       NVAL_NUMB  => TO_NUMBER(STAG1040));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.NRN,
                                       NCOMPANY   => RFISCDOC.NCOMPANY,
                                       SATTRIBUTE => '1041',
                                       SVAL_STR   => STAG1041);
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.NRN,
                                       NCOMPANY   => RFISCDOC.NCOMPANY,
                                       SATTRIBUTE => '1077',
                                       SVAL_STR   => STAG1077);
          exception
            when others then
              P_EXCEPTION(0,
                          'Ошибка установки значения атрибута фискального документа: %s',
                          sqlerrm);
          end;
        end;
      /* Ошибка обработки */
      when SSTATUS_FAIL then
        begin
          /* Проверим, что пришли код и текст ошибки */
          if ((SERR_CODE is null) or (SERR_TEXT is null)) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указан код или текст ошибки.',
                        SSTATUS);
          end if;
          /* Выставим код и текст в фискальном документе */
          update UDO_FISCDOCS T
             set T.SEND_ERROR = SUBSTR(SERR_CODE || ': ' ||
                                       REGEXP_REPLACE(replace(SERR_TEXT, CHR(10), ''), '[[:space:]]+', ' '),
                                       1,
                                       4000)
           where T.RN = RFISCDOC.NRN;
        end;
      /* Неизвестный статус */
      else
        P_EXCEPTION(0, 'Cтатус докуента "%s" не поддерживается.', SSTATUS);
    end case;
    /* Всё прошло успешно */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end V4_FFD105_PROCESS_GET_BILL_INF;
  
end;
/
