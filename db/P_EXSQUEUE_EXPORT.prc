create or replace procedure P_EXSQUEUE_EXPORT
(
  NRN                       in number,   -- Регистрационный номер очереди обмена
  NIDENT                    in number,   -- Идентификатор процесса
  STYPE_FILE                in varchar2, -- Расширение файла
  NMSG                      in number,   -- Признак выгрузки сообщения очереди обмена (0 - не выгружать, 1 - выгружать)
  NRESP                     in number,   -- Признак выгрузки ответа очереди обмена (0 - не выгружать, 1 - выгружать)
  NMSG_ORIGINAL             in number,   -- Признак выгрузки оригинала сообщения очереди обмена (0 - не выгружать, 1 - выгружать)
  NRESP_ORIGINAL            in number    -- Признак выгрузки оригинала ответа очереди обмена (0 - не выгружать, 1 - выгружать)
)
as
begin
  /* Фиксация начала выполнения действия */
  PKG_ENV.PROLOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => null,
                   SUNIT     => 'EXSQueue',
                   SACTION   => 'EXSQUEUE_EXPORT',
                   STABLE    => 'EXSQUEUE',
                   NDOCUMENT => NRN);

  /* Базовая выгрузка */
  P_EXSQUEUE_BASE_EXPORT(NRN            => NRN,
                    NIDENT         => NIDENT,
                    STYPE_FILE     => STYPE_FILE,
                    NMSG           => NMSG,
                    NRESP          => NRESP,
                    NMSG_ORIGINAL  => NMSG_ORIGINAL,
                    NRESP_ORIGINAL => NRESP_ORIGINAL);

  /* Фиксация окончания выполнения действия */
  PKG_ENV.EPILOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => null,
                   SUNIT     => 'EXSQueue',
                   SACTION   => 'EXSQUEUE_EXPORT',
                   STABLE    => 'EXSQUEUE',
                   NDOCUMENT => NRN);
end;
/
