create or replace package UDO_PKG_EXS_TEST as

  /* ��������� ������ � ����������� � ����������� �� ��������� ������ */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  );

end;
/
create or replace package body UDO_PKG_EXS_TEST as

  /* ��������� ������ � ����������� � ����������� �� ��������� ������ */
  procedure PROCESS_AGN_INFO_RESP
  (
    NIDENT                  in number,  -- ������������� ��������
    NSRV_TYPE               in number,  -- ��� ������� (��. ��������� PKG_EXS.NSRV_TYPE*)
    NEXSQUEUE               in number   -- ��������������� ����� �������������� ������� ������� ������
  )
  is
  begin
    null;
  end;

end;
/
