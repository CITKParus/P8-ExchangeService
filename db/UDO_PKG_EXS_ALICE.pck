create or replace package UDO_PKG_EXS_ALICE as

  /* Обработка запроса на поиск контрагента */
  procedure FIND_AGENT
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

  /* Обработка запроса на поиск договора */
  procedure FIND_CONTRACT
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );  

  /* Обработка запроса на поиск заказа потребителя */
  procedure FIND_CONSUMERORD
  (
    NIDENT                  in number,  -- Идентификатор процесса
    NSRV_TYPE               in number,  -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- Регистрационный номер обрабатываемой позиции очереди обмена
  );  

  /* Обработка запроса на поиск контактной информации */
  procedure FIND_CONTACT
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  );

end;
/
create or replace package body UDO_PKG_EXS_ALICE as

  /* Константы - каталог для поиска данных */
  SSEARCH_CATALOG_NAME      constant ACATALOG.NAME%type := 'Семинар 20_12_2018';
  
  /* Тип данных для коллекции шаблонов вспомогательных слов поиска */
  type THELPER_PATTERNS is table of varchar2(4000);

  /* Проверка на присутствие слова в списке вспомогательных */
  function UTL_HELPER_CHECK
  (
    SWORD                   in varchar2,        -- Проверяемое слово
    HELPER_PATTERNS         in THELPER_PATTERNS -- Коллекция шаблонов вспомогательных слов
  ) 
  return                    boolean             -- Резульата проверки
  is
    BRES                    boolean;            -- Буфер для результата
  begin
    /* Инициализируем буфер */
    BRES := false;
    /* Если коллекция не пуста */
    if ((HELPER_PATTERNS is not null) and (HELPER_PATTERNS.COUNT > 0)) then
      /* Обходим её */
      for I in HELPER_PATTERNS.FIRST .. HELPER_PATTERNS.LAST
      loop
        /* Если слово есть в коллекции */
        if (LOWER(SWORD) like LOWER(HELPER_PATTERNS(I))) then
          /* Выставим флаг присутствия и завершим поиск */
          BRES := true;
          exit;
        end if;
      end loop;
    end if;
    /* Возвращаем ответ */
    return BRES;
  end UTL_HELPER_CHECK;
  
  /* Инициализация общих вспомогательных поисковых фраз */
  procedure UTL_HELPER_INIT_COMMON
  (
    HELPER_PATTERNS         in out THELPER_PATTERNS -- Коллекция шаблонов вспомогательных слов
  )
  is
  begin
    /* Создадим пустую коллекцию если надо */
    if (HELPER_PATTERNS is null) then
      HELPER_PATTERNS := THELPER_PATTERNS();
    end if;
    /* Наполним её общими поисковыми вспомогательными фразами */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'скажи';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'подскажи';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'расскажи';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'про';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'о';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'об';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'по';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'сведения';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'информацию';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'информация';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'информации';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'инфы';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'инфу';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'инфа';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'дай';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'нарой';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'запроси';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'найди';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'сообщи';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'поведай';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'мне';    
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'состояни%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'статус%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'как';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'там';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'мой';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'номер%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'за';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'как';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'я';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'с';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'найти';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'можно';    
  end UTL_HELPER_INIT_COMMON;
  
  /* Подготовка поисковой фразы к участию в выборке */
  function UTL_SEARCH_STR_PREPARE
  (
    SSEARCH_STR             in varchar2,        -- Поисковая фраза
    SDELIM                  in varchar2,        -- Разделитель слов в поисковой фразе
    HELPER_PATTERNS         in THELPER_PATTERNS -- Коллекция шаблонов вспомогательных слов
  ) 
  return                    varchar2            -- Подготовленная поисковая фраза
  is
    SRES                    varchar2(32000);    -- Результат работы
  begin
    /* Если поисковая фраза задана */
    if (SSEARCH_STR is not null) then
      /* Обходим слова поисковой фразы */
      for W in (select REGEXP_SUBSTR(T.STR, '[^' || SDELIM || ']+', 1, level) SWRD
                  from (select replace(replace(replace(replace(replace(replace(replace(replace(replace(SSEARCH_STR,
                                                                                                       ',',
                                                                                                       ''),
                                                                                               '.',
                                                                                               ''),
                                                                                       '/',
                                                                                       ''),
                                                                               '\',
                                                                               ''),
                                                                       '''',
                                                                       ''),
                                                               '"',
                                                               ''),
                                                       ':',
                                                       ''),
                                               '?',
                                               ''),
                                       '!',
                                       '') STR
                          from DUAL) T
                connect by INSTR(T.STR, SDELIM, 1, level - 1) > 0)
      loop
        /* Если слово не в списке вспомогательных */
        if (not UTL_HELPER_CHECK(SWORD => W.SWRD, HELPER_PATTERNS => HELPER_PATTERNS)) then
          /* Оставляем его в итоговой выборке */
          SRES := SRES || '%' || W.SWRD;
        end if;
      end loop;
      /* Уберем лишние пробелы и готовим для поиска */
      SRES := '%' || trim(SRES) || '%';
      /* Проверим, что хоть какая-то зацепка осталось для поиска */
      if (replace(SRES, '%', '') is null) then
        /* Искать всё продряд - не верно, считаем что поисковой фразы нет */
        SRES := null;
      end if;
    else
      /* Нет поисковой фразы - нет результата */
      SRES := null;
    end if;
    /* Вернем ответ */
    return SRES;
  end UTL_SEARCH_STR_PREPARE;

  /* Обработка запроса на поиск контрагента */
  procedure FIND_AGENT
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- Коллекция шаблонов вспомогательных слов поиска
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Инициализируем коллекцию слов-помошников */
    UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
    /* Наполняем её значениями индивидуальными для данного запроса */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'контрагент%';
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Подготовим поисковую фразу */
    CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
    /* Если есть что искать */
    if (CTMP is not null) then
      /* Кладём конвертированное обратно (просто для удобства мониторинга) */
      PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
      /* Инициализируем ответ */
      CRESP := 'Контрагент не найден';
      /* Ищем запрошенного контрагента */
      for C in (select T.AGNNAME ||
                       DECODE(T.AGNTYPE, 1, ', физическое лицо', ', юридическое лицо') SAGENT,
                       T.AGNTYPE NAGNTYPE,
                       (select count(CN.RN) from CONTRACTS CN where CN.AGENT = T.RN) NCNT_CONTRACTS,
                       (select sum(CN.DOC_SUM) from CONTRACTS CN where CN.AGENT = T.RN) NSUM_CONTRACTS,
                       T.PHONE SPHONE,
                       T.MAIL SMAIL,
                       T.AGN_COMMENT SCONTACT_PERSON
                  from AGNLIST  T,
                       ACATALOG CAT
                 where ((LOWER(CTMP) like LOWER('%' || replace(T.AGNABBR, ' ', '%') || '%')) or
                       (LOWER(CTMP) like LOWER('%' || replace(T.AGNNAME, ' ', '%') || '%')) or
                       ((T.AGNFAMILYNAME is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME || '%'))) or
                       ((T.AGNFAMILYNAME_AC is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_AC || '%'))) or
                       ((T.AGNFAMILYNAME_ABL is not null) and
                       (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_ABL || '%'))) or
                       ((T.AGNFAMILYNAME_TO is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_TO || '%'))) or
                       ((T.AGNFAMILYNAME_FR is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_FR || '%'))))
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* Основная информация */
        CRESP := C.SAGENT;
        /* Далее - в зависимости от типа, для ЮЛ - сведения о договорах и контактном лице */
        if (C.NAGNTYPE = 0) then
          if (C.NCNT_CONTRACTS = 0) then
            CRESP := CRESP || ', не имеет зарегистрированных в системе договоров';
          else
            CRESP := CRESP || ', зарегистрировано договоров: ' || TO_CHAR(C.NCNT_CONTRACTS);
            if (C.NSUM_CONTRACTS <> 0) then
              CRESP := CRESP || ', на общую сумму: ' || TO_CHAR(C.NSUM_CONTRACTS) || ' руб.';
            end if;
          end if;
          if (C.SCONTACT_PERSON is not null) then
            CRESP := CRESP || ', контактное лицо: ' || C.SCONTACT_PERSON;
          end if;
        end if;
        /* Контакты контрагента - телефон */
        if (C.SPHONE is not null) then
          CRESP := CRESP || ', телефон: ' || C.SPHONE;
        end if;
        /* Контакты контрагента - e-mail */
        if (C.SMAIL is not null) then
          CRESP := CRESP || ', e-mail: ' || C.SMAIL;
        end if;
      end loop;
    else
      CRESP := 'Не понятно какого контрагента Вы хотите найти, извините...';
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end FIND_AGENT;

  /* Обработка запроса на поиск договора */
  procedure FIND_CONTRACT
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- Коллекция шаблонов вспомогательных слов поиска
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Инициализируем коллекцию слов-помошников */
    UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
    /* Наполняем её значениями индивидуальными для данного запроса */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'договор%';
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Подготовим поисковую фразу */
    CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
    /* Если есть что искать */
    if (CTMP is not null) then
      /* Кладём конвертированное обратно (просто для удобства мониторинга) */
      PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
      /* Инициализируем ответ */
      CRESP := 'Договор не найден';
      /* Ищем запрошенный договор */
      for C in (select DECODE(T.INOUT_SIGN, 0, 'Входящий', 'Исходящий') || ' договор №' ||
                       NVL(T.EXT_NUMBER, trim(T.DOC_NUMB)) || ' от ' || TO_CHAR(T.DOC_DATE, 'dd.mm.yyyy') ||
                       ' с контрагентом ' || AG.AGNNAME SDOC,
                       T.SUBJECT SSUBJECT,
                       T.DOC_SUM NDOC_SUM,
                       T.DOC_INPAY_SUM NDOC_INPAY_SUM,
                       T.DOC_OUTPAY_SUM NDOC_OUTPAY_SUM,
                       T.END_DATE DEND_DATE,
                       CN.ALTNAME10 SCUR
                  from CONTRACTS T,
                       AGNLIST   AG,
                       CURNAMES  CN,
                       ACATALOG  CAT
                 where (((T.EXT_NUMBER is not null) and (LOWER(CTMP) like LOWER('%' || T.EXT_NUMBER || '%'))) or
                       ((T.EXT_NUMBER is null) and (LOWER(CTMP) like LOWER('%' || trim(T.DOC_NUMB) || '%'))))
                   and T.AGENT = AG.RN
                   and T.CURRENCY = CN.RN
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* Основные сведения */
        CRESP := C.SDOC;
        /* Предмет договора */
        if (C.SSUBJECT is not null) then
          CRESP := CRESP || ', предмет договора: ' || C.SSUBJECT;
        end if;
        /* Сумма договора */
        if (C.NDOC_SUM <> 0) then
          CRESP := CRESP || CHR(10) || 'Сумма договора: ' || TO_CHAR(C.NDOC_SUM) || ' ' || C.SCUR;
          /* Состояние оплаты для поступления ДС */
          if (C.NDOC_INPAY_SUM <> 0) then
            if (C.NDOC_INPAY_SUM = C.NDOC_SUM) then
              CRESP := CRESP || ', оплачен закзчиком полностью';
            else
              CRESP := CRESP || ', получено от заказчика: ' || TO_CHAR(C.NDOC_INPAY_SUM) || ' ' || C.SCUR;
              if (C.NDOC_SUM - C.NDOC_INPAY_SUM > 0) then
                CRESP := CRESP || ', остаток к получению: ' || TO_CHAR(C.NDOC_SUM - C.NDOC_INPAY_SUM) || ' ' || C.SCUR;
                if (C.DEND_DATE is not null) then
                  CRESP := CRESP || ', договор истекает ' || TO_CHAR(C.DEND_DATE, 'dd.mm.yyyy');
                end if;
              end if;
            end if;
          end if;
          /* Состояние оплаты для выбытия ДС */
          if (C.NDOC_OUTPAY_SUM <> 0) then
            if (C.NDOC_OUTPAY_SUM = C.NDOC_SUM) then
              CRESP := CRESP || ', полностью оплачен закзчику';
            else
              CRESP := CRESP || ', оплачено заказчику ' || TO_CHAR(C.NDOC_OUTPAY_SUM) || ' ' || C.SCUR;
              if (C.NDOC_SUM - C.NDOC_OUTPAY_SUM > 0) then
                CRESP := CRESP || ', остаток к оплате ' || TO_CHAR(C.NDOC_SUM - C.NDOC_OUTPAY_SUM) || ' ' || C.SCUR;
                if (C.DEND_DATE is not null) then
                  CRESP := CRESP || ', договор истекает ' || TO_CHAR(C.DEND_DATE, 'dd.mm.yyyy');
                end if;
              end if;
            end if;
          end if;
        end if;
      end loop;
    else
      CRESP := 'Не понятно какой договор Вы хотите найти, извините...';
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end FIND_CONTRACT;
  
  /* Обработка запроса на поиск заказа потребителя */
  procedure FIND_CONSUMERORD
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- Коллекция шаблонов вспомогательных слов поиска
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    NSTATE_PROP             PKG_STD.TREF;     -- Рег. номер ДС для хранения состояния заказа
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Инициализируем коллекцию слов-помошников */
    UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
    /* Наполняем её значениями индивидуальными для данного запроса */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'заказ%';
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Подготовим поисковую фразу */
    CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
    /* Если есть что искать */
    if (CTMP is not null) then
      /* Кладём конвертированное обратно (просто для удобства мониторинга) */
      PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
      /* Инициализируем ответ */
      CRESP := 'Заказ не найден';
      /* Ищем запрошенный заказ */
      for C in (select 'Ваш заказ №' || trim(T.ORD_NUMB) || ' от ' || TO_CHAR(T.ORD_DATE, 'dd.mm.yyyy') SDOC,
                       T.PSUMWTAX NSUM,
                       T.RELEASE_DATE DRELEASE_DATE,
                       (select V.STR_VALUE
                          from DOCS_PROPS_VALS V,
                               DOCS_PROPS      DP
                         where V.UNIT_RN = T.RN
                           and V.DOCS_PROP_RN = DP.RN
                           and DP.CODE = 'СостояниеЗаказаПотр') SSTATE,
                       CN.ALTNAME10 SCUR,
                       AG.AGNNAME SMANAGER
                  from CONSUMERORD T,
                       AGNLIST     AG,
                       CURNAMES    CN,
                       ACATALOG    CAT
                 where (LOWER(CTMP) like LOWER('%' || trim(T.ORD_NUMB) || '%'))
                   and T.ACC_AGENT = AG.RN
                   and T.CURRENCY = CN.RN
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* Основные сведения */
        CRESP := C.SDOC;
        /* Состояние */
        if (C.SSTATE is not null) then
          CRESP := CRESP || ', находится в состоянии "' || C.SSTATE || '"';
        else
          CRESP := CRESP || ', к сожалению не удалось определить состояние заказа, но можно сказать что';
        end if;
        /* Сумма зазаза */
        if (C.NSUM <> 0) then
          CRESP := CRESP || ', сумма заказа составляет ' || TO_CHAR(C.NSUM) || ' ' || C.SCUR;
        end if;
        /* Плановый срок исполнения */
        CRESP := CRESP || ', плановая дата исполнения заказа ' || TO_CHAR(C.DRELEASE_DATE, 'dd.mm.yyyy');
        /* Менеджер */
        if (C.SMANAGER is not null) then
          CRESP := CRESP || ', менеджер: ' || C.SMANAGER;
        end if;
      end loop;
    else
      CRESP := 'Не понятно какой заказ Вы хотите найти, извините...';
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end FIND_CONSUMERORD;
  
  /* Обработка запроса на поиск контактной информации */
  procedure FIND_CONTACT
  (
    NIDENT                  in number,        -- Идентификатор процесса
    NSRV_TYPE               in number,        -- Тип сервиса (см. константы PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number         -- Регистрационный номер обрабатываемой позиции очереди обмена
  )
  is
    HELPER_PATTERNS         THELPER_PATTERNS; -- Коллекция шаблонов вспомогательных слов поиска
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    CTMP                    clob;             -- Буфер для конвертации
    CRESP                   clob;             -- Данные для ответа
    RCTMP                   sys_refcursor;    -- Буфер для измененной позиции очереди
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Инициализируем коллекцию слов-помошников */
    UTL_HELPER_INIT_COMMON(HELPER_PATTERNS => HELPER_PATTERNS);
    /* Наполняем её значениями индивидуальными для данного запроса */
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '%звонить';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'контакт%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'связ%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := 'менеджер%';
    HELPER_PATTERNS.EXTEND();
    HELPER_PATTERNS(HELPER_PATTERNS.LAST) := '%говорит%';
    /* Забираем данные сообщения и конвертируем в кодировку БД */
    CTMP := BLOB2CLOB(LBDATA => REXSQUEUE.MSG, SCHARSET => 'UTF8');
    /* Подготовим поисковую фразу */
    CTMP := UTL_SEARCH_STR_PREPARE(SSEARCH_STR => CTMP, SDELIM => ' ', HELPER_PATTERNS => HELPER_PATTERNS);
    /* Если есть что искать */
    if (CTMP is not null) then
      /* Кладём конвертированное обратно (просто для удобства мониторинга) */
      PKG_EXS.QUEUE_MSG_SET(NEXSQUEUE => REXSQUEUE.RN, BMSG => CLOB2BLOB(LCDATA => CTMP), RCQUEUE => RCTMP);
      /* Инициализируем ответ */
      CRESP := 'Контакт не найден';
      /* Ищем запрошенного контрагента */
      for C in (select T.AGNNAME     SAGENT,
                       T.AGNTYPE     NAGNTYPE,
                       T.PHONE       SPHONE,
                       T.MAIL        SMAIL,
                       T.AGN_COMMENT SCONTACT_PERSON
                  from AGNLIST  T,
                       ACATALOG CAT
                 where ((LOWER(CTMP) like LOWER('%' || replace(T.AGNABBR, ' ', '%') || '%')) or
                       (LOWER(CTMP) like LOWER('%' || replace(T.AGNNAME, ' ', '%') || '%')) or
                       ((T.AGNFAMILYNAME is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME || '%'))) or
                       ((T.AGNFAMILYNAME_AC is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_AC || '%'))) or
                       ((T.AGNFAMILYNAME_ABL is not null) and
                       (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_ABL || '%'))) or
                       ((T.AGNFAMILYNAME_TO is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_TO || '%'))) or
                       ((T.AGNFAMILYNAME_FR is not null) and (LOWER(CTMP) like LOWER('%' || T.AGNFAMILYNAME_FR || '%'))))
                   and T.CRN = CAT.RN
                   and CAT.NAME = SSEARCH_CATALOG_NAME
                   and ROWNUM <= 1)
      loop
        /* Основная информация */
        CRESP := C.SAGENT;
        /* Далее - в зависимости от типа, для ЮЛ - сведения о договорах и контактном лице */
        if (C.NAGNTYPE = 0) then
          if (C.SCONTACT_PERSON is not null) then
            CRESP := CRESP || ', контактное лицо: ' || C.SCONTACT_PERSON;
          end if;
        end if;
        /* Контакты контрагента - телефон */
        if (C.SPHONE is not null) then
          CRESP := CRESP || ', телефон: ' || C.SPHONE;
        end if;
        /* Контакты контрагента - e-mail */
        if (C.SMAIL is not null) then
          CRESP := CRESP || ', а можно не звонить, а написать e-mail: ' || C.SMAIL;
        end if;
      end loop;
    else
      CRESP := 'Не понятно какую контактную информацию Вы хотите найти, извините...';
    end if;
    /* Возвращаем ответ */
    PKG_EXS.PRC_RESP_ARG_BLOB_SET(NIDENT => NIDENT,
                                  SARG   => PKG_EXS.SCONT_FLD_BRESP,
                                  BVALUE => CLOB2BLOB(LCDATA => CRESP, SCHARSET => 'UTF8'));
  end FIND_CONTACT;
  
end;
/
