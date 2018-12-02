create or replace package PKG_EXS as

  /* Константы - идентификация сервера приложений в сессиях экземпляра БД */
  SAPPSRV_PROGRAMM_NAME     constant PKG_STD.TSTRING := 'node.exe';             -- Наименование исполняемого файла
  SAPPSRV_MODULE_NAME       constant PKG_STD.TSTRING := 'PARUS$ExchangeServer'; -- Наименование модуля
  
  /* Константы - контейнеры контекста и процессов расчёта */
  SCONT_MAIN                constant PKG_STD.TSTRING := 'EXSCONT'; -- Глобальный префикс контейнера
  SCONT_PRC                 constant PKG_STD.TSTRING := 'PRC';     -- Наименование контейнера для параметров процесса

  /* Константы - поля контейнеров */
  SCONT_FLD_SERR            constant PKG_STD.TSTRING := 'SERR';  -- Наименование поля контейнера для ошибки
  SCONT_FLD_BRESP           constant PKG_STD.TSTRING := 'BRESP'; -- Наименование поля контейнера для результата обработки

  /* Константы - типы сервисов */
  NSRV_TYPE_SEND            constant EXSSERVICE.SRV_TYPE%type := 0; -- Отправка сообщений
  NSRV_TYPE_RECIVE          constant EXSSERVICE.SRV_TYPE%type := 1; -- Получение сообщений
  SSRV_TYPE_SEND            constant varchar2(40) := 'SEND';        -- Отправка сообщений (строковый код)
  SSRV_TYPE_RECIVE          constant varchar2(40) := 'RECIVE';      -- Получение сообщений (строковый код)

  /* Константы - типы функций сервиса */
  NFN_TYPE_DATA             constant EXSSERVICEFN.FN_TYPE%type := 0; -- Обмен данными
  NFN_TYPE_LOGIN            constant EXSSERVICEFN.FN_TYPE%type := 1; -- Начало сеанса
  NFN_TYPE_LOGOUT           constant EXSSERVICEFN.FN_TYPE%type := 2; -- Завершение сеанса
  SFN_TYPE_DATA             constant varchar2(40) := 'DATA';         -- Обмен данными (строковый код)
  SFN_TYPE_LOGIN            constant varchar2(40) := 'LOGIN';        -- Начало сеанса (строковый код)
  SFN_TYPE_LOGOUT           constant varchar2(40) := 'LOGOUT';       -- Завершение сеанса (строковый код)

  /* Константы - способы передачи параметров функциям сервиса */
  NFN_PRMS_TYPE_POST        constant EXSSERVICEFN.FN_PRMS_TYPE%type := 0; -- POST-запрос
  NFN_PRMS_TYPE_GET         constant EXSSERVICEFN.FN_PRMS_TYPE%type := 1; -- GET-запрос
  SFN_PRMS_TYPE_POST        constant varchar2(40) := 'POST';              -- POST-запрос
  SFN_PRMS_TYPE_GET         constant varchar2(40) := 'GET';               -- GET-запрос

  /* Константы - расписание повторного исполнения функции */
  NRETRY_SCHEDULE_UNDEF     constant EXSSERVICEFN.RETRY_SCHEDULE%type := 0; -- Не определено
  NRETRY_SCHEDULE_SEC       constant EXSSERVICEFN.RETRY_SCHEDULE%type := 1; -- Секунда
  NRETRY_SCHEDULE_MIN       constant EXSSERVICEFN.RETRY_SCHEDULE%type := 2; -- Минута
  NRETRY_SCHEDULE_HOUR      constant EXSSERVICEFN.RETRY_SCHEDULE%type := 3; -- Час
  NRETRY_SCHEDULE_DAY       constant EXSSERVICEFN.RETRY_SCHEDULE%type := 4; -- Сутки
  NRETRY_SCHEDULE_WEEK      constant EXSSERVICEFN.RETRY_SCHEDULE%type := 5; -- Неделя
  NRETRY_SCHEDULE_MONTH     constant EXSSERVICEFN.RETRY_SCHEDULE%type := 6; -- Месяц
  SRETRY_SCHEDULE_UNDEF     constant varchar2(40) := 'UNDEFINED';           -- Не определено (строковый код)
  SRETRY_SCHEDULE_SEC       constant varchar2(40) := 'SEC';                 -- Секунда (строковый код)
  SRETRY_SCHEDULE_MIN       constant varchar2(40) := 'MIN';                 -- Минута (строковый код)
  SRETRY_SCHEDULE_HOUR      constant varchar2(40) := 'HOUR';                -- Час (строковый код)
  SRETRY_SCHEDULE_DAY       constant varchar2(40) := 'DAY';                 -- Сутки (строковый код)
  SRETRY_SCHEDULE_WEEK      constant varchar2(40) := 'WEEK';                -- Неделя (строковый код)
  SRETRY_SCHEDULE_MONTH     constant varchar2(40) := 'MONTH';               -- Месяц (строковый код)

  /* Константы - признак оповещения о простое удаленного сервиса */
  NUNAVLBL_NTF_SIGN_NO      constant EXSSERVICE.UNAVLBL_NTF_SIGN%type := 0; -- Не оповещать о простое
  NUNAVLBL_NTF_SIGN_YES     constant EXSSERVICE.UNAVLBL_NTF_SIGN%type := 1; -- Оповещать о простое
  SUNAVLBL_NTF_SIGN_NO      constant varchar2(40) := 'UNAVLBL_NTF_NO';      -- Не оповещать о простое (строковый код)
  SUNAVLBL_NTF_SIGN_YES     constant varchar2(40) := 'UNAVLBL_NTF_YES';     -- Оповещать о простое (строковый код)

  /* Константы - состояния записей журнала работы сервиса */
  NLOG_STATE_INF            constant EXSLOG.LOG_STATE%type := 0; -- Информация
  NLOG_STATE_WRN            constant EXSLOG.LOG_STATE%type := 1; -- Предупреждение
  NLOG_STATE_ERR            constant EXSLOG.LOG_STATE%type := 2; -- Ошибка
  SLOG_STATE_INF            constant varchar2(40) := 'INF';      -- Информация (строковый код)
  SLOG_STATE_WRN            constant varchar2(40) := 'WRN';      -- Предупреждение (строковый код)
  SLOG_STATE_ERR            constant varchar2(40) := 'ERR';      -- Ошибка (строковый код)
  
  /* Константы - состояния исполнения записей очереди обмена */
  NQUEUE_EXEC_STATE_INQUEUE constant EXSQUEUE.EXEC_STATE%type := 0; -- Поставлено в очередь
  NQUEUE_EXEC_STATE_APP     constant EXSQUEUE.EXEC_STATE%type := 1; -- Обрабатывается сервером приложений
  NQUEUE_EXEC_STATE_APP_OK  constant EXSQUEUE.EXEC_STATE%type := 2; -- Успешно обработано сервером приложений
  NQUEUE_EXEC_STATE_APP_ERR constant EXSQUEUE.EXEC_STATE%type := 3; -- Ошибка обработки сервером приложений
  NQUEUE_EXEC_STATE_DB      constant EXSQUEUE.EXEC_STATE%type := 4; -- Обрабатывается СУБД
  NQUEUE_EXEC_STATE_DB_OK   constant EXSQUEUE.EXEC_STATE%type := 5; -- Успешно обработано СУБД
  NQUEUE_EXEC_STATE_DB_ERR  constant EXSQUEUE.EXEC_STATE%type := 6; -- Ошибка обработки СУБД
  NQUEUE_EXEC_STATE_OK      constant EXSQUEUE.EXEC_STATE%type := 7; -- Обработано успешно
  NQUEUE_EXEC_STATE_ERR     constant EXSQUEUE.EXEC_STATE%type := 8; -- Обработано с ошибками
  SQUEUE_EXEC_STATE_INQUEUE constant varchar2(40) := 'INQUEUE';     -- Поставлено в очередь
  SQUEUE_EXEC_STATE_APP     constant varchar2(40) := 'APP';         -- Обрабатывается сервером приложений
  SQUEUE_EXEC_STATE_APP_OK  constant varchar2(40) := 'APP_OK';      -- Успешно обработано сервером приложений
  SQUEUE_EXEC_STATE_APP_ERR constant varchar2(40) := 'APP_ERR';     -- Ошибка обработки сервером приложений
  SQUEUE_EXEC_STATE_DB      constant varchar2(40) := 'DB';          -- Обрабатывается СУБД
  SQUEUE_EXEC_STATE_DB_OK   constant varchar2(40) := 'DB_OK';       -- Успешно обработано СУБД
  SQUEUE_EXEC_STATE_DB_ERR  constant varchar2(40) := 'DB_ERR';      -- Ошибка обработки СУБД    
  SQUEUE_EXEC_STATE_OK      constant varchar2(40) := 'OK';          -- Обработано успешно
  SQUEUE_EXEC_STATE_ERR     constant varchar2(40) := 'ERR';         -- Обработано с ошибками

  /* Константы - признак инкремента количества попыток исполнения позиции очереди */
  NINC_EXEC_CNT_NO          constant number(1) := 0; -- Не инкрементировать
  NINC_EXEC_CNT_YES         constant number(1) := 1; -- Инкрементировать
  
  /* Константы - признак инкремента количества попыток исполнения позиции очереди */  
  NQUEUE_EXEC_NO            constant number(1) := 0; -- Не исполнять
  NQUEUE_EXEC_YES           constant number(1) := 1; -- Исполнять
  
  /* Константы - ожидаемый интерфейс процедуры обработки сообщения очереди на стороне БД */
  SPRC_RESP_ARGS            constant varchar2(80) := 'NIDENT,IN,NUMBER;NSRV_TYPE,IN,NUMBER;NEXSQUEUE,IN,NUMBER;'; -- Список параметров процедуры обработки

  /* Проверка активности сервера приложений */
  function UTL_APPSRV_IS_ACTIVE 
  return                    boolean;    -- Флаг активности сервера приложений
  
  /* Формирование ссылки на вызываемый хранимый объект */
  function UTL_STORED_MAKE_LINK
  (
    SPROCEDURE              in varchar2,        -- Имя процедуры
    SPACKAGE                in varchar2 := null -- Имя пакета
  ) return                  varchar2;           -- Ссылка на вызываемый хранимый объект
  
  /* Проверка интерфейса хранимого объекта */
  procedure UTL_STORED_CHECK
  (
    NFLAG_SMART             in number,   -- Признак генерации исключения (0 - да, 1 - нет)
    SPKG                    in varchar2, -- Имя пакета
    SPRC                    in varchar2, -- Имя процедуры
    SARGS                   in varchar2, -- Список параметров (";" - разделитель аргументов, "," - разделитель атрибутов аргумента, формат: <АРГУМЕНТ>,<IN|OUT|IN OUT>,<ТИП ДАННЫХ ORACLE>;)
    NRESULT                 out number   -- Результат проверки (0 - ошибка, 1 - успех)
  );
  
  /* Формирование полного наименования контейнера для хранения окружения вызова процедуры */
  function UTL_CONTAINER_MAKE_NAME
  (
    NIDENT                  in number,          -- Идентификатор процесса
    SSUB_CONTAINER          in varchar2 := null -- Наименование контейнера второго уровня
  )
  return                    varchar2;           -- Полное наименование контейнера  
  
  /* Очистка контейнера для хранения окружения вызова процедуры */
  procedure UTL_CONTAINER_PURGE
  (
    NIDENT                  in number,          -- Идентификатор процесса
    SSUB_CONTAINER          in varchar2 := null -- Наименование контейнера второго уровня
  );
  
  /* Вычисление даты следующего запуска расписания */
  function UTL_SCHED_CALC_NEXT_DATE
  (
    DEXEC_DATE              in date,    -- Дата предыдущего исполнения
    NRETRY_SCHEDULE         in number,  -- График перезапуска (см. константы NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number   -- Шаг графика перезапуска
  ) 
  return                    date;       -- Дата следующего запуска
  
  /* Выяснение необходимости запуска по расписанию */
  function UTL_SCHED_CHECK_EXEC
  (
    DEXEC_DATE              in date,           -- Дата предыдущего исполнения
    NRETRY_SCHEDULE         in number,         -- График перезапуска (см. константы NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number,         -- Шаг графика перезапуска
    DEXEC                   in date := sysdate -- Дата, относительно которой необходимо выполнить проверку
  ) 
  return                    boolean;           -- Признак необходимости запуска
  
  /* Установка значения типа строка параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_STR_SET
  (
    NIDENT                  in number,   -- Идентификатор процесса
    SARG                    in varchar2, -- Наименование параметра
    SVALUE                  in varchar2  -- Значение параметра
  );

  /* Установка значения типа число параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_NUM_SET
  (
    NIDENT                  in number,   -- Идентификатор процесса
    SARG                    in varchar2, -- Наименование параметра
    NVALUE                  in number    -- Значение параметра
  );

  /* Установка значения типа дата параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_DATE_SET
  (
    NIDENT                  in number,   -- Идентификатор процесса
    SARG                    in varchar2, -- Наименование параметра
    DVALUE                  in date      -- Значение параметра
  );

  /* Установка значения типа BLOB параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_BLOB_SET
  (
    NIDENT                  in number,   -- Идентификатор процесса
    SARG                    in varchar2, -- Наименование параметра
    BVALUE                  in blob      -- Значение параметра
  );
  
  /* Считывание значения типа строка параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_STR_GET
  (
    NIDENT                  in number,  -- Идентификатор процесса
    SARG                    in varchar2 -- Наименование параметра
  ) return                  varchar2;   -- Значение параметра

  /* Считывание значения типа число параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_NUM_GET
  (
    NIDENT                  in number,  -- Идентификатор процесса
    SARG                    in varchar2 -- Наименование параметра
  ) return                  number;     -- Значение параметра

  /* Считывание значения типа дата параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_DATE_GET
  (
    NIDENT                  in number,  -- Идентификатор процесса
    SARG                    in varchar2 -- Наименование параметра
  ) return                  date;       -- Значение параметра
  
  /* Считывание значения типа BLOB параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_BLOB_GET
  (
    NIDENT                  in number,  -- Идентификатор процесса
    SARG                    in varchar2 -- Наименование параметра
  ) return                  blob;       -- Значение параметра
  
  /* Базовое добавление в буфер отбора документов */
  procedure RNLIST_BASE_INSERT
  (
    NIDENT                  in number,  -- Идентификатор буфера
    NDOCUMENT               in number,  -- Рег. номер записи документа
    NRN                     out number  -- Рег. номер добавленной записи буфера
  );
  
  /* Базовое удаление из буфера отбора документов */
  procedure RNLINST_BASE_DELETE
  (
    NRN                     in number   -- Рег. номер записи буфера
  );
  
  /* Базовая очистка буфера отбора документов */
  procedure RNLIST_BASE_CLEAR
  (
    NIDENT                  in number   -- Идентификатор буфера
  );  
  
  /* Получение сервиса */
  procedure SERVICE_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCSERVICE               out sys_refcursor -- Курсор со списком сервисов
  );
  
  /* Получение сервиса */
  procedure SERVICE_GET
  (
    NFLAG_SMART             in number,        -- Признак выдачи сообщения об ошибке
    NEXSSERVICE             in number,        -- Рег. номер записи сервиса
    RCSERVICE               out sys_refcursor -- Курсор со списком сервисов
  );
  
  /* Получение списка сервисов */
  procedure SERVICES_GET
  (
    RCSERVICES              out sys_refcursor -- Курсор со списком сервисов
  );

  /* Получение функции сервиса */
  procedure SERVICEFN_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCSERVICEFN             out sys_refcursor -- Курсор со списком функций сервиса
  );  

  /* Получение функции сервиса */
  procedure SERVICEFN_GET
  (
    NFLAG_SMART             in number,        -- Признак выдачи сообщения об ошибке
    NEXSSERVICEFN           in number,        -- Рег. номер функции сервиса
    RCSERVICEFN             out sys_refcursor -- Курсор со списком функций сервиса
  );  
  
  /* Получение списка функций сервиса */
  procedure SERVICEFNS_GET
  (
    NEXSSERVICE             in number,        -- Рег. номер записи сервиса
    RCSERVICEFNS            out sys_refcursor -- Курсор со списком функций
  );
  
  /* Поиск функции сервиса обмена по коду функции и коду сервиса */
  function SERVICEFN_FIND_BY_SRVCODE
  (
    NFLAG_SMART             in number,   -- Признак генерации исключения (0 - да, 1 - нет)
    SEXSSERVICE             in varchar2, -- Мнемокод сервиса для обработки
    SEXSSERVICEFN           in varchar2  -- Мнемокод функции сервиса для обработки
  )
  return                    number;      -- Рег. номер функции сервиса обмена

  /* Считывание записи журнала работы */
  procedure LOG_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCLOG                   out sys_refcursor -- Курсор со списком записей журнала работы
  );
  
  /* Считывание записи журнала работы */
  procedure LOG_GET
  (
    NFLAG_SMART             in number,        -- Признак выдачи сообщения об ошибке
    NEXSLOG                 in number,        -- Рег. номер записи журнала
    RCLOG                   out sys_refcursor -- Курсор со списком записей журнала работы
  );  
  
  /* Добавление записи в журнал работы */
  procedure LOG_PUT
  (
    NLOG_STATE              in number,         -- Тип записи (см. констнаты NLOG_STATE*)
    SMSG                    in varchar2,       -- Сообщение
    NEXSSERVICE             in number := null, -- Рег. номер связанного сервиса
    NEXSSERVICEFN           in number := null, -- Рег. номер связанной функции сервиса
    NEXSQUEUE               in number := null, -- Рег. номер связанной записи очереди
    RCLOG                   out sys_refcursor  -- Курсор со списком сервисов
  );

  /* Считывание сообщения очереди */
  procedure QUEUE_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCQUEUE                 out sys_refcursor -- Курсор с позицией очереди
  );
  
  /* Считывание сообщения из очереди */
  procedure QUEUE_GET
  (
    NFLAG_SMART             in number,        -- Признак выдачи сообщения об ошибке
    NEXSQUEUE               in number,        -- Рег. номер записи очереди
    RCQUEUE                 out sys_refcursor -- Курсор с позицией очереди
  );  
  
  /* Проверка необходимости исполнения исходящего сообщения очереди */
  function QUEUE_SRV_TYPE_SEND_EXEC_CHECK
  (
    NEXSQUEUE               in number -- Рег. номер записи очереди
  )
  return                    number;   -- Флаг необходимости исполнения позиции очереди (см. константы NQUEUE_EXEC_*)
  
  /* Считывание очередной порции исходящих сообщений из очереди */
  procedure QUEUE_SRV_TYPE_SEND_GET
  (
    NPORTION_SIZE           in number,        -- Количество выбираемых сообщений
    RCQUEUES                out sys_refcursor -- Курсор со списком позиций очереди
  );
 
  /* Установка состояние записи очереди */
  procedure QUEUE_EXEC_STATE_SET
  (
    NEXSQUEUE               in number,        -- Рег. номер записи очереди
    NEXEC_STATE             in number,        -- Устанавливаемое состояние
    SEXEC_MSG               in varchar2,      -- Сообщение обработчика
    NINC_EXEC_CNT           in number,        -- Флаг инкремента счётчика исполнений (см. констнаты NINC_EXEC_CNT_*, null - не менять)
    RCQUEUE                 out sys_refcursor -- Курсор с изменённой позицией очереди    
  );
  
  /* Установка результата обработки записи очереди */
  procedure QUEUE_RESP_SET
  (
    NEXSQUEUE               in number,        -- Рег. номер записи очереди  
    BRESP                   in blob,          -- Результат обработки
    RCQUEUE                 out sys_refcursor -- Курсор с изменённой позицией очереди    
  );
  
  /* Помещение сообщения обмена в очередь */
  procedure QUEUE_PUT
  (
    NEXSSERVICEFN           in number,         -- Рег. номер функции обработки
    BMSG                    in blob,           -- Данные
    NEXSQUEUE               in number := null, -- Рег. номер связанной позиции очереди
    RCQUEUE                 out sys_refcursor  -- Курсор с добавленной позицией очереди    
  );
  
  /* Помещение сообщения обмена в очередь (по коду сервиса и функции обрабоки) */
  procedure QUEUE_PUT
  (
    SEXSSERVICE             in varchar2,       -- Мнемокод сервиса для обработки
    SEXSSERVICEFN           in varchar2,       -- Мнемокод функции сервиса для обработки
    BMSG                    in blob,           -- Данные
    NEXSQUEUE               in number := null, -- Рег. номер связанной позиции очереди
    RCQUEUE                 out sys_refcursor  -- Курсор с добавленной позицией очереди
  );
  
  /* Исполнение обработчика для сообщения обмена */
  procedure QUEUE_PRC
  (
    NEXSQUEUE               in number,        -- Рег. номер записи очереди
    RCQUEUE                 out sys_refcursor -- Курсор с обработанной позицией очереди
  );
  
end;
/
create or replace package body PKG_EXS as

  /* Проверка активности сервера приложений */
  function UTL_APPSRV_IS_ACTIVE 
  return                    boolean     -- Флаг активности сервера приложений
  is
  begin
    /* Проверим наличие сеанса сервера приложений в сессиях */
    for C in (select S.SID
                from V$SESSION S
               where UPPER(S.MODULE) = UPPER(SAPPSRV_MODULE_NAME)
                 and S.STATUS <> 'KILLED'
                 and UPPER(S.PROGRAM) = UPPER(SAPPSRV_PROGRAMM_NAME))
    loop
      return true;
    end loop;
    /* Сеанса нет */
    return false;
  end UTL_APPSRV_IS_ACTIVE;
  
  /* Формирование ссылки на вызываемый хранимый объект */
  function UTL_STORED_MAKE_LINK
  (
    SPROCEDURE              in varchar2,        -- Имя процедуры
    SPACKAGE                in varchar2 := null -- Имя пакета
  ) return                  varchar2            -- Ссылка на вызываемый хранимый объект
  is
  begin
    /* Проверим параметры */
    if (SPROCEDURE is null) then
      P_EXCEPTION(0, 'Не указано наименование хранимой процедуры.');
    end if;
    /* Вернем результат */
    return PKG_OBJECT_DESC.STORED_NAME(SPACKAGE_NAME => SPACKAGE, SSTORED_NAME => SPROCEDURE);
  end UTL_STORED_MAKE_LINK;

  /* Проверка интерфейса хранимого объекта */
  procedure UTL_STORED_CHECK
  (
    NFLAG_SMART             in number,                  -- Признак генерации исключения (0 - да, 1 - нет)
    SPKG                    in varchar2,                -- Имя пакета
    SPRC                    in varchar2,                -- Имя процедуры
    SARGS                   in varchar2,                -- Список параметров (";" - разделитель аргументов, "," - разделитель атрибутов аргумента, формат: <АРГУМЕНТ>,<IN|OUT|IN OUT>,<ТИП ДАННЫХ ORACLE>;)
    NRESULT                 out number                  -- Результат проверки (0 - ошибка, 1 - успех)
  )
  is
    /* Локальные типы данных - запись параметра */
    type TARG is record
    (
      ARGUMENT_NAME         varchar2(30),               -- Имя параметра
      DATA_TYPE             varchar2(30),               -- Тип данных
      IN_OUT                varchar2(9),                -- Тип параметра
      CORRECT               number(1)                   -- Признак успешности проверки
    );
    /* Локальные типы данных - коллекция параметров */
    type TARGS_LIST is table of TARG;                   -- Коллекция параметров
    /* Локальные идентификаторы */
    STORED                  PKG_OBJECT_DESC.TSTORED;    -- Описание процедуры
    STORED_ARGS             PKG_OBJECT_DESC.TARGUMENTS; -- Коллекция описаний параметров процедуры
    STORED_ARG              PKG_OBJECT_DESC.TARGUMENT;  -- Описание параметра процедуры
    RARGS_LIST              TARGS_LIST;                 -- Коллекция существующих параметров
    RARGS_LIST_CUR          TARGS_LIST;                 -- Коллекция переданных параметров
    NARGS_LIST_CUR_CORRECT  number(1);                  -- Признак успешности проверки переданных параметров
    SARGS_LIST              PKG_STD.TSTRING;            -- Переданный список параметров
    SARG                    PKG_STD.TSTRING;            -- Переданный параметр процедуры
    SARG_TYPE               PKG_STD.TSTRING;            -- Тип данных параметра
    SARG_TYPE_NAME          PKG_STD.TSTRING;            -- Тип данных параметра (имя пользовательского типа данных)
    SINTERFACE              PKG_STD.TSTRING;            -- Ожидаемый интерфейс процедуры
  begin
    /* Проверим параметры - имя процедры всегода должно быть указано */
    if (SPRC is null) then
      P_EXCEPTION(NFLAG_SMART, 'Не указано имя процедуры.');
      return;
    end if;
    /* Проверим параметры - в списке параметров, если он есть, должны быть разделители */
    if (SARGS is not null) then
      if ((INSTR(SARGS, ';') = 0) or (INSTR(SARGS, ',') = 0)) then
        P_EXCEPTION(NFLAG_SMART,
                    'Ошибочный формат списка аргументов: используйте ";" для разделения аргументов в списке и "," для разделения атрибутов аргумента: <АРГУМЕНТ>,<IN|OUT|IN OUT>,<ТИП ДАННЫХ ORACLE>;.');
        return;
      end if;
    end if;
    /* Инициализируем результат - есть ошибки */
    NRESULT := 0;
    /* Проверка объектов БД */
    if (SPKG is not null) then
      /* Поиск пакета */
      if (PKG_OBJECT_DESC.EXISTS_PACKAGE(SPACKAGE_NAME => SPKG) = 0) then
        P_EXCEPTION(NFLAG_SMART, 'Пакет "%s" не найден.', SPKG);
        return;
      end if;
      /* Поиск процедуры в пакете*/
      if (PKG_OBJECT_DESC.EXISTS_PROCEDURE(SPROCEDURE_NAME => UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG)) = 0) then
        P_EXCEPTION(NFLAG_SMART, 'Процедура "%s" в пакете "%s" не найдена.', SPRC, SPKG);
        return;
      end if;
    else
      /* Поиск процедуры */
      if (PKG_OBJECT_DESC.EXISTS_PROCEDURE(SPROCEDURE_NAME => SPRC) = 0) then
        P_EXCEPTION(NFLAG_SMART,
                    'Процедура "%s" не найдена.',
                    UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG));
        return;
      end if;
    end if;
    /* Получаем описание процедуры */
    begin
      STORED := PKG_OBJECT_DESC.DESC_STORED(SSTORED_NAME => UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG),
                                            BRAISE_ERROR => true);
    exception
      when others then
        P_EXCEPTION(NFLAG_SMART, sqlerrm);
        return;
    end;
    /* Проверяем валидность */
    if (STORED.STATUS != 'VALID') then
      P_EXCEPTION(NFLAG_SMART,
                  'Процедура "%s" неработоспособна.',
                  UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG));
      return;
    end if;
    /* Получаем описание параметров процедуры */
    begin
      STORED_ARGS := PKG_OBJECT_DESC.DESC_ARGUMENTS(SSTORED_NAME => UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC,
                                                                                         SPACKAGE   => SPKG),
                                                    BRAISE_ERROR => true);
    exception
      when others then
        P_EXCEPTION(NFLAG_SMART, sqlerrm);
        return;
    end;
    /* Инициализируем локальную проверяемую коллекцию формальных параметров процедуры */
    RARGS_LIST := TARGS_LIST();
    for I in 1 .. PKG_OBJECT_DESC.COUNT_ARGUMENTS(RARGUMENTS => STORED_ARGS)
    loop
      /* Считываение очередного параметра из буфера */
      STORED_ARG := PKG_OBJECT_DESC.FETCH_ARGUMENT(RARGUMENTS => STORED_ARGS, IINDEX => I);
      /* Добавление эллемента в коллекцию */
      RARGS_LIST.EXTEND();
      /* Считывание имени параметра */
      RARGS_LIST(RARGS_LIST.LAST).ARGUMENT_NAME := STORED_ARG.ARGUMENT_NAME;
      /* Считывание типа параметра */
      RARGS_LIST(RARGS_LIST.LAST).IN_OUT := STORED_ARG.DB_IN_OUT;
      /* Считывание типа данных параметра */
      RARGS_LIST(RARGS_LIST.LAST).DATA_TYPE := STORED_ARG.DB_DATA_TYPE;
      if (RARGS_LIST(RARGS_LIST.LAST).DATA_TYPE in ('PL/SQL RECORD')) then
        P_EXCEPTION(NFLAG_SMART,
                    'Невозможно проверить интерфейс пользовательской процедуры: поддерживаются только простые типы данных аргументов!');
        return;
      end if;
      /* Установка признака - не проверено */
      RARGS_LIST(RARGS_LIST.LAST).CORRECT := 0;
    end loop;
    /* Проверка переданных параметров */
    if (SARGS is not null) then
      /* Инициализируем коллекцию ожидаемого списка параметров процедуры */
      SARGS_LIST     := replace(UPPER(SARGS), ' ', '');
      RARGS_LIST_CUR := TARGS_LIST();
      /* Цикл по списку параметров */
      loop
        /* Считывание параметра из списка */
        SARG := STRTOK(source => SARGS_LIST, DELIMETER => ';', ITEM => 1);
        /* Если пусто - выход из цикла*/
        if (SARG is null) then
          exit;
        end if;
        /* Добавление эллемента в коллекцию */
        RARGS_LIST_CUR.EXTEND();
        /* Установка признака - не проверено */
        RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).CORRECT := 0;
        /* Считывание имени параметра */
        RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).ARGUMENT_NAME := STRTOK(source => SARG, DELIMETER => ',', ITEM => 1);
        /* Считывание типа параметра */
        RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).IN_OUT := STRTOK(source => SARG, DELIMETER => ',', ITEM => 2);
        /* Считывание типа данных параметра */
        SARG_TYPE      := STRTOK(source => SARG, DELIMETER => ',', ITEM => 3);
        SARG_TYPE_NAME := STRTOK(source => SARG_TYPE, DELIMETER => '.', ITEM => 2);
        if (SARG_TYPE_NAME is not null) then
          /* Если пользовательский тип данных */
          P_EXCEPTION(NFLAG_SMART,
                      'Невозможно проверить интерфейс пользовательской процедуры: поддерживаются только простые типы данных!');
          return;
        else
          /* Если стандартный тип данных */
          RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).DATA_TYPE := SARG_TYPE;
        end if;
        SARG_TYPE := null;
        /* Удаление обработанного параметра из текущего списка */
        SARGS_LIST := replace(SARGS_LIST, SARG || ';');
      end loop;
      /* Проверка параметров */
      for I in RARGS_LIST_CUR.FIRST .. RARGS_LIST_CUR.LAST
      loop
        if (RARGS_LIST.COUNT > 0) then
          for J in RARGS_LIST.FIRST .. RARGS_LIST.LAST
          loop
            if (RARGS_LIST_CUR(I).ARGUMENT_NAME = RARGS_LIST(J).ARGUMENT_NAME) then
              if ((RARGS_LIST_CUR(I).IN_OUT = RARGS_LIST(J).IN_OUT) and
                 ((RARGS_LIST_CUR(I).DATA_TYPE is null) or (RARGS_LIST_CUR(I).DATA_TYPE = RARGS_LIST(J).DATA_TYPE)) and
                 (RARGS_LIST(J).CORRECT = 0)) then
                RARGS_LIST_CUR(I).CORRECT := 1;
                RARGS_LIST(J).CORRECT := 1;
              end if;
            end if;
          end loop;
        end if;
      end loop;
      /* Если хотя бы один параметр не совпадает - ошибка */
      NARGS_LIST_CUR_CORRECT := 1;
      for I in RARGS_LIST_CUR.FIRST .. RARGS_LIST_CUR.LAST
      loop
        if (RARGS_LIST_CUR(I).CORRECT = 0) then
          NARGS_LIST_CUR_CORRECT := 0;
        end if;
      end loop;
      /* Установка результата */
      NRESULT := NARGS_LIST_CUR_CORRECT;
      /* Установим сообщение об ожидаемом интерфейсе */
      SINTERFACE := RTRIM(replace(replace(replace(UPPER(SARGS), ' ', ''), ',', ' '), ';', ';' || CHR(13)),
                          ';' || CHR(13));
    else
      /* Если параметры не ожидались и их нет в списке формальных параметров процедуры */
      if (RARGS_LIST.COUNT = 0) then
        /* То проверка пройдена */
        NRESULT := 1;
      end if;
      /* Установим сообщение об ожидаемом интерфейсе */
      SINTERFACE := 'Без параметров';
    end if;
    /* Если проверка не пройдена */
    if (NRESULT = 0) then
      /* Выдаём сообщение об ошибке, если просили, с указанием ожидаемого интерфейса процедуры */
      P_EXCEPTION(NFLAG_SMART,
                  'Для процедуры "%s" ожидался следующий интерфейс вызова: %s.',
                  UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG),
                  CHR(13) || SINTERFACE);
    end if;
  end UTL_STORED_CHECK;
  
  /* Формирование полного наименования контейнера для хранения окружения вызова процедуры */
  function UTL_CONTAINER_MAKE_NAME
  (
    NIDENT                  in number,          -- Идентификатор процесса
    SSUB_CONTAINER          in varchar2 := null -- Наименование контейнера второго уровня
  )
  return                    varchar2            -- Полное наименование контейнера
  is
    /* Формирование полного наименования контейнера */
    function CONTAINER_MAKE_NAME
    (
      SCONT                 in varchar2,        -- Наименование
      SPREFIX               in varchar2 := null -- Префикс
    ) return                varchar2            -- Полное наименование контейнера
    is
    begin
      /* Проверим параметры */
      if (SCONT is null) then
        P_EXCEPTION(0, 'Не указано наименование контейнера.');
      end if;
      /* Сформируем полное наименование с учётом префикса */
      if (SPREFIX is null) then
        return SCONT;
      else
        return SPREFIX || '.' || SCONT;
      end if;
    end;
  begin
    if (SSUB_CONTAINER is null) then
      return TO_CHAR(NIDENT) || CONTAINER_MAKE_NAME(SCONT => SCONT_PRC, SPREFIX => SCONT_MAIN);
    else
      return TO_CHAR(NIDENT) || CONTAINER_MAKE_NAME(SCONT   => SSUB_CONTAINER,
                                                    SPREFIX => CONTAINER_MAKE_NAME(SCONT   => SCONT_PRC,
                                                                                   SPREFIX => SCONT_MAIN));
    end if;
  end UTL_CONTAINER_MAKE_NAME;

  /* Очистка контейнера для хранения окружения вызова процедуры */
  procedure UTL_CONTAINER_PURGE
  (
    NIDENT                  in number,          -- Идентификатор процесса
    SSUB_CONTAINER          in varchar2 := null -- Наименование контейнера второго уровня
  )
  is
  begin
    PKG_CONTVARGLB.PURGE(SCONTAINER => UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT, SSUB_CONTAINER => SSUB_CONTAINER));
  end UTL_CONTAINER_PURGE;
  
  /* Вычисление даты следующего запуска расписания */
  function UTL_SCHED_CALC_NEXT_DATE
  (
    DEXEC_DATE              in date,    -- Дата предыдущего исполнения
    NRETRY_SCHEDULE         in number,  -- График перезапуска (см. константы NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number   -- Шаг графика перезапуска
  ) 
  return                    date        -- Дата следующего запуска
  is
  begin
    /* Если нет даты предыдущего запуска или расписание не определено, то дата очередного запуска - это текущая дата */
    if (DEXEC_DATE is null) or (NRETRY_SCHEDULE = NRETRY_SCHEDULE_UNDEF) then
      /* Отнимим минутку - для верности */
      return sysdate -(1 / (24 * 60));
    else
      /* Расчитаем в зависимости от типа расписания */
      case NRETRY_SCHEDULE
        /* Ежесекундно */
        when NRETRY_SCHEDULE_SEC then
          begin
            return DEXEC_DATE +(1 / (24 * 60 * 60)) * NRETRY_STEP;
          end;
        /* Ежеминутно */
        when NRETRY_SCHEDULE_MIN then
          begin
            return DEXEC_DATE +(1 / (24 * 60)) * NRETRY_STEP;
          end;
        /* Ежечасно */
        when NRETRY_SCHEDULE_HOUR then
          begin
            return DEXEC_DATE +(1 / 24) * NRETRY_STEP;
          end;
        /* Ежедневно */
        when NRETRY_SCHEDULE_DAY then
          begin
            return DEXEC_DATE + 1 * NRETRY_STEP;
          end;
        /* Еженедельно */
        when NRETRY_SCHEDULE_WEEK then
          begin
            return DEXEC_DATE +(1 * 7) * NRETRY_STEP;
          end;
        /* Ежемесячно */
        when NRETRY_SCHEDULE_MONTH then
          begin
            return ADD_MONTHS(DEXEC_DATE, NRETRY_STEP);
          end;
        /* Неподдерживаемый тип расписания */
        else
          return null;
      end case;
    end if;
    return null;
  exception
    when others then
      return null;
  end UTL_SCHED_CALC_NEXT_DATE;

  /* Выяснение необходимости запуска по расписанию */
  function UTL_SCHED_CHECK_EXEC
  (
    DEXEC_DATE              in date,           -- Дата предыдущего исполнения
    NRETRY_SCHEDULE         in number,         -- График перезапуска (см. константы NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number,         -- Шаг графика перезапуска
    DEXEC                   in date := sysdate -- Дата, относительно которой необходимо выполнить проверку
  ) 
  return                    boolean            -- Признак необходимости запуска
  is
    DEXEC_NEXT              date;              -- Hасчетная дата следующего запуска
  begin
    /* Расчитаем дату следующего запуска */
    DEXEC_NEXT := UTL_SCHED_CALC_NEXT_DATE(DEXEC_DATE      => DEXEC_DATE,
                                           NRETRY_SCHEDULE => NRETRY_SCHEDULE,
                                           NRETRY_STEP     => NRETRY_STEP);
    /* Если не расчиталась - то запускать не можем */
    if (DEXEC_NEXT is null) then
      return false;
    end if;
    /* Если она раньше указанной - надо исполнять */
    if (DEXEC_NEXT <= DEXEC) then
      return true;
    end if;
    /* Исполять не надо */
    return false;
  exception
    when others then
      return false;
  end UTL_SCHED_CHECK_EXEC;
  
  /* Установка значения типа строка параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_STR_SET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2,     -- Наименование параметра
    SVALUE                  in varchar2      -- Значение параметра
  )
  is
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Установим значение */
    PKG_CONTVARGLB.PUTS(SCONTAINER => SCONTAINER, SNAME => SARG, SVALUE => SVALUE);
  end PRC_RESP_ARG_STR_SET;

  /* Установка значения типа число параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_NUM_SET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2,     -- Наименование параметра
    NVALUE                  in number        -- Значение параметра
  )
  is
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Установим значение */
    PKG_CONTVARGLB.PUTN(SCONTAINER => SCONTAINER, SNAME => SARG, NVALUE => NVALUE);
  end PRC_RESP_ARG_NUM_SET;

  /* Установка значения типа дата параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_DATE_SET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2,     -- Наименование параметра
    DVALUE                  in date          -- Значение параметра
  )
  is
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Установим значение */
    PKG_CONTVARGLB.PUTD(SCONTAINER => SCONTAINER, SNAME => SARG, DVALUE => DVALUE);
  end PRC_RESP_ARG_DATE_SET;

  /* Установка значения типа BLOB параметра процедуры обработки сообщения обмена */
  procedure PRC_RESP_ARG_BLOB_SET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2,     -- Наименование параметра
    BVALUE                  in blob          -- Значение параметра
  )
  is
    NFILE_IDENT             PKG_STD.TREF;    -- Идентификатор буфера для хранения результата обработки
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Сохраним результаты обработки в файловый буфер */
    NFILE_IDENT := GEN_IDENT();
    P_FILE_BUFFER_INSERT(NIDENT => NFILE_IDENT, CFILENAME => NFILE_IDENT, CDATA => null, BLOBDATA => BVALUE);
    /* Сохраним данные в контейнер */
    PKG_CONTVARGLB.PUTN(SCONTAINER => SCONTAINER, SNAME => SARG, NVALUE => NFILE_IDENT);
  end PRC_RESP_ARG_BLOB_SET;  
  
  /* Считывание значения типа строка параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_STR_GET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2      -- Наименование параметра
  ) return                  varchar2         -- Значение параметра
  is
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Считаем и вернём значение */
    return PKG_CONTVARGLB.GETS(SCONTAINER => SCONTAINER, SNAME => SARG);
  end PRC_RESP_ARG_STR_GET;

  /* Считывание значения типа число параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_NUM_GET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2      -- Наименование параметра
  ) return                  number           -- Значение параметра
  is
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Считаем и вернём значение */
    return PKG_CONTVARGLB.GETN(SCONTAINER => SCONTAINER, SNAME => SARG);
  end PRC_RESP_ARG_NUM_GET;

  /* Считывание значения типа дата параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_DATE_GET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2      -- Наименование параметра
  ) return                  date             -- Значение параметра
  is
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Считаем и вернём значение */
    return PKG_CONTVARGLB.GETD(SCONTAINER => SCONTAINER, SNAME => SARG);
  end PRC_RESP_ARG_DATE_GET;
  
  /* Считывание значения типа BLOB параметра процедуры обработки сообщения обмена */
  function PRC_RESP_ARG_BLOB_GET
  (
    NIDENT                  in number,       -- Идентификатор процесса
    SARG                    in varchar2      -- Наименование параметра
  ) return                  blob             -- Значение параметра
  is
    NFILE_IDENT             PKG_STD.TREF;    -- Идентификатор буфера для хранения результата обработки
    SCONTAINER              PKG_STD.TSTRING; -- Наименование контейнера
    BRESP                   blob;            -- Буфер для значения
  begin
    /* Сформируем наименование контейнера */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* Считаем значение идентификатора буфера из контейнера */
    NFILE_IDENT := PKG_CONTVARGLB.GETN(SCONTAINER => SCONTAINER, SNAME => SARG);
    /* Заберем результаты обработки из файлового буфера */
    begin
      select T.BDATA into BRESP from FILE_BUFFER T where T.IDENT = NFILE_IDENT;
    exception
      when NO_DATA_FOUND then
        P_EXCEPTION(0,
                    'Результаты обработки не найдены в буфере (IDENT: %s).',
                    TO_CHAR(NFILE_IDENT));
      when TOO_MANY_ROWS then
        P_EXCEPTION(0,
                    'Результаты обработки не определены однозначно (IDENT: %s).',
                    TO_CHAR(NFILE_IDENT));
    end;
    /* Зачистим файловый буфер */
    P_FILE_BUFFER_CLEAR(NIDENT => NFILE_IDENT);    
    /* Вернём значение */
    return BRESP;
  end PRC_RESP_ARG_BLOB_GET;  

  /* Базовое добавление в буфер отбора документов */
  procedure RNLIST_BASE_INSERT
  (
    NIDENT                  in number,  -- Идентификатор буфера
    NDOCUMENT               in number,  -- Рег. номер записи документа
    NRN                     out number  -- Рег. номер добавленной записи буфера
  )
  is
  begin
    /* Генерируем рег. номер */
    NRN := GEN_ID();
    /* Добавляем запись */
    insert into EXSRNLIST (RN, IDENT, DOCUMENT) values (NRN, NIDENT, NDOCUMENT);
  end RNLIST_BASE_INSERT;
  
  /* Базовое удаление из буфера отбора документов */
  procedure RNLINST_BASE_DELETE
  (
    NRN                     in number   -- Рег. номер записи буфера
  )
  is
  begin
    /* Удалим запись */
    delete from EXSRNLIST T where T.RN = NRN;
  end RNLINST_BASE_DELETE;
  
  /* Базовая очистка буфера отбора документов */
  procedure RNLIST_BASE_CLEAR
  (
    NIDENT                  in number   -- Идентификатор буфера
  )
  is
  begin
    /* Обходим буфер */
    for C in (select T.RN from EXSRNLIST T where T.IDENT = NIDENT)
    loop
      /* Удаляем его записи */
      RNLINST_BASE_DELETE(NRN => C.RN);
    end loop;
  end RNLIST_BASE_CLEAR;
  
  /* Получение сервиса */
  procedure SERVICE_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCSERVICE               out sys_refcursor -- Курсор со списком сервисов
  )
  is
  begin
    /* Отдаём список сервисов в виде курсора */
    open RCSERVICE for
      select T.RN "nId",
             T.CODE "sCode",
             T.SRV_TYPE "nSrvType",
             DECODE(T.SRV_TYPE, NSRV_TYPE_SEND, SSRV_TYPE_SEND, NSRV_TYPE_RECIVE, SSRV_TYPE_RECIVE) "sSrvType",
             T.SRV_ROOT "sSrvRoot",
             T.SRV_USER "sSrvUser",
             T.SRV_PASS "sSrvPass",
             T.UNAVLBL_NTF_SIGN "nUnavlblNtfSign",
             DECODE(T.UNAVLBL_NTF_SIGN,
                    NUNAVLBL_NTF_SIGN_NO,
                    SUNAVLBL_NTF_SIGN_NO,
                    NUNAVLBL_NTF_SIGN_YES,
                    SUNAVLBL_NTF_SIGN_YES) "sUnavlblNtfSign",
             T.UNAVLBL_NTF_TIME "nUnavlblNtfTime",
             T.UNAVLBL_NTF_MAIL "sUnavlblNtfMail"
        from EXSSERVICE T
       where T.RN in (select L.DOCUMENT from EXSRNLIST L where L.IDENT = NIDENT);
  end SERVICE_GET;
  
  /* Получение сервиса */
  procedure SERVICE_GET
  (
    NFLAG_SMART             in number,          -- Признак выдачи сообщения об ошибке
    NEXSSERVICE             in number,          -- Рег. номер записи сервиса
    RCSERVICE               out sys_refcursor   -- Курсор со списком сервисов
  )
  is
    REXSSERVICE             EXSSERVICE%rowtype; -- Запись сервиса
    NIDENT                  PKG_STD.TREF;       -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;       -- Рег. номер очередной записи буфера
  begin
    /* Считаем запись сервиса */
    REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSSERVICE);
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Положим рег. номер сервиса в буфер */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSSERVICE.RN, NEXSSERVICE), NRN => NTMP);
    /* Забираем сервис в виде курсора */
    SERVICE_GET(NIDENT => NIDENT, RCSERVICE => RCSERVICE);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICE_GET;
  
  /* Получение списка сервисов */
  procedure SERVICES_GET
  (
    RCSERVICES              out sys_refcursor -- Курсор со списком сервисов
  )
  is
    NIDENT                  PKG_STD.TREF;     -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;     -- Рег. номер очередной записи буфера
  begin
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Обходим нужные сервисы */
    for C in (select T.RN from EXSSERVICE T)
    loop
      /* Запоминаем их рег. номера в буфере */
      RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => C.RN, NRN => NTMP);
    end loop;
    /* Забираем отобранные сервисы */
    SERVICE_GET(NIDENT => NIDENT, RCSERVICE => RCSERVICES);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICES_GET;  
  
  /* Получение функции сервиса */
  procedure SERVICEFN_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCSERVICEFN             out sys_refcursor -- Курсор со списком функций сервиса
  )
  is
  begin
    /* Отдаём список функций в виде курсора */
    open RCSERVICEFN for
      select T.RN "nId",
             T.PRN "nServiceId",
             T.CODE "sCode",
             T.FN_TYPE "nFnType",
             DECODE(T.FN_TYPE,
                    NFN_TYPE_DATA,
                    SFN_TYPE_DATA,
                    NFN_TYPE_LOGIN,
                    SFN_TYPE_LOGIN,
                    NFN_TYPE_LOGOUT,
                    SFN_TYPE_LOGOUT) "sFnType",
             T.FN_URL "sFnURL",
             T.FN_PRMS_TYPE "nFnPrmsType",
             DECODE(T.FN_PRMS_TYPE, NFN_PRMS_TYPE_POST, SFN_PRMS_TYPE_POST, NFN_PRMS_TYPE_GET, SFN_PRMS_TYPE_GET) "sFnPrmsType",
             T.RETRY_SCHEDULE "nRetrySchedule",
             DECODE(T.RETRY_SCHEDULE,
                    NRETRY_SCHEDULE_UNDEF,
                    SRETRY_SCHEDULE_UNDEF,
                    NRETRY_SCHEDULE_SEC,
                    SRETRY_SCHEDULE_SEC,
                    NRETRY_SCHEDULE_MIN,
                    SRETRY_SCHEDULE_MIN,
                    NRETRY_SCHEDULE_HOUR,
                    SRETRY_SCHEDULE_HOUR,
                    NRETRY_SCHEDULE_DAY,
                    SRETRY_SCHEDULE_DAY,
                    NRETRY_SCHEDULE_WEEK,
                    SRETRY_SCHEDULE_WEEK,
                    NRETRY_SCHEDULE_MONTH,
                    SRETRY_SCHEDULE_MONTH) "sRetrySchedule",
             T.EXSMSGTYPE "nMsgId",
             M.CODE "sMsgCode",
             M.APPSRV_BEFORE "sAppSrvBefore",
             M.APPSRV_AFTER "sAppSrvAfter"
        from EXSSERVICEFN T,
             EXSMSGTYPE   M
       where T.RN in (select L.DOCUMENT from EXSRNLIST L where L.IDENT = NIDENT)
         and T.EXSMSGTYPE = M.RN;
  end SERVICEFN_GET;
  
  /* Получение функции сервиса */
  procedure SERVICEFN_GET
  (
    NFLAG_SMART             in number,            -- Признак выдачи сообщения об ошибке
    NEXSSERVICEFN           in number,            -- Рег. номер функции сервиса
    RCSERVICEFN             out sys_refcursor     -- Курсор со списком функций сервиса
  )
  is
    REXSSERVICEFN           EXSSERVICEFN%rowtype; -- Запись функции сервиса
    NIDENT                  PKG_STD.TREF;         -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;         -- Рег. номер очередной записи буфера
  begin
    /* Считаем запись функции сервиса */
    REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSSERVICEFN);
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Положим рег. номер функции сервиса в буфер */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSSERVICEFN.RN, NEXSSERVICEFN), NRN => NTMP);
    /* Забираем сервис в виде курсора */
    SERVICEFN_GET(NIDENT => NIDENT, RCSERVICEFN => RCSERVICEFN);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICEFN_GET;
  
  /* Получение списка функций сервиса */
  procedure SERVICEFNS_GET
  (
    NEXSSERVICE             in number,        -- Рег. номер записи сервиса
    RCSERVICEFNS            out sys_refcursor -- Курсор со списком функций
  )
  is
    NIDENT                  PKG_STD.TREF;     -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;     -- Рег. номер очередной записи буфера
  begin
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Обходим функции сервиса */
    for C in (select T.RN from EXSSERVICEFN T where T.PRN = NEXSSERVICE)
    loop
      /* Запоминаем их рег. номера в буфере */
      RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => C.RN, NRN => NTMP);
    end loop;
    /* Забираем отобранные функции сервиса */
    SERVICEFN_GET(NIDENT => NIDENT, RCSERVICEFN => RCSERVICEFNS);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICEFNS_GET;
  
  /* Поиск функции сервиса обмена по коду функции и коду сервиса */
  function SERVICEFN_FIND_BY_SRVCODE
  (
    NFLAG_SMART             in number,    -- Признак генерации исключения (0 - да, 1 - нет)
    SEXSSERVICE             in varchar2,  -- Мнемокод сервиса для обработки
    SEXSSERVICEFN           in varchar2   -- Мнемокод функции сервиса для обработки
  )
  return                    number        -- Рег. номер функции сервиса обмена
  is
    NEXSSERVICEFN           PKG_STD.TREF; -- Рег. номер функции сервиса обработки  
  begin
    /* Найдем функцию сервиса обработки */
    begin
      select T.RN
        into NEXSSERVICEFN
        from EXSSERVICEFN T,
             EXSSERVICE   S
       where S.CODE = SEXSSERVICE
         and S.RN = T.PRN
         and T.CODE = SEXSSERVICEFN;
    exception
      when NO_DATA_FOUND then
        P_EXCEPTION(NFLAG_SMART,
                    'Функция "%s" сервиса обмена "%s" не определена',
                    SEXSSERVICEFN,
                    SEXSSERVICE);
    end;
    /* Вернем результат */
    return NEXSSERVICEFN;
  end SERVICEFN_FIND_BY_SRVCODE;
  
  /* Считывание записи журнала работы */
  procedure LOG_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCLOG                   out sys_refcursor -- Курсор со списком записей журнала работы
  )
  is
  begin
    /* Отдаём запись в виде курсора */
    open RCLOG for
      select T.RN "nId",
             T.LOG_DATE "dLogDate",
             TO_CHAR(T.LOG_DATE, 'dd.mm.yyyy hh24:mi:ss') "sLogDate",
             T.LOG_STATE "nLogState",
             DECODE(T.LOG_STATE,
                    NLOG_STATE_INF,
                    SLOG_STATE_INF,
                    NLOG_STATE_WRN,
                    SLOG_STATE_WRN,
                    NLOG_STATE_ERR,
                    SLOG_STATE_ERR) "sLogState",
             T.MSG "sMsg",
             T.EXSSERVICE "nServiceId",
             S.CODE "sServiceCode",
             T.EXSSERVICEFN "nServiceFnId",
             SFN.CODE "sServiceFnCode",
             T.EXSQUEUE "nQueueId"
        from EXSLOG       T,
             EXSSERVICE   S,
             EXSSERVICEFN SFN
       where T.RN in (select L.DOCUMENT from EXSRNLIST L where L.IDENT = NIDENT)
         and T.EXSSERVICE = S.RN(+)
         and T.EXSSERVICEFN = SFN.RN(+);
  end LOG_GET;
  
  /* Считывание записи журнала работы */
  procedure LOG_GET
  (
    NFLAG_SMART             in number,        -- Признак выдачи сообщения об ошибке    
    NEXSLOG                 in number,        -- Рег. номер записи журнала
    RCLOG                   out sys_refcursor -- Курсор со списком записей журнала работы
  )
  is
    REXSLOG                 EXSLOG%rowtype;   -- Запись журнала работы
    NIDENT                  PKG_STD.TREF;     -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;     -- Рег. номер очередной записи буфера
  begin
    /* Считаем запись журнала работы */
    REXSLOG := GET_EXSLOG_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSLOG);
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Положим рег. номер записи журнала работы в буфер */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSLOG.RN, NEXSLOG), NRN => NTMP);
    /* Забираем позицию очереди в виде курсора */
    LOG_GET(NIDENT => NIDENT, RCLOG => RCLOG);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end LOG_GET;

  /* Добавление записи в журнал работы */
  procedure LOG_PUT
  (
    NLOG_STATE              in number,            -- Тип записи (см. констнаты NLOG_STATE*)
    SMSG                    in varchar2,          -- Сообщение
    NEXSSERVICE             in number := null,    -- Рег. номер связанного сервиса
    NEXSSERVICEFN           in number := null,    -- Рег. номер связанной функции сервиса
    NEXSQUEUE               in number := null,    -- Рег. номер связанной записи очереди
    RCLOG                   out sys_refcursor     -- Курсор со списком сервисов
  )
  is
    NEXSSERVICE_            EXSSERVICE.RN%type;   -- Рег. номер связанного сервиса (для автоматического определения)
    NEXSSERVICEFN_          EXSSERVICEFN.RN%type; -- Рег. номер связанной функции сервиса (для автоматического определения)
    NEXSLOG                 PKG_STD.TREF;         -- Рег. номер добавленной записи журнала
  begin
    /* Проинициализирем переопределенные функцию и сервис */
    NEXSSERVICE_   := NEXSSERVICE;
    NEXSSERVICEFN_ := NEXSSERVICEFN;
    /* Если задана функция сервиса - определяем по ней сервис */
    if (NEXSSERVICEFN is not null) then
      begin
        select T.PRN into NEXSSERVICE_ from EXSSERVICEFN T where T.RN = NEXSSERVICEFN;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSSERVICEFN, SUNIT_TABLE => 'EXSSERVICEFN');
      end;
    end if;
    /* Если задана позиция очереди - определяем по ней и функцию и сервис */
    if (NEXSQUEUE is not null) then
      begin
        select SFN.PRN,
               SFN.RN
          into NEXSSERVICE_,
               NEXSSERVICEFN_
          from EXSQUEUE     T,
               EXSSERVICEFN SFN
         where T.RN = NEXSQUEUE
           and T.EXSSERVICEFN = SFN.RN;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSQUEUE, SUNIT_TABLE => 'EXSQUEUE');
      end;
    end if;
    /* Добавим запись в протокол работы */
    P_EXSLOG_BASE_INSERT(DLOG_DATE     => sysdate,
                         NLOG_STATE    => NLOG_STATE,
                         SMSG          => SMSG,
                         NEXSSERVICE   => NEXSSERVICE_,
                         NEXSSERVICEFN => NEXSSERVICEFN_,
                         NEXSQUEUE     => NEXSQUEUE,
                         NRN           => NEXSLOG);
    /* Вернем добавленную запись */
    LOG_GET(NFLAG_SMART => 0, NEXSLOG => NEXSLOG, RCLOG => RCLOG);                         
  end LOG_PUT;

  /* Считывание сообщения из очереди */
  procedure QUEUE_GET
  (
    NIDENT                  in number,        -- Идентификатор буфера
    RCQUEUE                 out sys_refcursor -- Курсор с позицией очереди
  )
  is
  begin
    open RCQUEUE for
      select T.RN "nId",
             T.IN_DATE "dInDate",
             TO_CHAR(T.IN_DATE, 'dd.mm.yyyy hh24:mi:ss') "sInDate",
             T.IN_AUTHID "sInAuth",
             S.RN "nServiceId",
             S.CODE "sServiceCode",
             T.EXSSERVICEFN "nServiceFnId",
             F.CODE "sServiceFnCode",
             T.EXEC_DATE "dExecDate",
             TO_CHAR(T.EXEC_DATE, 'dd.mm.yyyy hh24:mi:ss') "sExecDate",
             T.EXEC_CNT "nExecCnt",
             T.EXEC_STATE "nExecState",
             DECODE(T.EXEC_STATE,
                    NQUEUE_EXEC_STATE_INQUEUE,
                    SQUEUE_EXEC_STATE_INQUEUE,
                    NQUEUE_EXEC_STATE_APP,
                    SQUEUE_EXEC_STATE_APP,
                    NQUEUE_EXEC_STATE_APP_OK,
                    SQUEUE_EXEC_STATE_APP_OK,
                    NQUEUE_EXEC_STATE_APP_ERR,
                    SQUEUE_EXEC_STATE_APP_ERR,
                    NQUEUE_EXEC_STATE_DB,
                    SQUEUE_EXEC_STATE_DB,
                    NQUEUE_EXEC_STATE_DB_OK,
                    SQUEUE_EXEC_STATE_DB_OK,
                    NQUEUE_EXEC_STATE_DB_ERR,
                    SQUEUE_EXEC_STATE_DB_ERR,
                    NQUEUE_EXEC_STATE_OK,
                    SQUEUE_EXEC_STATE_OK,
                    NQUEUE_EXEC_STATE_ERR,
                    SQUEUE_EXEC_STATE_ERR) "sExecState",
             T.EXEC_MSG "sExecMsg",
             T.MSG "blMsg",
             T.RESP "blResp",
             T.EXSQUEUE "nQueueId"
        from EXSQUEUE     T,
             EXSSERVICEFN F,
             EXSSERVICE   S
       where T.RN in (select L.DOCUMENT from EXSRNLIST L where L.IDENT = NIDENT)
         and T.EXSSERVICEFN = F.RN
         and F.PRN = S.RN;
  end QUEUE_GET;
  
  /* Считывание сообщения из очереди */
  procedure QUEUE_GET
  (
    NFLAG_SMART             in number,        -- Признак выдачи сообщения об ошибке    
    NEXSQUEUE               in number,        -- Рег. номер записи очереди
    RCQUEUE                 out sys_refcursor -- Курсор с позицией очереди
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
    NIDENT                  PKG_STD.TREF;     -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;     -- Рег. номер очередной записи буфера
  begin
    /* Считаем запись позиции очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSQUEUE);
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Положим рег. номер записи очереди в буфер */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSQUEUE.RN, NEXSQUEUE), NRN => NTMP);
    /* Забираем позицию очереди в виде курсора */
    QUEUE_GET(NIDENT => NIDENT, RCQUEUE => RCQUEUE);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end QUEUE_GET;
  
  /* Проверка необходимости исполнения позиции очереди */
  function QUEUE_SRV_TYPE_SEND_EXEC_CHECK
  (
    NEXSQUEUE               in number -- Рег. номер записи очереди
  )
  return                    number    -- Флаг необходимости исполнения позиции очереди (см. константы NQUEUE_EXEC_*)
  is
    REXSQUEUE               EXSQUEUE%rowtype;          -- Запись позиции очереди
    REXSSERVICE             EXSSERVICE%rowtype;        -- Запись сервиса обработки
    REXSSERVICEFN           EXSSERVICEFN%rowtype;      -- Запись функции обработки
    NRESULT                 number(17); -- Результат работы
  begin
    /* Инициализируем результат */
    NRESULT := NQUEUE_EXEC_NO;
    begin
      /* Считаем запись очереди */
      REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
      /* Считаем запись функции обработки */
      REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 0, NRN => REXSQUEUE.EXSSERVICEFN);
      /* Считаем запись сервиса обработки */
      REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => REXSSERVICEFN.PRN);
      /* Проверим условия исполнения - исходящее, недоисполнено, и остались попытки */
      if ((REXSSERVICE.SRV_TYPE = NSRV_TYPE_SEND) and
         (REXSQUEUE.EXEC_STATE in
         (NQUEUE_EXEC_STATE_INQUEUE, NQUEUE_EXEC_STATE_APP_ERR, NQUEUE_EXEC_STATE_DB_ERR, NQUEUE_EXEC_STATE_ERR)) and
         (((REXSSERVICEFN.RETRY_SCHEDULE <> NRETRY_SCHEDULE_UNDEF) and
         (REXSQUEUE.EXEC_CNT < REXSSERVICEFN.RETRY_ATTEMPTS)) or
         ((REXSSERVICEFN.RETRY_SCHEDULE = NRETRY_SCHEDULE_UNDEF) and (REXSQUEUE.EXEC_CNT = 0))) and
         (UTL_SCHED_CHECK_EXEC(DEXEC_DATE      => REXSQUEUE.EXEC_DATE,
                                NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                                NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP))) then
        /* Надо исполнять */
        NRESULT := NQUEUE_EXEC_YES;
      end if;
    exception
      when others then
        NRESULT := NQUEUE_EXEC_NO;
    end;
    /* Вернём результат */
    return NRESULT;
  end QUEUE_SRV_TYPE_SEND_EXEC_CHECK;
  
  /* Считывание очередной порции исходящих сообщений из очереди */
  procedure QUEUE_SRV_TYPE_SEND_GET
  (
    NPORTION_SIZE           in number,        -- Количество выбираемых сообщений
    RCQUEUES                out sys_refcursor -- Курсор со списком позиций очереди
  )
  is
    NIDENT                  PKG_STD.TREF;     -- Идентификатор буфера
    NTMP                    PKG_STD.TREF;     -- Рег. номер очередной записи буфера
  begin
    /* Сформируем идентификатор буфера */
    NIDENT := GEN_IDENT();
    /* Обходим требуемые исходящие сообщения */
    for C in (select *
                from (select T.RN
                        from EXSQUEUE T
                       where QUEUE_SRV_TYPE_SEND_EXEC_CHECK(T.RN) = NQUEUE_EXEC_YES
                       order by T.IN_DATE)
               where ROWNUM <= NPORTION_SIZE)
    loop
      /* Запоминаем их рег. номера в буфере */
      RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => C.RN, NRN => NTMP);
    end loop;
    /* Забираем отобранные записи очереди */
    QUEUE_GET(NIDENT => NIDENT, RCQUEUE => RCQUEUES);
    /* Чистим буфер */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end QUEUE_SRV_TYPE_SEND_GET;

  /* Установка состояние записи очереди */
  procedure QUEUE_EXEC_STATE_SET
  (
    NEXSQUEUE               in number,        -- Рег. номер записи очереди
    NEXEC_STATE             in number,        -- Устанавливаемое состояние
    SEXEC_MSG               in varchar2,      -- Сообщение обработчика
    NINC_EXEC_CNT           in number,        -- Флаг инкремента счётчика исполнений (см. констнаты NINC_EXEC_CNT_*, null - не менять)
    RCQUEUE                 out sys_refcursor -- Курсор с изменённой позицией очереди    
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- Запись позиции очереди
  begin
    /* Проверям параметры */
    if (NEXSQUEUE is null) then
      P_EXCEPTION(0,
                  'Не указан идентификатор позиции очереди для изменения состояния');
    end if;
    if (NEXEC_STATE not in (NQUEUE_EXEC_STATE_INQUEUE,
                            NQUEUE_EXEC_STATE_APP,
                            NQUEUE_EXEC_STATE_APP_OK,
                            NQUEUE_EXEC_STATE_APP_ERR,
                            NQUEUE_EXEC_STATE_DB,
                            NQUEUE_EXEC_STATE_DB_OK,
                            NQUEUE_EXEC_STATE_DB_ERR,
                            NQUEUE_EXEC_STATE_OK,
                            NQUEUE_EXEC_STATE_ERR)) then
      P_EXCEPTION(0,
                  'Код состояния "%s" позиции очереди не поддерживается',
                  TO_CHAR(NEXEC_STATE));
    end if;
    if (NVL(NINC_EXEC_CNT, NINC_EXEC_CNT_NO) not in (NINC_EXEC_CNT_YES, NINC_EXEC_CNT_NO)) then
      P_EXCEPTION(0,
                  'Флаг икремента счетчика исполнений "%s" позиции очереди не поддерживается',
                  TO_CHAR(NINC_EXEC_CNT));
    end if;
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Увеличим счётчик количества попыток исполнения, если просили */
    if (NVL(NINC_EXEC_CNT, NINC_EXEC_CNT_NO) = NINC_EXEC_CNT_YES) then
      REXSQUEUE.EXEC_CNT := REXSQUEUE.EXEC_CNT + 1;
    end if;
    /* Выставим состояние */
    update EXSQUEUE T
       set T.EXEC_DATE  = sysdate,
           T.EXEC_STATE = NEXEC_STATE,
           T.EXEC_CNT   = REXSQUEUE.EXEC_CNT,
           T.EXEC_MSG   = SEXEC_MSG
     where T.RN = NEXSQUEUE;
    if (sql%rowcount = 0) then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSQUEUE, SUNIT_TABLE => 'EXSQUEUE');
    end if;
    /* Вернем измененную позицию очереди */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => NEXSQUEUE, RCQUEUE => RCQUEUE);
  end QUEUE_EXEC_STATE_SET;
  
  /* Установка результата обработки записи очереди */
  procedure QUEUE_RESP_SET
  (
    NEXSQUEUE               in number,        -- Рег. номер записи очереди  
    BRESP                   in blob,          -- Результат обработки
    RCQUEUE                 out sys_refcursor -- Курсор с изменённой позицией очереди            
  )
  is
  begin
    /* Выставим результат */
    update EXSQUEUE T set T.RESP = BRESP where T.RN = NEXSQUEUE;
    if (sql%rowcount = 0) then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSQUEUE, SUNIT_TABLE => 'EXSQUEUE');
    end if;
    /* Вернем измененную позицию очереди */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => NEXSQUEUE, RCQUEUE => RCQUEUE);
  end QUEUE_RESP_SET;

  /* Помещение сообщения обмена в очередь */
  procedure QUEUE_PUT
  (
    NEXSSERVICEFN           in number,         -- Рег. номер функции обработки
    BMSG                    in blob,           -- Данные
    NEXSQUEUE               in number := null, -- Рег. номер связанной позиции очереди
    RCQUEUE                 out sys_refcursor  -- Курсор с добавленной позицией очереди    
  )
  is
    NRN                     EXSQUEUE.RN%type;  -- Рег. номер добавленной записи очереди
  begin
    /* Проверяем параметры */
    if (NEXSSERVICEFN is null) then
      P_EXCEPTION(0, 'Не указан идентификатор функции сервиса обмена');
    end if;
    /* Ставим запись в очередь */
    P_EXSQUEUE_BASE_INSERT(DIN_DATE      => sysdate,
                           SIN_AUTHID    => UTILIZER(),
                           NEXSSERVICEFN => NEXSSERVICEFN,
                           DEXEC_DATE    => null,
                           NEXEC_CNT     => 0,
                           NEXEC_STATE   => NQUEUE_EXEC_STATE_INQUEUE,
                           SEXEC_MSG     => null,
                           BMSG          => BMSG,
                           BRESP         => null,
                           NEXSQUEUE     => NEXSQUEUE,
                           NRN           => NRN);
    /* Возвращаем добавленную позицию очереди */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => NRN, RCQUEUE => RCQUEUE);
  end QUEUE_PUT;

  /* Помещение сообщения обмена в очередь (по коду сервиса и функции обрабоки) */
  procedure QUEUE_PUT
  (
    SEXSSERVICE             in varchar2,       -- Мнемокод сервиса для обработки
    SEXSSERVICEFN           in varchar2,       -- Мнемокод функции сервиса для обработки
    BMSG                    in blob,           -- Данные
    NEXSQUEUE               in number := null, -- Рег. номер связанной позиции очереди
    RCQUEUE                 out sys_refcursor  -- Курсор с добавленной позицией очереди
  )
  is
    NEXSSERVICEFN           PKG_STD.TREF;      -- Рег. номер функции сервиса обработки
  begin
    /* Проверяем параметры */
    if (SEXSSERVICE is null) then
      P_EXCEPTION(0, 'Не указан код сервиса обмена');
    end if;
    if (SEXSSERVICEFN is null) then
      P_EXCEPTION(0, 'Не указан код функции сервиса обмена');
    end if;
    /* Разыменуем функцию сервиса */
    NEXSSERVICEFN := SERVICEFN_FIND_BY_SRVCODE(NFLAG_SMART   => 0,
                                               SEXSSERVICE   => SEXSSERVICE,
                                               SEXSSERVICEFN => SEXSSERVICEFN);
    /* Ставим запись в очередь */
    QUEUE_PUT(NEXSSERVICEFN => NEXSSERVICEFN, BMSG => BMSG, NEXSQUEUE => NEXSQUEUE, RCQUEUE => RCQUEUE);
  end QUEUE_PUT;
  
  /* Исполнение обработчика для сообщения обмена */
  procedure QUEUE_PRC
  (
    NEXSQUEUE               in number,                 -- Рег. номер записи очереди
    RCQUEUE                 out sys_refcursor          -- Курсор с обработанной позицией очереди
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;          -- Запись позиции очереди
    REXSSERVICE             EXSSERVICE%rowtype;        -- Запись сервиса обработки
    REXSSERVICEFN           EXSSERVICEFN%rowtype;      -- Запись функции обработки
    REXSMSGTYPE             EXSMSGTYPE%rowtype;        -- Запись типового сообщения обмена
    SERR                    EXSQUEUE.EXEC_MSG%type;    -- Сообщение об ошибке обработчика
    NIDENT                  PKG_STD.TREF;              -- Идентификатор процесса обработки
    PRMS                    PKG_CONTPRMLOC.TCONTAINER; -- Контейнер для параметров процедуры обработки 
  begin
    /* Считаем запись очереди */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* Считаем запись функции обработки */
    REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 0, NRN => REXSQUEUE.EXSSERVICEFN);
    /* Считаем запись сервиса обработки */
    REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => REXSSERVICEFN.PRN);
    /* Считаем запись типового сообщения */
    REXSMSGTYPE := GET_EXSMSGTYPE_ID(NFLAG_SMART => 0, NRN => REXSSERVICEFN.EXSMSGTYPE);
    /* Запустим обработчик, если он есть */
    if (REXSMSGTYPE.PRC_RESP is not null) then
      /* Проверяем интерфейс обработчика */
      UTL_STORED_CHECK(NFLAG_SMART => 0,
                       SPKG        => REXSMSGTYPE.PKG_RESP,
                       SPRC        => REXSMSGTYPE.PRC_RESP,
                       SARGS       => SPRC_RESP_ARGS,
                       NRESULT     => NIDENT);
      /* Формируем идентификатор процесса */
      NIDENT := GEN_IDENT();
      /* Установим значения фиксированных входных параметров */
      PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS,
                             SNAME      => 'NIDENT',
                             NVALUE     => NIDENT,
                             NIN_OUT    => PKG_STD.IPARAM_TYPE_IN);
      PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS,
                             SNAME      => 'NSRV_TYPE',
                             NVALUE     => REXSSERVICE.SRV_TYPE,
                             NIN_OUT    => PKG_STD.IPARAM_TYPE_IN);
      PKG_CONTPRMLOC.APPENDN(RCONTAINER => PRMS,
                             SNAME      => 'NEXSQUEUE',
                             NVALUE     => REXSQUEUE.RN,
                             NIN_OUT    => PKG_STD.IPARAM_TYPE_IN);
      /* Исполняем процедуру */
      PKG_SQL_CALL.EXECUTE_STORED(SSTORED_NAME     => UTL_STORED_MAKE_LINK(SPACKAGE   => REXSMSGTYPE.PKG_RESP,
                                                                           SPROCEDURE => REXSMSGTYPE.PRC_RESP),
                                  RPARAM_CONTAINER => PRMS);
      /*
      TODO: owner="mikha" created="15.11.2018"
      text="Протестировать что будет если процедура не установила параметр перед завершением и вообще - как эту ситуацию отловить, чтобы ругаться, мол не установлено значение"
      */
      /* Забираем параметр с ошибками обработчика */
      SERR := PRC_RESP_ARG_STR_GET(NIDENT => NIDENT, SARG => SCONT_FLD_SERR);
      /* Если были ошибки - скажем об этом */
      if (SERR is not null) then
        P_EXCEPTION(0, SERR);
      else
        /* Зафиксируем результат обработки (только для входящих и только если нет ошибок обработки) */
        if (REXSSERVICE.SRV_TYPE = NSRV_TYPE_RECIVE) then
          QUEUE_RESP_SET(NEXSQUEUE => REXSQUEUE.RN,
                         BRESP     => PRC_RESP_ARG_BLOB_GET(NIDENT => NIDENT, SARG => SCONT_FLD_BRESP),
                         RCQUEUE   => RCQUEUE);
        end if;
      end if;
      /* Очистим контейнер параметров */
      PKG_CONTPRMLOC.PURGE(RCONTAINER => PRMS);
    end if;
    /* Возвращаем обработанную позицию очереди */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => REXSQUEUE.RN, RCQUEUE => RCQUEUE);
  end QUEUE_PRC;
  
end;
/
