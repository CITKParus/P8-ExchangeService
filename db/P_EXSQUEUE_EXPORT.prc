create or replace procedure P_EXSQUEUE_EXPORT
(
  NRN                       in number,   -- ��������������� ����� ������� ������
  NIDENT                    in number,   -- ������������� ��������
  STYPE_FILE                in varchar2, -- ���������� �����
  NMSG                      in number,   -- ������� �������� ��������� ������� ������ (0 - �� ���������, 1 - ���������)
  NRESP                     in number,   -- ������� �������� ������ ������� ������ (0 - �� ���������, 1 - ���������)
  NMSG_ORIGINAL             in number,   -- ������� �������� ��������� ��������� ������� ������ (0 - �� ���������, 1 - ���������)
  NRESP_ORIGINAL            in number    -- ������� �������� ��������� ������ ������� ������ (0 - �� ���������, 1 - ���������)
)
as
begin
  /* �������� ������ ���������� �������� */
  PKG_ENV.PROLOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => null,
                   SUNIT     => 'EXSQueue',
                   SACTION   => 'EXSQUEUE_EXPORT',
                   STABLE    => 'EXSQUEUE',
                   NDOCUMENT => NRN);

  /* ������� �������� */
  P_EXSQUEUE_BASE_EXPORT(NRN            => NRN,
                    NIDENT         => NIDENT,
                    STYPE_FILE     => STYPE_FILE,
                    NMSG           => NMSG,
                    NRESP          => NRESP,
                    NMSG_ORIGINAL  => NMSG_ORIGINAL,
                    NRESP_ORIGINAL => NRESP_ORIGINAL);

  /* �������� ��������� ���������� �������� */
  PKG_ENV.EPILOGUE(NCOMPANY  => null,
                   NVERSION  => null,
                   NCATALOG  => null,
                   SUNIT     => 'EXSQueue',
                   SACTION   => 'EXSQUEUE_EXPORT',
                   STABLE    => 'EXSQUEUE',
                   NDOCUMENT => NRN);
end;
/
