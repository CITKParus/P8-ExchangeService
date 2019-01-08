create or replace procedure P_EXSQUEUE_BASE_EXPORT
(
  NRN                       in number,                   -- ��������������� ����� ������� ������
  NIDENT                    in number,                   -- ������������� ��������
  STYPE_FILE                in varchar2,                 -- ���������� �����
  NMSG                      in number,                   -- ������� �������� ��������� ������� ������ (0 - �� ���������, 1 - ���������)
  NRESP                     in number,                   -- ������� �������� ������ ������� ������ (0 - �� ���������, 1 - ���������)
  NMSG_ORIGINAL             in number,                   -- ������� �������� ��������� ��������� ������� ������ (0 - �� ���������, 1 - ���������)
  NRESP_ORIGINAL            in number                    -- ������� �������� ��������� ������ ������� ������ (0 - �� ���������, 1 - ���������)
)
as
  SFILENAME                 PKG_STD.TSTRING;             -- ������������ �����
  DIN_DATE                  EXSQUEUE.IN_DATE%type;       -- ���� � ����� ���������� � �������
  SIN_AUTHID                EXSQUEUE.IN_AUTHID%type;     -- ������������, ����������� � �������
  BMSG                      EXSQUEUE.MSG%type;           -- ��������� ������� ������
  BRESP                     EXSQUEUE.RESP%type;          -- ����� ������� ������
  BMSG_ORIGINAL             EXSQUEUE.MSG_ORIGINAL%type;  -- �������� ��������� ������� ������
  BRESP_ORIGINAL            EXSQUEUE.RESP_ORIGINAL%type; -- �������� ������ ������� ������
begin
  /* ����� ����������� �������� ������� ������ */
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
  /* ������������ ������������ ����� */
  SFILENAME := TO_CHAR(NRN) || '_' || TO_CHAR(DIN_DATE, 'dd_mm_yyyy_hh24_mi') || '_' || SIN_AUTHID ||
               NULLIF('.' || STYPE_FILE, '.');
  /* �������� ��������� */
  if (NMSG = 1) then
    /* ���������� ������ � ����� ��� �������� � ���� */
    P_FILE_BUFFER_INSERT(NIDENT => NIDENT, CFILENAME => 'MESSAGE_' || SFILENAME, CDATA => null, BLOBDATA => BMSG);
  end if;
  /* �������� ������ */
  if (NRESP = 1) then
    /* ���������� ������ � ����� ��� �������� � ���� */
    P_FILE_BUFFER_INSERT(NIDENT => NIDENT, CFILENAME => 'RESPOND_' || SFILENAME, CDATA => null, BLOBDATA => BRESP);
  end if;
  /* �������� ��������� ��������� */
  if (NMSG_ORIGINAL = 1) then
    /* ���������� ������ � ����� ��� �������� � ���� */
    P_FILE_BUFFER_INSERT(NIDENT    => NIDENT,
                         CFILENAME => 'MESSAGE_ORIGINAL_' || SFILENAME,
                         CDATA     => null,
                         BLOBDATA  => BMSG_ORIGINAL);
  end if;
  /* �������� ��������� ������ */
  if (NRESP_ORIGINAL = 1) then
    /* ���������� ������ � ����� ��� �������� � ���� */
    P_FILE_BUFFER_INSERT(NIDENT    => NIDENT,
                         CFILENAME => 'RESPOND_ORIGINAL_' || SFILENAME,
                         CDATA     => null,
                         BLOBDATA  => BRESP_ORIGINAL);
  end if;
end;
/
