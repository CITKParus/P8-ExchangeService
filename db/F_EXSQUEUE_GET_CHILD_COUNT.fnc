create or replace function F_EXSQUEUE_GET_CHILD_COUNT
(
  NRN                       in number        -- Регистрационный номер записи очереди обмена
) return                    number           -- Количество связанных записей
as
  NCHILD_COUNT              PKG_STD.TNUMBER; -- Найденное количество связанных записей
begin
  /* Определение количества */
  select count(*) - 1 into NCHILD_COUNT from EXSQUEUE T connect by prior T.RN = T.EXSQUEUE start with T.RN = NRN;
  /* Возвращение результата */
  return NCHILD_COUNT;
end;
/
