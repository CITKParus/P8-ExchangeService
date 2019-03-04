create or replace package UDO_PKG_EXS_ATOL as

  /* Константы - тестовое окружение сервера АТОЛ-Онлайн */
  STEST_SRV_ROOT_PATTERN    constant varchar2(80) := '%testonline.atol.ru%';      -- Шаблон адреса тестового сервера
  STEST_INN                 constant varchar2(80) := '5544332219';                -- Тестовый ИНН
  STEST_ADDR                constant varchar2(80) := 'https://v4.online.atol.ru'; -- Тестовый адрес расчётов
  
  /* Константы - типы функций обработки */
  SFN_TYPE_REG_BILL         constant varchar2(20) := 'REG_BILL';     -- Типовая функция регистрации чека
  SFN_TYPE_GET_BILL_INF     constant varchar2(20) := 'GET_BILL_INF'; -- Типовая функция получения иформации о регистрации чека
  
  /* Константы - версии ФФД (строковые представления) */
  SFFD105                   constant varchar2(20) := '1.05'; -- Версия ФФД 1.05
  SFFD110                   constant varchar2(20) := '1.10'; -- Версия ФФД 1.10

  /* Константы - значения тэга "Номер версии ФФД" (1209) для версий формата */
  NTAG1209_FFD105           constant number(2) := 2; -- Значение тэга  1209 для версии ФФД 1.05
  NTAG1209_FFD110           constant number(2) := 3; -- Значение тэга  1209 для версии ФФД 1.10

  /* Проверка сервиса на то, что он является тестовым */
  function UTL_EXSSERVICE_IS_TEST
  (
    NEXSSERVICE             in number   -- Регистрационный номер сервиса обмена
  ) return                  boolean;    -- Признак тестового сервиса (true - тестовый, false - не тестовый)
  
  /* Получение рег. номера функции сервиса обмена для регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_EXSFN_REG
  (
    NFISCDOC                in number   -- Рег. номер фискального документа
  ) return                  number;     -- Рег. номер функции регистрации чека в сервисе АТОЛ-Онлайн

  /* Получение рег. номера функции сервиса обмена для запроса информации о регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_EXSFN_INF
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

  /* Отработка ответов ОФД на запрос чека */
  procedure OFD_PROCESS_GET_BILL_DOC
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
    NFISCDOC                in number             -- Рег. номер фискального документа
  ) return                  UDO_FISCDOCS%rowtype  -- Найденная запись фискального документа
  is
    RRES                    UDO_FISCDOCS%rowtype; -- Буфер для результата
  begin
    /* Считаем запись */
    select T.* into RRES from UDO_FISCDOCS T where T.RN = NFISCDOC;
    /* Вернём результат */
    return RRES;
  exception
    when NO_DATA_FOUND then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NFISCDOC, SUNIT_TABLE => 'UDO_FISCDOCS');
  end UTL_FISCDOC_GET;
  
  /* Получение постфикса сервиса обмена для фискального документа по его принадлежности к организации */
  function UTL_FISCDOC_GET_EXS_POSTFIX
  (
    NFISCDOC                in number            -- Рег. номер фискального документа
  ) return                  varchar2             -- Постфикс сервиса обмена
  is
    SRES                    COMPANIES.NAME%type; -- Результат работы
  begin
    /* Считаем постфик сервиса обмена (это наименование организации фискального документа) */
    select C.NAME
      into SRES
      from UDO_FISCDOCS  FD,
           COMPANIES C
     where FD.RN = NFISCDOC
       and FD.COMPANY = C.RN;
    /* Возвращаем результат */
    return SRES;
  exception
    when others then
      P_EXCEPTION(0, 
                  'Для фискального документа (RN: %s) не определен постфикс сервиса обмена.',
                  TO_CHAR(NFISCDOC));
  end UTL_FISCDOC_GET_EXS_POSTFIX;
  
  /* Получение мнемокода сервиса обмена и мнемокода его функции по типу функции обработки и версии ФФД */
  procedure UTL_FISCDOC_GET_EXSFN
  (
    NFISCDOC                in number,   -- Рег. номер фискального документа
    SFN_TYPE                in varchar2, -- Тип функции обработки (см. константы SFN_TYPE_*)
    NEXSSERVICEFN           out number   -- Рег. номер функции-обработчика    
  )
  is
    SEXSRV                  EXSSERVICE.CODE%type;   -- Мнемокод эталонного сервиса обмена из настроек фискального документа
    SEXSRVFN                EXSSERVICEFN.CODE%type; -- Мнемокод эталонной функции обмена из настроек фискального документа
  begin
    begin
      /* Находим мнемокод эталонной функции и сервиса из настроек фискального документа */
      select DECODE(SFN_TYPE, SFN_TYPE_REG_BILL, SREG.CODE, SFN_TYPE_GET_BILL_INF, SINF.CODE),
             DECODE(SFN_TYPE, SFN_TYPE_REG_BILL, SFNREG.CODE, SFN_TYPE_GET_BILL_INF, SFNINF.CODE)
        into SEXSRV,
             SEXSRVFN
        from UDO_FISCDOCS  FD,
             UDO_FDKNDVERS TV,
             EXSSERVICEFN  SFNREG,
             EXSSERVICEFN  SFNINF,
             EXSSERVICE    SREG,
             EXSSERVICE    SINF
       where FD.RN = NFISCDOC
         and FD.TYPE_VERSION = TV.RN
         and TV.FUNCTION_SEND = SFNREG.RN(+)
         and SFNREG.PRN = SREG.RN(+)
         and TV.FUNCTION_RESP = SFNINF.RN(+)
         and SFNINF.PRN = SINF.RN(+);
    exception
      when others then
        SEXSRV   := null;
        SEXSRVFN := null;
    end;
    /* Если найдены эталонные сервис обмена и функция - подбираем то что нужно по принадлености фискального документа к организации */
    if ((SEXSRV is not null) and (SEXSRVFN is not null)) then
      NEXSSERVICEFN := PKG_EXS.SERVICEFN_FIND_BY_SRVCODE(NFLAG_SMART => 0,
                                                         SEXSSERVICE => SEXSRV || '_' || UTL_FISCDOC_GET_EXS_POSTFIX(NFISCDOC => NFISCDOC),
                                                         SEXSSERVICEFN => SEXSRVFN);
    else
      /* Эталоны не найдены - значит невозможен подбор реальной функции */
      P_EXCEPTION(0,
                  'Для фискального документа (RN: %s) не определеная типовая функция "%s".',
                  TO_CHAR(NFISCDOC),
                  SFN_TYPE);
    end if;
  end UTL_FISCDOC_GET_EXSFN;
  
  /* Получение рег. номера функции сервиса обмена для регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_EXSFN_REG
  (
    NFISCDOC                in number     -- Рег. номер фискального документа
  ) return                  number        -- Рег. номер функции регистрации чека в сервисе АТОЛ-Онлайн
  is
    NRES                    PKG_STD.TREF; -- Буфер для результата
  begin
    /* Определим мнемокоды сервиса и функции для обработки */
    UTL_FISCDOC_GET_EXSFN(NFISCDOC => NFISCDOC, SFN_TYPE => SFN_TYPE_REG_BILL, NEXSSERVICEFN => NRES);
    /* Вернём результат */
    return NRES;
  end UTL_FISCDOC_GET_EXSFN_REG;
  
  /* Получение рег. номера функции сервиса обмена для запроса информации о регистрации чека по рег. номеру фискального документа */
  function UTL_FISCDOC_GET_EXSFN_INF
  (
    NFISCDOC                in number     -- Рег. номер фискального документа
  ) return                  number        -- Рег. номер функции запроса информации о регистрации чека в сервисе АТОЛ-Онлайн
  is
    NRES                    PKG_STD.TREF; -- Буфер для результата
  begin
    /* Определим мнемокоды сервиса и функции для обработки */
    UTL_FISCDOC_GET_EXSFN(NFISCDOC => NFISCDOC, SFN_TYPE => SFN_TYPE_GET_BILL_INF, NEXSSERVICEFN => NRES);
    /* Вернём результат */
    return NRES;
  end UTL_FISCDOC_GET_EXSFN_INF;

  /* Контроль версии ФФД */
  procedure UTL_FISCDOC_CHECK_FFD_VERS
  (
    NCOMPANY                in number,  -- Рег. номер организации
    NFISCDOC                in number,  -- Рег. номер фискального документа    
    NEXPECTED_VERS          in number,  -- Ожидаемая версия ФФД (по значению тэга 1209, см. констнаты NTAG1209_FFD*)
    SEXPECTED_VERS          in varchar2 -- Ожидаемая версия ФФД (строковое представление)
  )
  is
  begin
    /* Считаем тэг 1209 (в нем хранится номер версии ФФД) и сверим значения, фактическое и ожидаемое процедурой */
    if (UDO_F_FISCDOCS_GET_NUMB(NRN => NFISCDOC, NCOMPANY => NCOMPANY, SATTRIBUTE => '1209') != NEXPECTED_VERS) then
      P_EXCEPTION(0,
                  'Версия формата фискального документа (значение тэга 1209 - %s) не поддерживается. Ожидаемая версия - %s (значение тэга 1209 - %s).',
                  NVL(TO_CHAR(UDO_F_FISCDOCS_GET_NUMB(NRN => NFISCDOC, NCOMPANY => NCOMPANY, SATTRIBUTE => '1209')),
                      '<НЕ УКАЗАНО>'),
                  NVL(SEXPECTED_VERS, '<НЕ УКАЗАНА>'),
                  NVL(TO_CHAR(NEXPECTED_VERS), '<НЕ УКАЗАНО>'));
    end if;
  end UTL_FISCDOC_CHECK_FFD_VERS;
  
  /* Проверка сервиса на то, что он является тестовым */
  function UTL_EXSSERVICE_IS_TEST
  (
    NEXSSERVICE             in number           -- Регистрационный номер сервиса обмена
  ) return                  boolean             -- Признак тестового сервиса (true - тестовый, false - не тестовый)
  is
    REXSSERVICE             EXSSERVICE%rowtype; -- Запись сервиса обмена
  begin
    /* Считаем запись сервиса обмена */
    REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => NEXSSERVICE);
    /* Проверим его по адресу */
    if (REXSSERVICE.SRV_ROOT like STEST_SRV_ROOT_PATTERN) then
      return true;
    else
      return false;
    end if;
  end;

  /* Отработка ответов АТОЛ (v4) на регистрацию чека на приход, расход, возврат (ФФД 1.05) */
  procedure V4_FFD105_PROCESS_REG_BILL_SIR
  (
    NIDENT                  in number,            -- Идентификатор процесса
    NEXSQUEUE               in number             -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    RFISCDOC                UDO_FISCDOCS%rowtype; -- Запись фискального документа
    CTMP                    clob;                 -- Буфер для хранения данных ответа сервера
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Проверим что позиция очереди корректна */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* Считаем запись фискального документа */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* Проверим, что он верного формата */
    UTL_FISCDOC_CHECK_FFD_VERS(NCOMPANY       => RFISCDOC.COMPANY,
                               NFISCDOC       => RFISCDOC.RN,
                               NEXPECTED_VERS => NTAG1209_FFD105,
                               SEXPECTED_VERS => SFFD105);
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
    NIDENT                  in number,            -- Идентификатор процесса
    NEXSQUEUE               in number             -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;     -- Запись позиции очереди
    RFISCDOC                UDO_FISCDOCS%rowtype; -- Запись фискального документа
    RDOC                    PKG_XPATH.TDOCUMENT;  -- Разобранный XML-документ
    RROOT_NODE              PKG_XPATH.TNODE;      -- Корневой тэг XML-документа
    SSTATUS                 PKG_STD.TSTRING;      -- Буфер для значения "Статус обработки документа"
    STIMESTAMP              PKG_STD.TSTRING;      -- Буфер для значения "Дата и время документа внешней системы" (строковое представление)
    DTIMESTAMP              PKG_STD.TLDATE;       -- Буфер для значения "Дата и время документа внешней системы"
    STAG1012                PKG_STD.TSTRING;      -- Буфер для значения "Дата и время документа из ФН" (тэг 1012)
    STAG1038                PKG_STD.TSTRING;      -- Буфер для значения "Номер смены" (тэг 1038)
    STAG1040                PKG_STD.TSTRING;      -- Буфер для значения "Фискальный номер документа" (тэг 1040)
    STAG1041                PKG_STD.TSTRING;      -- Буфер для значения "Номер ФН" (тэг 1041)
    STAG1042                PKG_STD.TSTRING;      -- Буфер для значения "Номер чека в смене" (тэг 1042)
    STAG1077                PKG_STD.TSTRING;      -- Буфер для значения "Фискальный признак документа" (тэг 1077)
    SERR_CODE               PKG_STD.TSTRING;      -- Буфер для значения "Код ошибки"
    SERR_TEXT               PKG_STD.TSTRING;      -- Буфер для значения "Текст ошибки"
    NNEW_EXSQUEUE           PKG_STD.TREF;         -- Рег. номер записи очереди обмена (для скачивания готового чека)
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Проверим что позиция очереди корректна */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* Считаем запись фискального документа */
    RFISCDOC := UTL_FISCDOC_GET(NFISCDOC => REXSQUEUE.LNK_DOCUMENT);
    /* Проверим, что он верного формата */
    UTL_FISCDOC_CHECK_FFD_VERS(NCOMPANY       => RFISCDOC.COMPANY,
                               NFISCDOC       => RFISCDOC.RN,
                               NEXPECTED_VERS => NTAG1209_FFD105,
                               SEXPECTED_VERS => SFFD105);
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
    STAG1012   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1012'));
    STAG1038   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1038'));
    STAG1040   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1040'));
    STAG1041   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1041'));
    STAG1042   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1042'));
    STAG1077   := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE, SPATTERN => '/RESP/TAG1077'));
    STIMESTAMP := PKG_XPATH.VALUE(RNODE => PKG_XPATH.SINGLE_NODE(RPARENT_NODE => RROOT_NODE,
                                                                 SPATTERN     => '/RESP/TIMESTAMP'));
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
          if (STAG1012 is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Дата и время документа из ФН" (тэг 1012).',
                        SSTATUS);
          end if;
          if (STAG1038 is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Номер смены" (тэг 1038).',
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
          if (STAG1042 is null) then
            P_EXCEPTION(0,
                        'Документ в статусе "%s", но не указано значение "Номер чека в смене" (тэг 1042).',
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
           where T.RN = RFISCDOC.RN;
          /* Устанавливаем значения тэгов */
          begin
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN          => RFISCDOC.RN,
                                       NCOMPANY      => RFISCDOC.COMPANY,
                                       SATTRIBUTE    => '1012',
                                       DVAL_DATETIME => TO_DATE(STAG1012, 'dd.mm.yyyy hh24:mi:ss'));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1038',
                                       NVAL_NUMB  => TO_NUMBER(STAG1038));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1040',
                                       NVAL_NUMB  => TO_NUMBER(STAG1040));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1041',
                                       SVAL_STR   => STAG1041);
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1042',
                                       NVAL_NUMB  => TO_NUMBER(STAG1042));
            UDO_P_FISCDOCSPROP_SET_VAL(NPRN       => RFISCDOC.RN,
                                       NCOMPANY   => RFISCDOC.COMPANY,
                                       SATTRIBUTE => '1077',
                                       SVAL_STR   => STAG1077);
          exception
            when others then
              P_EXCEPTION(0,
                          'Ошибка установки значения атрибута фискального документа: %s',
                          sqlerrm);
          end;
          /* Ставим задачу на получение чека от ОФД */
          PKG_EXS.QUEUE_PUT(SEXSSERVICE   => 'ОФД_ПолучЧека',
                            SEXSSERVICEFN => 'ПолучЧека',
                            BMSG          => CLOB2BLOB(LCDATA   => STAG1041 || '/' || STAG1040 || '/' || STAG1077,
                                                       SCHARSET => 'UTF8'),
                            NLNK_COMPANY  => RFISCDOC.COMPANY,
                            NLNK_DOCUMENT => RFISCDOC.RN,
                            SLNK_UNITCODE => 'UDO_FiscalDocuments',
                            NNEW_EXSQUEUE => NNEW_EXSQUEUE);
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
           where T.RN = RFISCDOC.RN;
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
  
  /* Отработка ответов ОФД на запрос чека */
  procedure OFD_PROCESS_GET_BILL_DOC
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Проверим что позиция очереди корректна */
    UTL_EXSQUEUE_CHECK_ATTRS(REXSQUEUE => REXSQUEUE);
    /* Сохраним полученный чек в ФД */
    UDO_P_FISCDOCS_PUT_BILL(NRN => REXSQUEUE.LNK_DOCUMENT, NCOMPANY => REXSQUEUE.LNK_COMPANY, BDATA => REXSQUEUE.RESP);
    /* Всё прошло успешно */
    PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT);
  exception
    when others then
      /* Вернём ошибку */
      PKG_EXS.PRC_RESP_RESULT_SET(NIDENT => NIDENT, SRESULT => PKG_EXS.SPRC_RESP_RESULT_ERR, SMSG => sqlerrm);
  end OFD_PROCESS_GET_BILL_DOC;
      
end;
/
