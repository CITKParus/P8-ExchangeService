create or replace function F_EXSQUEUE_GET_CHILD_COUNT
(
  NRN                       in number        -- ��������������� ����� ������ ������� ������
) return                    number           -- ���������� ��������� �������
as
  NCHILD_COUNT              PKG_STD.TNUMBER; -- ��������� ���������� ��������� �������
begin
  /* ����������� ���������� */
  select count(*) - 1 into NCHILD_COUNT from EXSQUEUE T connect by prior T.RN = T.EXSQUEUE start with T.RN = NRN;
  /* ����������� ���������� */
  return NCHILD_COUNT;
end;
/
