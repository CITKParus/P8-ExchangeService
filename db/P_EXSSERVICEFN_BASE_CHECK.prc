create or replace procedure P_EXSSERVICEFN_BASE_CHECK
(
  SMODE                     in varchar2,              -- Тип действия ('I' - Добавление, 'U' - Исправление, 'D' - Удаление)
  REXSSERVICEFN             in EXSSERVICEFN%rowtype   -- Запись функции сервиса обмена
)
as
  /* Процедура проверки значений, которые зависят от типа сервиса обмена*/
  procedure CHECK_SRV_TYPE
  (
    NPRN                    in number,                -- Регистрационный номер сервиса обмена
    NRETRY_SCHEDULE         in number,                -- Расписание повторного исполнения
    NRETRY_STEP             in number,                -- Шаг расписания повторного исполнения
    NRETRY_ATTEMPTS         in number                 -- Количество попыток повторного исполнения
  )
  as
    NSRV_TYPE               EXSSERVICE.SRV_TYPE%type; -- Тип сервиса обмена
  begin
    /* Определение типа сериса обмена */
    begin
      select SRV_TYPE into NSRV_TYPE from EXSSERVICE where RN = NPRN;
    exception
      when NO_DATA_FOUND then
        PKG_MSG.RECORD_NOT_FOUND(NDOCUMENT => NPRN, SUNIT_TABLE => 'EXSService');
    end;
    /* Если тип сервиса обмена "Получение сообщений" */
    if (NSRV_TYPE = 1) then
      /* Проверка расписания повторного исполнения */
      if (NRETRY_SCHEDULE != 0) then
        P_EXCEPTION(0,
                    'Недопустимое значение расписания повторного исполнения функции сервиса обмена.');
      end if;
      /* Проверка шага расписания повторного исполнения */
      if (NRETRY_STEP != 0) then
        P_EXCEPTION(0,
                    'Недопустимое значение шага расписания повторного исполнения функции сервиса обмена.');
      end if;
      /* Проверка количества попыток повторного исполнения */
      if (NRETRY_ATTEMPTS != 0) then
        P_EXCEPTION(0,
                    'Недопустимое значение количества попыток повторного исполнения функции сервиса обмена.');
      end if;
    end if;
  end CHECK_SRV_TYPE;

  /* Процедура проверки значений, которые зависят от расписания повторного исполнения функции сервиса обмена */
  procedure CHECK_RETRY_SCHEDULE
  (
    NRETRY_SCHEDULE         in number,                -- Расписание повторного исполнения
    NRETRY_STEP             in number,                -- Шаг расписания повторного исполнения
    NRETRY_ATTEMPTS         in number                 -- Количество попыток повторного исполнения
  )
  as
  begin
    /* Если расписание повторного исполнения не определено */
    if (NRETRY_SCHEDULE = 0) then
      /* Проверка шага расписания повторного исполнения */
      if (NRETRY_STEP != 0) then
        P_EXCEPTION(0,
                    'Недопустимое значение шага расписания повторного исполнения функции сервиса обмена.');
      end if;
      /* Проверка количества попыток повторного исполнения */
      if (NRETRY_ATTEMPTS != 0) then
        P_EXCEPTION(0,
                    'Недопустимое значение количества попыток повторного исполнения функции сервиса обмена.');
      end if;
    end if;
  end CHECK_RETRY_SCHEDULE;

  /* Проверка функций типа "Начало сеанса" и "Завершение сеанса" */
  procedure CHECK_FN_TYPE
  (
    NRN                     in number,                -- Регистрационный номер проверяемой записи
    NPRN                    in number,                -- Регистрационный номер сервиса обмена
    NFN_TYPE                in number                 -- Типовая функция
  )
  as
    REXSSERVICEFN           EXSSERVICEFN%rowtype;     -- Текущая запись   
    NCOUNT                  PKG_STD.TNUMBER;          -- Количество найденных записей
  begin
    /* Считаем текущую запись */
    REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 1, NRN => NRN);
    /* Если типовая функция "Начало сеанса" или "Завершение сеанса" */
    if (NFN_TYPE in (1, 2)) then
      /* Определение количества записей */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and FN_TYPE = NFN_TYPE
         and ((NRN is null) or ((NRN is not null) and (RN <> NRN)));
      /* Если есть записи с такой же типовой функцией */
      if (NCOUNT > 0) then
        P_EXCEPTION(0,
                    'Сервис не может содержать более одной функции начала/завершения сеанса.');
      end if;
    end if;
    /* Если данная функция была началом сеанса, а теперь нет */
    if ((REXSSERVICEFN.FN_TYPE = 1) and (NFN_TYPE <> 1)) then
      /* Проверка на существование функций с установленным признаком "Требуется аутентификация" */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and AUTH_ONLY = 1
         and ((NRN is not null and RN != NRN) or (NRN is null));
      /* Если есть функции с установленным признаком "Требуется аутентификация" */
      if (NCOUNT > 0) then
        P_EXCEPTION(0,
                    'Изменение типа функции "Начало сеанаса" невозможно, т.к. имеются функции с установленным признаком "Требуется аутентификация".');
      end if;
    end if;
  end CHECK_FN_TYPE;

  /* Проверка активности сервера приложений */
  procedure CHECK_ACTIVE_APPSRV
  (
    SMODE                   in varchar2               -- Тип действия ('I' - Добавление, 'U' - Исправление, 'D' - Удаление)
  )
  as
    SACTION                 PKG_STD.TSTRING;          -- Наименование действия
  begin
    /* Если сервер приложений активен - не допускать добавление, исправление, удаление функции сервиса обмена */
    if (PKG_EXS.UTL_APPSRV_IS_ACTIVE) then
      /* Тип действия */
      case SMODE
        /* Добавление */
        when 'I' then
          SACTION := 'добавление';
        /* Исправление */
        when 'U' then
          SACTION := 'исправление';
        /* Удаление */
        when 'D' then
          SACTION := 'удаление';
        /* Иначе */
        else
          return;
      end case;
      P_EXCEPTION(0,
                  'Сервер приложений активен, ' || SACTION || ' функции сервиса обмена недопустимо.');
    end if;
  end CHECK_ACTIVE_APPSRV;

  /* Проверка списка адресов E-Mail для уведомления об ошибках обработки */
  procedure CHECK_ERR_NTF_MAIL
  (
    SERR_NTF_MAIL           in varchar2               -- Список адресов E-Mail для уведомления
  )
  as
    SSEQSYMB                PKG_STD.TSTRING;          -- Символ-разделитель элементов списка
    SREG_EXP_EMAIL          PKG_STD.TSTRING;          -- Маска для регулярного выражения
    NCOUNT_SEQSYMB          PKG_STD.TNUMBER;          -- Количество вхождений символа группирования перечислений в строке списка адресов E-Mail
    NREG                    PKG_STD.TNUMBER;          -- Результат выполнения REGEXP_LIKE
  begin
    /* Определение символа-разделителя элементов списка */
    SSEQSYMB := ',';
    /* Определение количества вхождений символа группирования перечислений в строке списка адресов E-Mail */
    NCOUNT_SEQSYMB := LENGTH(SERR_NTF_MAIL) - LENGTH(replace(SERR_NTF_MAIL, SSEQSYMB));
    /* Определение маски */
    SREG_EXP_EMAIL := '^((([a-z0-9_-]+\.)*[a-z0-9_-]+@[a-z0-9_-]+(\.[a-z0-9_-]+)*\.[a-z]+)\' || SSEQSYMB || '?){' ||
                      TO_CHAR(NCOUNT_SEQSYMB + 1) || '}[a-z]*$';
    /* Проверка списка адресов */
    begin
      select 1 into NREG from DUAL where REGEXP_LIKE(LOWER(SERR_NTF_MAIL), SREG_EXP_EMAIL);
    exception
      when NO_DATA_FOUND then
        P_EXCEPTION(0,
                    'Неверный формат поля "Список адресов E-Mail для уведомления об ошибках обработки".' || CR ||
                    'Пример: example@mail.ru' || CR ||
                    'Для указания нескольких адресов следует использовать запятую в качестве разделителя (без пробелов).' || CR ||
                    'Пример: example@mail.ru' || SSEQSYMB || 'e-mail@gmail.com');
    end;
  end CHECK_ERR_NTF_MAIL;

  /* Проверка признака "Требуется аутентификация" */
  procedure CHECK_AUTH_ONLY
  (
    NRN                     in number,       -- Регистрационный номер
    NPRN                    in number,       -- Регистрационный номер сервиса обмена
    NAUTH_ONLY              in number        -- Требуется аутентификация
  )
  as
    NCOUNT                  PKG_STD.TNUMBER; -- Количество функций с типом "Начало сеанса"
  begin
    /* Если указан признак */
    if (NAUTH_ONLY = 1) then
      /* Проверка на существование функции с типом "Начало сеанса" */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and FN_TYPE = 1
         and ((NRN is not null and RN != NRN) or (NRN is null));
      /* Если нет функций с типом "Начало сеанса" */
      if (NCOUNT < 1) then
        P_EXCEPTION(0,
                    'Для установки признака "Требуется аутентификация" необходима функция с типом "Начало сеанса".');
      end if;
    end if;
  end CHECK_AUTH_ONLY;

  /* Проверка признака "Требуется аутентификация" при удалении */
  procedure CHECK_AUTH_ONLY_DELETE
  (
    NRN                     in number,       -- Регистрационный номер
    NPRN                    in number,       -- Регистрационный номер сервиса обмена
    NFN_TYPE                in number        -- Типовая функция
  )
  as
    NCOUNT                  PKG_STD.TNUMBER; -- Количество функций с установленным признаком "Требуется аутентификация"
  begin
    /* Если удаляемая функция "Начало сеанса" */
    if (NFN_TYPE = 1) then
      /* Проверка на существование функций с установленным признаком "Требуется аутентификация" */
      select count(*)
        into NCOUNT
        from EXSSERVICEFN
       where PRN = NPRN
         and AUTH_ONLY = 1
         and ((NRN is not null and RN != NRN) or (NRN is null));
      /* Если есть функции с установленным признаком "Требуется аутентификация" */
      if (NCOUNT > 0) then
        P_EXCEPTION(0,
                    'Удаление функции с типом "Начало сеанаса" невозможно, т.к. имеются функции с установленным признаком "Требуется аутентификация".');
      end if;
    end if;
  end CHECK_AUTH_ONLY_DELETE;

begin
  /* Проверка активности сервера приложений */
  CHECK_ACTIVE_APPSRV(SMODE => SMODE);
  /* Тип действия */
  case SMODE
    /* Добавление */
    when 'I' then
      /* Проверка значений функции сервиса обмена */
      CHECK_SRV_TYPE(NPRN            => REXSSERVICEFN.PRN,
                     NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                     NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                     NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_RETRY_SCHEDULE(NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                           NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                           NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_FN_TYPE(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NFN_TYPE => REXSSERVICEFN.FN_TYPE);
      if (REXSSERVICEFN.ERR_NTF_MAIL is not null) then
        CHECK_ERR_NTF_MAIL(SERR_NTF_MAIL => REXSSERVICEFN.ERR_NTF_MAIL);
      end if;
      CHECK_AUTH_ONLY(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NAUTH_ONLY => REXSSERVICEFN.AUTH_ONLY);
    /* Исправление */
    when 'U' then
      /* Проверка значений функции сервиса обмена */
      CHECK_SRV_TYPE(NPRN            => REXSSERVICEFN.PRN,
                     NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                     NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                     NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_RETRY_SCHEDULE(NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                           NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP,
                           NRETRY_ATTEMPTS => REXSSERVICEFN.RETRY_ATTEMPTS);
      CHECK_FN_TYPE(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NFN_TYPE => REXSSERVICEFN.FN_TYPE);
      if (REXSSERVICEFN.ERR_NTF_MAIL is not null) then
        CHECK_ERR_NTF_MAIL(SERR_NTF_MAIL => REXSSERVICEFN.ERR_NTF_MAIL);
      end if;
      CHECK_AUTH_ONLY(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NAUTH_ONLY => REXSSERVICEFN.AUTH_ONLY);
    /* Удаление */
    when 'D' then
      /* Проверка значений функции сервиса обмена */
      CHECK_AUTH_ONLY_DELETE(NRN => REXSSERVICEFN.RN, NPRN => REXSSERVICEFN.PRN, NFN_TYPE => REXSSERVICEFN.FN_TYPE);
    else
      P_EXCEPTION(0, 'Тип действия определен неверно.');
  end case;
end;
/
