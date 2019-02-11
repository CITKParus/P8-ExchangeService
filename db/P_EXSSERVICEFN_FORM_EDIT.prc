create or replace procedure P_EXSSERVICEFN_FORM_EDIT
(
  NMODE                     in number,                -- Тип действия (0 - Добавление, 1 - Исправление)
  NFIRST                    in out number,            -- Признак первого обращения (0 - вторичное обращение, 1 - первое обращение)
  SATTRIB                   in varchar2,              -- Измененный атрибут
  NRN                       in number,                -- Регистрационный номер функции сервиса обмена
  NPRN                      in number,                -- Регистрационный номер сервиса обмена
  NFN_TYPE                  in number,                -- Типовая функция
  NRETRY_SCHEDULE           in out number,            -- Расписание повторного исполнения
  NRETRY_STEP               in out number,            -- Шаг расписания повторного исполнения
  NRETRY_ATTEMPTS           in out number,            -- Количество попыток повторного исполнения
  NERR_NTF_SIGN             in out number,            -- Уведомлять об ошибках обработки
  SERR_NTF_MAIL             in out varchar2,          -- Список адресов E-Mail для уведомления об ошибках обработки
  NAUTH_ONLY                in out number,            -- Требуется аутентификация
  NE_RETRY_SCHEDULE         in out number,            -- Признак доступности элемента "NRETRY_SCHEDULE" (Расписание повторного исполнения)
  NE_RETRY_STEP             in out number,            -- Признак доступности элемента "NRETRY_STEP" (Шаг расписания повторного исполнения)
  NE_RETRY_ATTEMPTS         in out number,            -- Признак доступности элемента "NRETRY_ATTEMPTS" (Количество попыток повторного исполнения)
  NE_ERR_NTF_MAIL           in out number,            -- Признак доступности элемента "SERR_NTF_MAIL" (Список адресов E-Mail для уведомления об ошибках обработки)
  NE_AUTH_ONLY              in out number,            -- Признак доступности элемента "NAUTH_ONLY" (Требуется аутентификация)
  NR_ERR_NTF_MAIL           in out number             -- Признак обязательности элемента "SERR_NTF_MAIL" (Список адресов E-Mail для уведомления об ошибках обработки)
)
as
  /* Установка доступности и значений элементов, которые зависят от типа сервиса обмена */
  procedure SET_ENABLED_SRV_TYPE
  as
    NSRV_TYPE               EXSSERVICE.SRV_TYPE%type; -- Тип сервиса обмена
  begin
    /* Определение типа сервиса обмена */
    begin
      select SRV_TYPE into NSRV_TYPE from EXSSERVICE where RN = NPRN;
    exception
      when NO_DATA_FOUND then
        PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NPRN, SUNIT_TABLE => 'EXSService');
    end;
    /* Если тип сервиса обмена "Получение сообщений" */
    if (NSRV_TYPE = 1) then
      NE_RETRY_SCHEDULE := 0;
      NE_RETRY_STEP     := 0;
      NE_RETRY_ATTEMPTS := 0;
      NRETRY_SCHEDULE   := 0;
      NRETRY_STEP       := 0;
      NRETRY_ATTEMPTS   := 0;
    else
      NE_RETRY_SCHEDULE := 1;
      NE_RETRY_STEP     := 1;
      NE_RETRY_ATTEMPTS := 1;
    end if;
  end SET_ENABLED_SRV_TYPE;

  /* Установка доступности и значений элементов, которые зависят от расписания повторного исполнения функции сервиса обмена */
  procedure SET_ENABLED_RETRY_SCHEDULE
  as
  begin
    /* Если расписание повторного исполнения не определено */
    if (NRETRY_SCHEDULE = 0) then
      NE_RETRY_STEP     := 0;
      NE_RETRY_ATTEMPTS := 0;
      NRETRY_STEP       := 0;
      NRETRY_ATTEMPTS   := 0;
    else
      NE_RETRY_STEP     := 1;
      NE_RETRY_ATTEMPTS := 1;
    end if;
  end SET_ENABLED_RETRY_SCHEDULE;

  /* Установка доступности, обязательности и значений элементов, которые зависят от признака "Уведомлять об ошибках обработки" */
  procedure SET_ENABLED_ERR_NTF_SIGN
  as
  begin
    /* Если не установлен признак "Уведомлять об ошибках обработки" */
    if (NERR_NTF_SIGN = 0) then
      NE_ERR_NTF_MAIL := 0;
      NR_ERR_NTF_MAIL := 0;
      SERR_NTF_MAIL   := null;
    else
      NE_ERR_NTF_MAIL := 1;
      NR_ERR_NTF_MAIL := 1;
      /* Если значение не задано */
      if (SERR_NTF_MAIL is null) then
        /* Определение списка адресов из заголовка */
        begin
          select T.UNAVLBL_NTF_MAIL into SERR_NTF_MAIL from EXSSERVICE T where T.RN = NPRN;
        exception
          when NO_DATA_FOUND then
            PKG_MSG.RECORD_NOT_FOUND(NDOCUMENT => NPRN, SUNIT_TABLE => 'EXSService');
        end;
      end if;
    end if;
  end SET_ENABLED_ERR_NTF_SIGN;

  /* Установка доступности и значения элемента "Требуется аутентификация" */
  procedure SET_ENABLED_AUTH_ONLY
  as
    NCOUNT                  PKG_STD.TNUMBER; -- Количество функций с типом "Начало сеанса"
  begin
    /* Проверка на существование функции с типом "Начало сеанса" */
    select count(*)
      into NCOUNT
      from EXSSERVICEFN
     where PRN = NPRN
       and FN_TYPE = 1;
    /* Если есть функции с типом "Начало сеанса" */
    if (NCOUNT > 0) then
      /* Если функция "Обмен данными" */
      if (NFN_TYPE = 0) then
        NE_AUTH_ONLY := 1;
      /* Если функция "Начало сеанса" */
      elsif (NFN_TYPE = 1) then
        NAUTH_ONLY   := 0;
        NE_AUTH_ONLY := 0;
      /* Если функция "Завершение сеанса" */
      elsif (NFN_TYPE = 2) then
        NAUTH_ONLY   := 1;
        NE_AUTH_ONLY := 0;
      end if;
    /* Если нет функций с типом "Начало сеанса" */
    else
      NAUTH_ONLY   := 0;
      NE_AUTH_ONLY := 0;
    end if;
  end;

begin
  /* Если это первое обращение */
  if (NFIRST = 1) then
    /* Установка доступности и значений элементов */
    SET_ENABLED_SRV_TYPE;
    SET_ENABLED_RETRY_SCHEDULE;
    SET_ENABLED_ERR_NTF_SIGN;
    SET_ENABLED_AUTH_ONLY;
  end if;

  /* Если измененный атрибут "NRETRY_SCHEDULE" (Расписание повторного исполнения) */
  if (SATTRIB = 'NRETRY_SCHEDULE') then
    /* Установка доступности и значений элементов */
    SET_ENABLED_RETRY_SCHEDULE;
  end if;

  /* Если измененный атрибут "NERR_NTF_SIGN" (Уведомлять об ошибках обработки) или это первое обращение */
  if (SATTRIB = 'NERR_NTF_SIGN') then
    /* Установка доступности, обязательности и значений элементов */
    SET_ENABLED_ERR_NTF_SIGN;
  end if;

  /* Если измененный атрибут "NFN_TYPE" (Типовая функция) */
  if (SATTRIB = 'NFN_TYPE') then
    /* Установка доступности и значения элемента "Требуется аутентификация" */
    SET_ENABLED_AUTH_ONLY;
  end if;

  /* Установка признака первого обращение */
  NFIRST := 0;
end;
/
