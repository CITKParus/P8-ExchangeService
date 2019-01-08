create or replace procedure P_EXSQUEUE_BASE_INSERT
(
  DIN_DATE                  in date,     -- Дата и время постановки в очередь
  SIN_AUTHID                in varchar2, -- Пользователь, поставивший в очередь
  NEXSSERVICEFN             in number,   -- Ссылка на запись таблицы "Сервисы обмена (функции)"
  DEXEC_DATE                in date,     -- Дата и время обработки
  NEXEC_CNT                 in number,   -- Количество попыток обработки
  NEXEC_STATE               in number,   -- Статус обработки
  SEXEC_MSG                 in varchar2, -- Сообщение обработки
  BMSG                      in blob,     -- Сообщение
  BRESP                     in blob,     -- Ответ
  NEXSQUEUE                 in number,   -- Связанная позиция очереди
  NLNK_COMPANY              in number,   -- Связанная организация
  NLNK_DOCUMENT             in number,   -- Связанная запись
  SLNK_UNITCODE             in varchar2, -- Связанный раздел
  SOPTIONS                  in varchar2, -- Параметры
  NRN                       out number   -- Регистрационный номер
)
as
begin
  /* Генерация регистрационного номера */
  NRN := GEN_ID;

  /* Добавление записи в таблицу */
  insert into EXSQUEUE
    (RN,
     IN_DATE,
     IN_AUTHID,
     EXSSERVICEFN,
     EXEC_DATE,
     EXEC_CNT,
     EXEC_STATE,
     EXEC_MSG,
     MSG,
     RESP,
     EXSQUEUE,
     LNK_COMPANY,
     LNK_DOCUMENT,
     LNK_UNITCODE,
     MSG_ORIGINAL,
     RESP_ORIGINAL,
     OPTIONS)
  values
    (NRN,
     DIN_DATE,
     SIN_AUTHID,
     NEXSSERVICEFN,
     DEXEC_DATE,
     NEXEC_CNT,
     NEXEC_STATE,
     SEXEC_MSG,
     BMSG,
     BRESP,
     NEXSQUEUE,
     NLNK_COMPANY,
     NLNK_DOCUMENT,
     SLNK_UNITCODE,
     BMSG,
     BRESP,
     SOPTIONS);
end;
/
