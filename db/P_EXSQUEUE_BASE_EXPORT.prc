create or replace procedure P_EXSQUEUE_BASE_EXPORT
(
  NRN                       in number,                   -- Регистрационный номер очереди обмена
  NIDENT                    in number,                   -- Идентификатор процесса
  STYPE_FILE                in varchar2,                 -- Расширение файла
  NMSG                      in number,                   -- Признак выгрузки сообщения очереди обмена (0 - не выгружать, 1 - выгружать)
  NRESP                     in number,                   -- Признак выгрузки ответа очереди обмена (0 - не выгружать, 1 - выгружать)
  NMSG_ORIGINAL             in number,                   -- Признак выгрузки оригинала сообщения очереди обмена (0 - не выгружать, 1 - выгружать)
  NRESP_ORIGINAL            in number                    -- Признак выгрузки оригинала ответа очереди обмена (0 - не выгружать, 1 - выгружать)
)
as
  SFILENAME                 PKG_STD.TSTRING;             -- Наименование файла
  DIN_DATE                  EXSQUEUE.IN_DATE%type;       -- Дата и время постановки в очередь
  SIN_AUTHID                EXSQUEUE.IN_AUTHID%type;     -- Пользователь, поставивший в очередь
  BMSG                      EXSQUEUE.MSG%type;           -- Сообщение очереди обмена
  BRESP                     EXSQUEUE.RESP%type;          -- Ответ очереди обмена
  BMSG_ORIGINAL             EXSQUEUE.MSG_ORIGINAL%type;  -- Оригинал сообщения очереди обмена
  BRESP_ORIGINAL            EXSQUEUE.RESP_ORIGINAL%type; -- Оригинал ответа очереди обмена
begin
  /* Поиск необходимых значений очереди обмена */
  begin
    select IN_DATE,
           IN_AUTHID,
           MSG,
           RESP,
           MSG_ORIGINAL,
           RESP_ORIGINAL
      into DIN_DATE,
           SIN_AUTHID,
           BMSG,
           BRESP,
           BMSG_ORIGINAL,
           BRESP_ORIGINAL
      from EXSQUEUE
     where RN = NRN;
  exception
    when NO_DATA_FOUND then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NRN);
  end;
  /* Формирование наименования файла */
  SFILENAME := TO_CHAR(NRN) || '_' || TO_CHAR(DIN_DATE, 'dd_mm_yyyy_hh24_mi') || '_' || SIN_AUTHID ||
               NULLIF('.' || STYPE_FILE, '.');
  /* Выгрузка сообщения */
  if (NMSG = 1) then
    /* Добавление данных в буфер для выгрузки в файл */
    P_FILE_BUFFER_INSERT(NIDENT => NIDENT, CFILENAME => 'MESSAGE_' || SFILENAME, CDATA => null, BLOBDATA => BMSG);
  end if;
  /* Выгрузка ответа */
  if (NRESP = 1) then
    /* Добавление данных в буфер для выгрузки в файл */
    P_FILE_BUFFER_INSERT(NIDENT => NIDENT, CFILENAME => 'RESPOND_' || SFILENAME, CDATA => null, BLOBDATA => BRESP);
  end if;
  /* Выгрузка оригинала сообщения */
  if (NMSG_ORIGINAL = 1) then
    /* Добавление данных в буфер для выгрузки в файл */
    P_FILE_BUFFER_INSERT(NIDENT    => NIDENT,
                         CFILENAME => 'MESSAGE_ORIGINAL_' || SFILENAME,
                         CDATA     => null,
                         BLOBDATA  => BMSG_ORIGINAL);
  end if;
  /* Выгрузка оригинала ответа */
  if (NRESP_ORIGINAL = 1) then
    /* Добавление данных в буфер для выгрузки в файл */
    P_FILE_BUFFER_INSERT(NIDENT    => NIDENT,
                         CFILENAME => 'RESPOND_ORIGINAL_' || SFILENAME,
                         CDATA     => null,
                         BLOBDATA  => BRESP_ORIGINAL);
  end if;
end;
/
