create or replace procedure P_EXSQUEUE_BASE_INSERT
(
  DIN_DATE                  in date,     -- ���� � ����� ���������� � �������
  SIN_AUTHID                in varchar2, -- ������������, ����������� � �������
  NEXSSERVICEFN             in number,   -- ������ �� ������ ������� "������� ������ (�������)"
  DEXEC_DATE                in date,     -- ���� � ����� ���������
  NEXEC_CNT                 in number,   -- ���������� ������� ���������
  NEXEC_STATE               in number,   -- ������ ���������
  SEXEC_MSG                 in varchar2, -- ��������� ���������
  BMSG                      in blob,     -- ���������
  BRESP                     in blob,     -- �����
  NEXSQUEUE                 in number,   -- ��������� ������� �������
  NLNK_COMPANY              in number,   -- ��������� �����������
  NLNK_DOCUMENT             in number,   -- ��������� ������
  SLNK_UNITCODE             in varchar2, -- ��������� ������
  SOPTIONS                  in varchar2, -- ���������
  NRN                       out number   -- ��������������� �����
)
as
begin
  /* ��������� ���������������� ������ */
  NRN := GEN_ID;

  /* ���������� ������ � ������� */
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
