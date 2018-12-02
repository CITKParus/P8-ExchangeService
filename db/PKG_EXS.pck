create or replace package PKG_EXS as

  /* ��������� - ������������� ������� ���������� � ������� ���������� �� */
  SAPPSRV_PROGRAMM_NAME     constant PKG_STD.TSTRING := 'node.exe';             -- ������������ ������������ �����
  SAPPSRV_MODULE_NAME       constant PKG_STD.TSTRING := 'PARUS$ExchangeServer'; -- ������������ ������
  
  /* ��������� - ���������� ��������� � ��������� ������� */
  SCONT_MAIN                constant PKG_STD.TSTRING := 'EXSCONT'; -- ���������� ������� ����������
  SCONT_PRC                 constant PKG_STD.TSTRING := 'PRC';     -- ������������ ���������� ��� ���������� ��������

  /* ��������� - ���� ����������� */
  SCONT_FLD_SERR            constant PKG_STD.TSTRING := 'SERR';  -- ������������ ���� ���������� ��� ������
  SCONT_FLD_BRESP           constant PKG_STD.TSTRING := 'BRESP'; -- ������������ ���� ���������� ��� ���������� ���������

  /* ��������� - ���� �������� */
  NSRV_TYPE_SEND            constant EXSSERVICE.SRV_TYPE%type := 0; -- �������� ���������
  NSRV_TYPE_RECIVE          constant EXSSERVICE.SRV_TYPE%type := 1; -- ��������� ���������
  SSRV_TYPE_SEND            constant varchar2(40) := 'SEND';        -- �������� ��������� (��������� ���)
  SSRV_TYPE_RECIVE          constant varchar2(40) := 'RECIVE';      -- ��������� ��������� (��������� ���)

  /* ��������� - ���� ������� ������� */
  NFN_TYPE_DATA             constant EXSSERVICEFN.FN_TYPE%type := 0; -- ����� �������
  NFN_TYPE_LOGIN            constant EXSSERVICEFN.FN_TYPE%type := 1; -- ������ ������
  NFN_TYPE_LOGOUT           constant EXSSERVICEFN.FN_TYPE%type := 2; -- ���������� ������
  SFN_TYPE_DATA             constant varchar2(40) := 'DATA';         -- ����� ������� (��������� ���)
  SFN_TYPE_LOGIN            constant varchar2(40) := 'LOGIN';        -- ������ ������ (��������� ���)
  SFN_TYPE_LOGOUT           constant varchar2(40) := 'LOGOUT';       -- ���������� ������ (��������� ���)

  /* ��������� - ������� �������� ���������� �������� ������� */
  NFN_PRMS_TYPE_POST        constant EXSSERVICEFN.FN_PRMS_TYPE%type := 0; -- POST-������
  NFN_PRMS_TYPE_GET         constant EXSSERVICEFN.FN_PRMS_TYPE%type := 1; -- GET-������
  SFN_PRMS_TYPE_POST        constant varchar2(40) := 'POST';              -- POST-������
  SFN_PRMS_TYPE_GET         constant varchar2(40) := 'GET';               -- GET-������

  /* ��������� - ���������� ���������� ���������� ������� */
  NRETRY_SCHEDULE_UNDEF     constant EXSSERVICEFN.RETRY_SCHEDULE%type := 0; -- �� ����������
  NRETRY_SCHEDULE_SEC       constant EXSSERVICEFN.RETRY_SCHEDULE%type := 1; -- �������
  NRETRY_SCHEDULE_MIN       constant EXSSERVICEFN.RETRY_SCHEDULE%type := 2; -- ������
  NRETRY_SCHEDULE_HOUR      constant EXSSERVICEFN.RETRY_SCHEDULE%type := 3; -- ���
  NRETRY_SCHEDULE_DAY       constant EXSSERVICEFN.RETRY_SCHEDULE%type := 4; -- �����
  NRETRY_SCHEDULE_WEEK      constant EXSSERVICEFN.RETRY_SCHEDULE%type := 5; -- ������
  NRETRY_SCHEDULE_MONTH     constant EXSSERVICEFN.RETRY_SCHEDULE%type := 6; -- �����
  SRETRY_SCHEDULE_UNDEF     constant varchar2(40) := 'UNDEFINED';           -- �� ���������� (��������� ���)
  SRETRY_SCHEDULE_SEC       constant varchar2(40) := 'SEC';                 -- ������� (��������� ���)
  SRETRY_SCHEDULE_MIN       constant varchar2(40) := 'MIN';                 -- ������ (��������� ���)
  SRETRY_SCHEDULE_HOUR      constant varchar2(40) := 'HOUR';                -- ��� (��������� ���)
  SRETRY_SCHEDULE_DAY       constant varchar2(40) := 'DAY';                 -- ����� (��������� ���)
  SRETRY_SCHEDULE_WEEK      constant varchar2(40) := 'WEEK';                -- ������ (��������� ���)
  SRETRY_SCHEDULE_MONTH     constant varchar2(40) := 'MONTH';               -- ����� (��������� ���)

  /* ��������� - ������� ���������� � ������� ���������� ������� */
  NUNAVLBL_NTF_SIGN_NO      constant EXSSERVICE.UNAVLBL_NTF_SIGN%type := 0; -- �� ��������� � �������
  NUNAVLBL_NTF_SIGN_YES     constant EXSSERVICE.UNAVLBL_NTF_SIGN%type := 1; -- ��������� � �������
  SUNAVLBL_NTF_SIGN_NO      constant varchar2(40) := 'UNAVLBL_NTF_NO';      -- �� ��������� � ������� (��������� ���)
  SUNAVLBL_NTF_SIGN_YES     constant varchar2(40) := 'UNAVLBL_NTF_YES';     -- ��������� � ������� (��������� ���)

  /* ��������� - ��������� ������� ������� ������ ������� */
  NLOG_STATE_INF            constant EXSLOG.LOG_STATE%type := 0; -- ����������
  NLOG_STATE_WRN            constant EXSLOG.LOG_STATE%type := 1; -- ��������������
  NLOG_STATE_ERR            constant EXSLOG.LOG_STATE%type := 2; -- ������
  SLOG_STATE_INF            constant varchar2(40) := 'INF';      -- ���������� (��������� ���)
  SLOG_STATE_WRN            constant varchar2(40) := 'WRN';      -- �������������� (��������� ���)
  SLOG_STATE_ERR            constant varchar2(40) := 'ERR';      -- ������ (��������� ���)
  
  /* ��������� - ��������� ���������� ������� ������� ������ */
  NQUEUE_EXEC_STATE_INQUEUE constant EXSQUEUE.EXEC_STATE%type := 0; -- ���������� � �������
  NQUEUE_EXEC_STATE_APP     constant EXSQUEUE.EXEC_STATE%type := 1; -- �������������� �������� ����������
  NQUEUE_EXEC_STATE_APP_OK  constant EXSQUEUE.EXEC_STATE%type := 2; -- ������� ���������� �������� ����������
  NQUEUE_EXEC_STATE_APP_ERR constant EXSQUEUE.EXEC_STATE%type := 3; -- ������ ��������� �������� ����������
  NQUEUE_EXEC_STATE_DB      constant EXSQUEUE.EXEC_STATE%type := 4; -- �������������� ����
  NQUEUE_EXEC_STATE_DB_OK   constant EXSQUEUE.EXEC_STATE%type := 5; -- ������� ���������� ����
  NQUEUE_EXEC_STATE_DB_ERR  constant EXSQUEUE.EXEC_STATE%type := 6; -- ������ ��������� ����
  NQUEUE_EXEC_STATE_OK      constant EXSQUEUE.EXEC_STATE%type := 7; -- ���������� �������
  NQUEUE_EXEC_STATE_ERR     constant EXSQUEUE.EXEC_STATE%type := 8; -- ���������� � ��������
  SQUEUE_EXEC_STATE_INQUEUE constant varchar2(40) := 'INQUEUE';     -- ���������� � �������
  SQUEUE_EXEC_STATE_APP     constant varchar2(40) := 'APP';         -- �������������� �������� ����������
  SQUEUE_EXEC_STATE_APP_OK  constant varchar2(40) := 'APP_OK';      -- ������� ���������� �������� ����������
  SQUEUE_EXEC_STATE_APP_ERR constant varchar2(40) := 'APP_ERR';     -- ������ ��������� �������� ����������
  SQUEUE_EXEC_STATE_DB      constant varchar2(40) := 'DB';          -- �������������� ����
  SQUEUE_EXEC_STATE_DB_OK   constant varchar2(40) := 'DB_OK';       -- ������� ���������� ����
  SQUEUE_EXEC_STATE_DB_ERR  constant varchar2(40) := 'DB_ERR';      -- ������ ��������� ����    
  SQUEUE_EXEC_STATE_OK      constant varchar2(40) := 'OK';          -- ���������� �������
  SQUEUE_EXEC_STATE_ERR     constant varchar2(40) := 'ERR';         -- ���������� � ��������

  /* ��������� - ������� ���������� ���������� ������� ���������� ������� ������� */
  NINC_EXEC_CNT_NO          constant number(1) := 0; -- �� ����������������
  NINC_EXEC_CNT_YES         constant number(1) := 1; -- ����������������
  
  /* ��������� - ������� ���������� ���������� ������� ���������� ������� ������� */  
  NQUEUE_EXEC_NO            constant number(1) := 0; -- �� ���������
  NQUEUE_EXEC_YES           constant number(1) := 1; -- ���������
  
  /* ��������� - ��������� ��������� ��������� ��������� ��������� ������� �� ������� �� */
  SPRC_RESP_ARGS            constant varchar2(80) := 'NIDENT,IN,NUMBER;NSRV_TYPE,IN,NUMBER;NEXSQUEUE,IN,NUMBER;'; -- ������ ���������� ��������� ���������

  /* �������� ���������� ������� ���������� */
  function UTL_APPSRV_IS_ACTIVE 
  return                    boolean;    -- ���� ���������� ������� ����������
  
  /* ������������ ������ �� ���������� �������� ������ */
  function UTL_STORED_MAKE_LINK
  (
    SPROCEDURE              in varchar2,        -- ��� ���������
    SPACKAGE                in varchar2 := null -- ��� ������
  ) return                  varchar2;           -- ������ �� ���������� �������� ������
  
  /* �������� ���������� ��������� ������� */
  procedure UTL_STORED_CHECK
  (
    NFLAG_SMART             in number,   -- ������� ��������� ���������� (0 - ��, 1 - ���)
    SPKG                    in varchar2, -- ��� ������
    SPRC                    in varchar2, -- ��� ���������
    SARGS                   in varchar2, -- ������ ���������� (";" - ����������� ����������, "," - ����������� ��������� ���������, ������: <��������>,<IN|OUT|IN OUT>,<��� ������ ORACLE>;)
    NRESULT                 out number   -- ��������� �������� (0 - ������, 1 - �����)
  );
  
  /* ������������ ������� ������������ ���������� ��� �������� ��������� ������ ��������� */
  function UTL_CONTAINER_MAKE_NAME
  (
    NIDENT                  in number,          -- ������������� ��������
    SSUB_CONTAINER          in varchar2 := null -- ������������ ���������� ������� ������
  )
  return                    varchar2;           -- ������ ������������ ����������  
  
  /* ������� ���������� ��� �������� ��������� ������ ��������� */
  procedure UTL_CONTAINER_PURGE
  (
    NIDENT                  in number,          -- ������������� ��������
    SSUB_CONTAINER          in varchar2 := null -- ������������ ���������� ������� ������
  );
  
  /* ���������� ���� ���������� ������� ���������� */
  function UTL_SCHED_CALC_NEXT_DATE
  (
    DEXEC_DATE              in date,    -- ���� ����������� ����������
    NRETRY_SCHEDULE         in number,  -- ������ ����������� (��. ��������� NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number   -- ��� ������� �����������
  ) 
  return                    date;       -- ���� ���������� �������
  
  /* ��������� ������������� ������� �� ���������� */
  function UTL_SCHED_CHECK_EXEC
  (
    DEXEC_DATE              in date,           -- ���� ����������� ����������
    NRETRY_SCHEDULE         in number,         -- ������ ����������� (��. ��������� NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number,         -- ��� ������� �����������
    DEXEC                   in date := sysdate -- ����, ������������ ������� ���������� ��������� ��������
  ) 
  return                    boolean;           -- ������� ������������� �������
  
  /* ��������� �������� ���� ������ ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_STR_SET
  (
    NIDENT                  in number,   -- ������������� ��������
    SARG                    in varchar2, -- ������������ ���������
    SVALUE                  in varchar2  -- �������� ���������
  );

  /* ��������� �������� ���� ����� ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_NUM_SET
  (
    NIDENT                  in number,   -- ������������� ��������
    SARG                    in varchar2, -- ������������ ���������
    NVALUE                  in number    -- �������� ���������
  );

  /* ��������� �������� ���� ���� ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_DATE_SET
  (
    NIDENT                  in number,   -- ������������� ��������
    SARG                    in varchar2, -- ������������ ���������
    DVALUE                  in date      -- �������� ���������
  );

  /* ��������� �������� ���� BLOB ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_BLOB_SET
  (
    NIDENT                  in number,   -- ������������� ��������
    SARG                    in varchar2, -- ������������ ���������
    BVALUE                  in blob      -- �������� ���������
  );
  
  /* ���������� �������� ���� ������ ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_STR_GET
  (
    NIDENT                  in number,  -- ������������� ��������
    SARG                    in varchar2 -- ������������ ���������
  ) return                  varchar2;   -- �������� ���������

  /* ���������� �������� ���� ����� ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_NUM_GET
  (
    NIDENT                  in number,  -- ������������� ��������
    SARG                    in varchar2 -- ������������ ���������
  ) return                  number;     -- �������� ���������

  /* ���������� �������� ���� ���� ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_DATE_GET
  (
    NIDENT                  in number,  -- ������������� ��������
    SARG                    in varchar2 -- ������������ ���������
  ) return                  date;       -- �������� ���������
  
  /* ���������� �������� ���� BLOB ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_BLOB_GET
  (
    NIDENT                  in number,  -- ������������� ��������
    SARG                    in varchar2 -- ������������ ���������
  ) return                  blob;       -- �������� ���������
  
  /* ������� ���������� � ����� ������ ���������� */
  procedure RNLIST_BASE_INSERT
  (
    NIDENT                  in number,  -- ������������� ������
    NDOCUMENT               in number,  -- ���. ����� ������ ���������
    NRN                     out number  -- ���. ����� ����������� ������ ������
  );
  
  /* ������� �������� �� ������ ������ ���������� */
  procedure RNLINST_BASE_DELETE
  (
    NRN                     in number   -- ���. ����� ������ ������
  );
  
  /* ������� ������� ������ ������ ���������� */
  procedure RNLIST_BASE_CLEAR
  (
    NIDENT                  in number   -- ������������� ������
  );  
  
  /* ��������� ������� */
  procedure SERVICE_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCSERVICE               out sys_refcursor -- ������ �� ������� ��������
  );
  
  /* ��������� ������� */
  procedure SERVICE_GET
  (
    NFLAG_SMART             in number,        -- ������� ������ ��������� �� ������
    NEXSSERVICE             in number,        -- ���. ����� ������ �������
    RCSERVICE               out sys_refcursor -- ������ �� ������� ��������
  );
  
  /* ��������� ������ �������� */
  procedure SERVICES_GET
  (
    RCSERVICES              out sys_refcursor -- ������ �� ������� ��������
  );

  /* ��������� ������� ������� */
  procedure SERVICEFN_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCSERVICEFN             out sys_refcursor -- ������ �� ������� ������� �������
  );  

  /* ��������� ������� ������� */
  procedure SERVICEFN_GET
  (
    NFLAG_SMART             in number,        -- ������� ������ ��������� �� ������
    NEXSSERVICEFN           in number,        -- ���. ����� ������� �������
    RCSERVICEFN             out sys_refcursor -- ������ �� ������� ������� �������
  );  
  
  /* ��������� ������ ������� ������� */
  procedure SERVICEFNS_GET
  (
    NEXSSERVICE             in number,        -- ���. ����� ������ �������
    RCSERVICEFNS            out sys_refcursor -- ������ �� ������� �������
  );
  
  /* ����� ������� ������� ������ �� ���� ������� � ���� ������� */
  function SERVICEFN_FIND_BY_SRVCODE
  (
    NFLAG_SMART             in number,   -- ������� ��������� ���������� (0 - ��, 1 - ���)
    SEXSSERVICE             in varchar2, -- �������� ������� ��� ���������
    SEXSSERVICEFN           in varchar2  -- �������� ������� ������� ��� ���������
  )
  return                    number;      -- ���. ����� ������� ������� ������

  /* ���������� ������ ������� ������ */
  procedure LOG_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCLOG                   out sys_refcursor -- ������ �� ������� ������� ������� ������
  );
  
  /* ���������� ������ ������� ������ */
  procedure LOG_GET
  (
    NFLAG_SMART             in number,        -- ������� ������ ��������� �� ������
    NEXSLOG                 in number,        -- ���. ����� ������ �������
    RCLOG                   out sys_refcursor -- ������ �� ������� ������� ������� ������
  );  
  
  /* ���������� ������ � ������ ������ */
  procedure LOG_PUT
  (
    NLOG_STATE              in number,         -- ��� ������ (��. ��������� NLOG_STATE*)
    SMSG                    in varchar2,       -- ���������
    NEXSSERVICE             in number := null, -- ���. ����� ���������� �������
    NEXSSERVICEFN           in number := null, -- ���. ����� ��������� ������� �������
    NEXSQUEUE               in number := null, -- ���. ����� ��������� ������ �������
    RCLOG                   out sys_refcursor  -- ������ �� ������� ��������
  );

  /* ���������� ��������� ������� */
  procedure QUEUE_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCQUEUE                 out sys_refcursor -- ������ � �������� �������
  );
  
  /* ���������� ��������� �� ������� */
  procedure QUEUE_GET
  (
    NFLAG_SMART             in number,        -- ������� ������ ��������� �� ������
    NEXSQUEUE               in number,        -- ���. ����� ������ �������
    RCQUEUE                 out sys_refcursor -- ������ � �������� �������
  );  
  
  /* �������� ������������� ���������� ���������� ��������� ������� */
  function QUEUE_SRV_TYPE_SEND_EXEC_CHECK
  (
    NEXSQUEUE               in number -- ���. ����� ������ �������
  )
  return                    number;   -- ���� ������������� ���������� ������� ������� (��. ��������� NQUEUE_EXEC_*)
  
  /* ���������� ��������� ������ ��������� ��������� �� ������� */
  procedure QUEUE_SRV_TYPE_SEND_GET
  (
    NPORTION_SIZE           in number,        -- ���������� ���������� ���������
    RCQUEUES                out sys_refcursor -- ������ �� ������� ������� �������
  );
 
  /* ��������� ��������� ������ ������� */
  procedure QUEUE_EXEC_STATE_SET
  (
    NEXSQUEUE               in number,        -- ���. ����� ������ �������
    NEXEC_STATE             in number,        -- ��������������� ���������
    SEXEC_MSG               in varchar2,      -- ��������� �����������
    NINC_EXEC_CNT           in number,        -- ���� ���������� �������� ���������� (��. ��������� NINC_EXEC_CNT_*, null - �� ������)
    RCQUEUE                 out sys_refcursor -- ������ � ��������� �������� �������    
  );
  
  /* ��������� ���������� ��������� ������ ������� */
  procedure QUEUE_RESP_SET
  (
    NEXSQUEUE               in number,        -- ���. ����� ������ �������  
    BRESP                   in blob,          -- ��������� ���������
    RCQUEUE                 out sys_refcursor -- ������ � ��������� �������� �������    
  );
  
  /* ��������� ��������� ������ � ������� */
  procedure QUEUE_PUT
  (
    NEXSSERVICEFN           in number,         -- ���. ����� ������� ���������
    BMSG                    in blob,           -- ������
    NEXSQUEUE               in number := null, -- ���. ����� ��������� ������� �������
    RCQUEUE                 out sys_refcursor  -- ������ � ����������� �������� �������    
  );
  
  /* ��������� ��������� ������ � ������� (�� ���� ������� � ������� ��������) */
  procedure QUEUE_PUT
  (
    SEXSSERVICE             in varchar2,       -- �������� ������� ��� ���������
    SEXSSERVICEFN           in varchar2,       -- �������� ������� ������� ��� ���������
    BMSG                    in blob,           -- ������
    NEXSQUEUE               in number := null, -- ���. ����� ��������� ������� �������
    RCQUEUE                 out sys_refcursor  -- ������ � ����������� �������� �������
  );
  
  /* ���������� ����������� ��� ��������� ������ */
  procedure QUEUE_PRC
  (
    NEXSQUEUE               in number,        -- ���. ����� ������ �������
    RCQUEUE                 out sys_refcursor -- ������ � ������������ �������� �������
  );
  
end;
/
create or replace package body PKG_EXS as

  /* �������� ���������� ������� ���������� */
  function UTL_APPSRV_IS_ACTIVE 
  return                    boolean     -- ���� ���������� ������� ����������
  is
  begin
    /* �������� ������� ������ ������� ���������� � ������� */
    for C in (select S.SID
                from V$SESSION S
               where UPPER(S.MODULE) = UPPER(SAPPSRV_MODULE_NAME)
                 and S.STATUS <> 'KILLED'
                 and UPPER(S.PROGRAM) = UPPER(SAPPSRV_PROGRAMM_NAME))
    loop
      return true;
    end loop;
    /* ������ ��� */
    return false;
  end UTL_APPSRV_IS_ACTIVE;
  
  /* ������������ ������ �� ���������� �������� ������ */
  function UTL_STORED_MAKE_LINK
  (
    SPROCEDURE              in varchar2,        -- ��� ���������
    SPACKAGE                in varchar2 := null -- ��� ������
  ) return                  varchar2            -- ������ �� ���������� �������� ������
  is
  begin
    /* �������� ��������� */
    if (SPROCEDURE is null) then
      P_EXCEPTION(0, '�� ������� ������������ �������� ���������.');
    end if;
    /* ������ ��������� */
    return PKG_OBJECT_DESC.STORED_NAME(SPACKAGE_NAME => SPACKAGE, SSTORED_NAME => SPROCEDURE);
  end UTL_STORED_MAKE_LINK;

  /* �������� ���������� ��������� ������� */
  procedure UTL_STORED_CHECK
  (
    NFLAG_SMART             in number,                  -- ������� ��������� ���������� (0 - ��, 1 - ���)
    SPKG                    in varchar2,                -- ��� ������
    SPRC                    in varchar2,                -- ��� ���������
    SARGS                   in varchar2,                -- ������ ���������� (";" - ����������� ����������, "," - ����������� ��������� ���������, ������: <��������>,<IN|OUT|IN OUT>,<��� ������ ORACLE>;)
    NRESULT                 out number                  -- ��������� �������� (0 - ������, 1 - �����)
  )
  is
    /* ��������� ���� ������ - ������ ��������� */
    type TARG is record
    (
      ARGUMENT_NAME         varchar2(30),               -- ��� ���������
      DATA_TYPE             varchar2(30),               -- ��� ������
      IN_OUT                varchar2(9),                -- ��� ���������
      CORRECT               number(1)                   -- ������� ���������� ��������
    );
    /* ��������� ���� ������ - ��������� ���������� */
    type TARGS_LIST is table of TARG;                   -- ��������� ����������
    /* ��������� �������������� */
    STORED                  PKG_OBJECT_DESC.TSTORED;    -- �������� ���������
    STORED_ARGS             PKG_OBJECT_DESC.TARGUMENTS; -- ��������� �������� ���������� ���������
    STORED_ARG              PKG_OBJECT_DESC.TARGUMENT;  -- �������� ��������� ���������
    RARGS_LIST              TARGS_LIST;                 -- ��������� ������������ ����������
    RARGS_LIST_CUR          TARGS_LIST;                 -- ��������� ���������� ����������
    NARGS_LIST_CUR_CORRECT  number(1);                  -- ������� ���������� �������� ���������� ����������
    SARGS_LIST              PKG_STD.TSTRING;            -- ���������� ������ ����������
    SARG                    PKG_STD.TSTRING;            -- ���������� �������� ���������
    SARG_TYPE               PKG_STD.TSTRING;            -- ��� ������ ���������
    SARG_TYPE_NAME          PKG_STD.TSTRING;            -- ��� ������ ��������� (��� ����������������� ���� ������)
    SINTERFACE              PKG_STD.TSTRING;            -- ��������� ��������� ���������
  begin
    /* �������� ��������� - ��� �������� ������� ������ ���� ������� */
    if (SPRC is null) then
      P_EXCEPTION(NFLAG_SMART, '�� ������� ��� ���������.');
      return;
    end if;
    /* �������� ��������� - � ������ ����������, ���� �� ����, ������ ���� ����������� */
    if (SARGS is not null) then
      if ((INSTR(SARGS, ';') = 0) or (INSTR(SARGS, ',') = 0)) then
        P_EXCEPTION(NFLAG_SMART,
                    '��������� ������ ������ ����������: ����������� ";" ��� ���������� ���������� � ������ � "," ��� ���������� ��������� ���������: <��������>,<IN|OUT|IN OUT>,<��� ������ ORACLE>;.');
        return;
      end if;
    end if;
    /* �������������� ��������� - ���� ������ */
    NRESULT := 0;
    /* �������� �������� �� */
    if (SPKG is not null) then
      /* ����� ������ */
      if (PKG_OBJECT_DESC.EXISTS_PACKAGE(SPACKAGE_NAME => SPKG) = 0) then
        P_EXCEPTION(NFLAG_SMART, '����� "%s" �� ������.', SPKG);
        return;
      end if;
      /* ����� ��������� � ������*/
      if (PKG_OBJECT_DESC.EXISTS_PROCEDURE(SPROCEDURE_NAME => UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG)) = 0) then
        P_EXCEPTION(NFLAG_SMART, '��������� "%s" � ������ "%s" �� �������.', SPRC, SPKG);
        return;
      end if;
    else
      /* ����� ��������� */
      if (PKG_OBJECT_DESC.EXISTS_PROCEDURE(SPROCEDURE_NAME => SPRC) = 0) then
        P_EXCEPTION(NFLAG_SMART,
                    '��������� "%s" �� �������.',
                    UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG));
        return;
      end if;
    end if;
    /* �������� �������� ��������� */
    begin
      STORED := PKG_OBJECT_DESC.DESC_STORED(SSTORED_NAME => UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG),
                                            BRAISE_ERROR => true);
    exception
      when others then
        P_EXCEPTION(NFLAG_SMART, sqlerrm);
        return;
    end;
    /* ��������� ���������� */
    if (STORED.STATUS != 'VALID') then
      P_EXCEPTION(NFLAG_SMART,
                  '��������� "%s" ����������������.',
                  UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG));
      return;
    end if;
    /* �������� �������� ���������� ��������� */
    begin
      STORED_ARGS := PKG_OBJECT_DESC.DESC_ARGUMENTS(SSTORED_NAME => UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC,
                                                                                         SPACKAGE   => SPKG),
                                                    BRAISE_ERROR => true);
    exception
      when others then
        P_EXCEPTION(NFLAG_SMART, sqlerrm);
        return;
    end;
    /* �������������� ��������� ����������� ��������� ���������� ���������� ��������� */
    RARGS_LIST := TARGS_LIST();
    for I in 1 .. PKG_OBJECT_DESC.COUNT_ARGUMENTS(RARGUMENTS => STORED_ARGS)
    loop
      /* ����������� ���������� ��������� �� ������ */
      STORED_ARG := PKG_OBJECT_DESC.FETCH_ARGUMENT(RARGUMENTS => STORED_ARGS, IINDEX => I);
      /* ���������� ��������� � ��������� */
      RARGS_LIST.EXTEND();
      /* ���������� ����� ��������� */
      RARGS_LIST(RARGS_LIST.LAST).ARGUMENT_NAME := STORED_ARG.ARGUMENT_NAME;
      /* ���������� ���� ��������� */
      RARGS_LIST(RARGS_LIST.LAST).IN_OUT := STORED_ARG.DB_IN_OUT;
      /* ���������� ���� ������ ��������� */
      RARGS_LIST(RARGS_LIST.LAST).DATA_TYPE := STORED_ARG.DB_DATA_TYPE;
      if (RARGS_LIST(RARGS_LIST.LAST).DATA_TYPE in ('PL/SQL RECORD')) then
        P_EXCEPTION(NFLAG_SMART,
                    '���������� ��������� ��������� ���������������� ���������: �������������� ������ ������� ���� ������ ����������!');
        return;
      end if;
      /* ��������� �������� - �� ��������� */
      RARGS_LIST(RARGS_LIST.LAST).CORRECT := 0;
    end loop;
    /* �������� ���������� ���������� */
    if (SARGS is not null) then
      /* �������������� ��������� ���������� ������ ���������� ��������� */
      SARGS_LIST     := replace(UPPER(SARGS), ' ', '');
      RARGS_LIST_CUR := TARGS_LIST();
      /* ���� �� ������ ���������� */
      loop
        /* ���������� ��������� �� ������ */
        SARG := STRTOK(source => SARGS_LIST, DELIMETER => ';', ITEM => 1);
        /* ���� ����� - ����� �� �����*/
        if (SARG is null) then
          exit;
        end if;
        /* ���������� ��������� � ��������� */
        RARGS_LIST_CUR.EXTEND();
        /* ��������� �������� - �� ��������� */
        RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).CORRECT := 0;
        /* ���������� ����� ��������� */
        RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).ARGUMENT_NAME := STRTOK(source => SARG, DELIMETER => ',', ITEM => 1);
        /* ���������� ���� ��������� */
        RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).IN_OUT := STRTOK(source => SARG, DELIMETER => ',', ITEM => 2);
        /* ���������� ���� ������ ��������� */
        SARG_TYPE      := STRTOK(source => SARG, DELIMETER => ',', ITEM => 3);
        SARG_TYPE_NAME := STRTOK(source => SARG_TYPE, DELIMETER => '.', ITEM => 2);
        if (SARG_TYPE_NAME is not null) then
          /* ���� ���������������� ��� ������ */
          P_EXCEPTION(NFLAG_SMART,
                      '���������� ��������� ��������� ���������������� ���������: �������������� ������ ������� ���� ������!');
          return;
        else
          /* ���� ����������� ��� ������ */
          RARGS_LIST_CUR(RARGS_LIST_CUR.LAST).DATA_TYPE := SARG_TYPE;
        end if;
        SARG_TYPE := null;
        /* �������� ������������� ��������� �� �������� ������ */
        SARGS_LIST := replace(SARGS_LIST, SARG || ';');
      end loop;
      /* �������� ���������� */
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
      /* ���� ���� �� ���� �������� �� ��������� - ������ */
      NARGS_LIST_CUR_CORRECT := 1;
      for I in RARGS_LIST_CUR.FIRST .. RARGS_LIST_CUR.LAST
      loop
        if (RARGS_LIST_CUR(I).CORRECT = 0) then
          NARGS_LIST_CUR_CORRECT := 0;
        end if;
      end loop;
      /* ��������� ���������� */
      NRESULT := NARGS_LIST_CUR_CORRECT;
      /* ��������� ��������� �� ��������� ���������� */
      SINTERFACE := RTRIM(replace(replace(replace(UPPER(SARGS), ' ', ''), ',', ' '), ';', ';' || CHR(13)),
                          ';' || CHR(13));
    else
      /* ���� ��������� �� ��������� � �� ��� � ������ ���������� ���������� ��������� */
      if (RARGS_LIST.COUNT = 0) then
        /* �� �������� �������� */
        NRESULT := 1;
      end if;
      /* ��������� ��������� �� ��������� ���������� */
      SINTERFACE := '��� ����������';
    end if;
    /* ���� �������� �� �������� */
    if (NRESULT = 0) then
      /* ����� ��������� �� ������, ���� �������, � ��������� ���������� ���������� ��������� */
      P_EXCEPTION(NFLAG_SMART,
                  '��� ��������� "%s" �������� ��������� ��������� ������: %s.',
                  UTL_STORED_MAKE_LINK(SPROCEDURE => SPRC, SPACKAGE => SPKG),
                  CHR(13) || SINTERFACE);
    end if;
  end UTL_STORED_CHECK;
  
  /* ������������ ������� ������������ ���������� ��� �������� ��������� ������ ��������� */
  function UTL_CONTAINER_MAKE_NAME
  (
    NIDENT                  in number,          -- ������������� ��������
    SSUB_CONTAINER          in varchar2 := null -- ������������ ���������� ������� ������
  )
  return                    varchar2            -- ������ ������������ ����������
  is
    /* ������������ ������� ������������ ���������� */
    function CONTAINER_MAKE_NAME
    (
      SCONT                 in varchar2,        -- ������������
      SPREFIX               in varchar2 := null -- �������
    ) return                varchar2            -- ������ ������������ ����������
    is
    begin
      /* �������� ��������� */
      if (SCONT is null) then
        P_EXCEPTION(0, '�� ������� ������������ ����������.');
      end if;
      /* ���������� ������ ������������ � ������ �������� */
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

  /* ������� ���������� ��� �������� ��������� ������ ��������� */
  procedure UTL_CONTAINER_PURGE
  (
    NIDENT                  in number,          -- ������������� ��������
    SSUB_CONTAINER          in varchar2 := null -- ������������ ���������� ������� ������
  )
  is
  begin
    PKG_CONTVARGLB.PURGE(SCONTAINER => UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT, SSUB_CONTAINER => SSUB_CONTAINER));
  end UTL_CONTAINER_PURGE;
  
  /* ���������� ���� ���������� ������� ���������� */
  function UTL_SCHED_CALC_NEXT_DATE
  (
    DEXEC_DATE              in date,    -- ���� ����������� ����������
    NRETRY_SCHEDULE         in number,  -- ������ ����������� (��. ��������� NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number   -- ��� ������� �����������
  ) 
  return                    date        -- ���� ���������� �������
  is
  begin
    /* ���� ��� ���� ����������� ������� ��� ���������� �� ����������, �� ���� ���������� ������� - ��� ������� ���� */
    if (DEXEC_DATE is null) or (NRETRY_SCHEDULE = NRETRY_SCHEDULE_UNDEF) then
      /* ������� ������� - ��� �������� */
      return sysdate -(1 / (24 * 60));
    else
      /* ��������� � ����������� �� ���� ���������� */
      case NRETRY_SCHEDULE
        /* ����������� */
        when NRETRY_SCHEDULE_SEC then
          begin
            return DEXEC_DATE +(1 / (24 * 60 * 60)) * NRETRY_STEP;
          end;
        /* ���������� */
        when NRETRY_SCHEDULE_MIN then
          begin
            return DEXEC_DATE +(1 / (24 * 60)) * NRETRY_STEP;
          end;
        /* �������� */
        when NRETRY_SCHEDULE_HOUR then
          begin
            return DEXEC_DATE +(1 / 24) * NRETRY_STEP;
          end;
        /* ��������� */
        when NRETRY_SCHEDULE_DAY then
          begin
            return DEXEC_DATE + 1 * NRETRY_STEP;
          end;
        /* ����������� */
        when NRETRY_SCHEDULE_WEEK then
          begin
            return DEXEC_DATE +(1 * 7) * NRETRY_STEP;
          end;
        /* ���������� */
        when NRETRY_SCHEDULE_MONTH then
          begin
            return ADD_MONTHS(DEXEC_DATE, NRETRY_STEP);
          end;
        /* ���������������� ��� ���������� */
        else
          return null;
      end case;
    end if;
    return null;
  exception
    when others then
      return null;
  end UTL_SCHED_CALC_NEXT_DATE;

  /* ��������� ������������� ������� �� ���������� */
  function UTL_SCHED_CHECK_EXEC
  (
    DEXEC_DATE              in date,           -- ���� ����������� ����������
    NRETRY_SCHEDULE         in number,         -- ������ ����������� (��. ��������� NRETRY_SCHEDULE_*)
    NRETRY_STEP             in number,         -- ��� ������� �����������
    DEXEC                   in date := sysdate -- ����, ������������ ������� ���������� ��������� ��������
  ) 
  return                    boolean            -- ������� ������������� �������
  is
    DEXEC_NEXT              date;              -- H�������� ���� ���������� �������
  begin
    /* ��������� ���� ���������� ������� */
    DEXEC_NEXT := UTL_SCHED_CALC_NEXT_DATE(DEXEC_DATE      => DEXEC_DATE,
                                           NRETRY_SCHEDULE => NRETRY_SCHEDULE,
                                           NRETRY_STEP     => NRETRY_STEP);
    /* ���� �� ����������� - �� ��������� �� ����� */
    if (DEXEC_NEXT is null) then
      return false;
    end if;
    /* ���� ��� ������ ��������� - ���� ��������� */
    if (DEXEC_NEXT <= DEXEC) then
      return true;
    end if;
    /* �������� �� ���� */
    return false;
  exception
    when others then
      return false;
  end UTL_SCHED_CHECK_EXEC;
  
  /* ��������� �������� ���� ������ ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_STR_SET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2,     -- ������������ ���������
    SVALUE                  in varchar2      -- �������� ���������
  )
  is
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ��������� �������� */
    PKG_CONTVARGLB.PUTS(SCONTAINER => SCONTAINER, SNAME => SARG, SVALUE => SVALUE);
  end PRC_RESP_ARG_STR_SET;

  /* ��������� �������� ���� ����� ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_NUM_SET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2,     -- ������������ ���������
    NVALUE                  in number        -- �������� ���������
  )
  is
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ��������� �������� */
    PKG_CONTVARGLB.PUTN(SCONTAINER => SCONTAINER, SNAME => SARG, NVALUE => NVALUE);
  end PRC_RESP_ARG_NUM_SET;

  /* ��������� �������� ���� ���� ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_DATE_SET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2,     -- ������������ ���������
    DVALUE                  in date          -- �������� ���������
  )
  is
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ��������� �������� */
    PKG_CONTVARGLB.PUTD(SCONTAINER => SCONTAINER, SNAME => SARG, DVALUE => DVALUE);
  end PRC_RESP_ARG_DATE_SET;

  /* ��������� �������� ���� BLOB ��������� ��������� ��������� ��������� ������ */
  procedure PRC_RESP_ARG_BLOB_SET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2,     -- ������������ ���������
    BVALUE                  in blob          -- �������� ���������
  )
  is
    NFILE_IDENT             PKG_STD.TREF;    -- ������������� ������ ��� �������� ���������� ���������
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* �������� ���������� ��������� � �������� ����� */
    NFILE_IDENT := GEN_IDENT();
    P_FILE_BUFFER_INSERT(NIDENT => NFILE_IDENT, CFILENAME => NFILE_IDENT, CDATA => null, BLOBDATA => BVALUE);
    /* �������� ������ � ��������� */
    PKG_CONTVARGLB.PUTN(SCONTAINER => SCONTAINER, SNAME => SARG, NVALUE => NFILE_IDENT);
  end PRC_RESP_ARG_BLOB_SET;  
  
  /* ���������� �������� ���� ������ ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_STR_GET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2      -- ������������ ���������
  ) return                  varchar2         -- �������� ���������
  is
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ������� � ����� �������� */
    return PKG_CONTVARGLB.GETS(SCONTAINER => SCONTAINER, SNAME => SARG);
  end PRC_RESP_ARG_STR_GET;

  /* ���������� �������� ���� ����� ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_NUM_GET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2      -- ������������ ���������
  ) return                  number           -- �������� ���������
  is
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ������� � ����� �������� */
    return PKG_CONTVARGLB.GETN(SCONTAINER => SCONTAINER, SNAME => SARG);
  end PRC_RESP_ARG_NUM_GET;

  /* ���������� �������� ���� ���� ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_DATE_GET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2      -- ������������ ���������
  ) return                  date             -- �������� ���������
  is
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ������� � ����� �������� */
    return PKG_CONTVARGLB.GETD(SCONTAINER => SCONTAINER, SNAME => SARG);
  end PRC_RESP_ARG_DATE_GET;
  
  /* ���������� �������� ���� BLOB ��������� ��������� ��������� ��������� ������ */
  function PRC_RESP_ARG_BLOB_GET
  (
    NIDENT                  in number,       -- ������������� ��������
    SARG                    in varchar2      -- ������������ ���������
  ) return                  blob             -- �������� ���������
  is
    NFILE_IDENT             PKG_STD.TREF;    -- ������������� ������ ��� �������� ���������� ���������
    SCONTAINER              PKG_STD.TSTRING; -- ������������ ����������
    BRESP                   blob;            -- ����� ��� ��������
  begin
    /* ���������� ������������ ���������� */
    SCONTAINER := UTL_CONTAINER_MAKE_NAME(NIDENT => NIDENT);
    /* ������� �������� �������������� ������ �� ���������� */
    NFILE_IDENT := PKG_CONTVARGLB.GETN(SCONTAINER => SCONTAINER, SNAME => SARG);
    /* ������� ���������� ��������� �� ��������� ������ */
    begin
      select T.BDATA into BRESP from FILE_BUFFER T where T.IDENT = NFILE_IDENT;
    exception
      when NO_DATA_FOUND then
        P_EXCEPTION(0,
                    '���������� ��������� �� ������� � ������ (IDENT: %s).',
                    TO_CHAR(NFILE_IDENT));
      when TOO_MANY_ROWS then
        P_EXCEPTION(0,
                    '���������� ��������� �� ���������� ���������� (IDENT: %s).',
                    TO_CHAR(NFILE_IDENT));
    end;
    /* �������� �������� ����� */
    P_FILE_BUFFER_CLEAR(NIDENT => NFILE_IDENT);    
    /* ����� �������� */
    return BRESP;
  end PRC_RESP_ARG_BLOB_GET;  

  /* ������� ���������� � ����� ������ ���������� */
  procedure RNLIST_BASE_INSERT
  (
    NIDENT                  in number,  -- ������������� ������
    NDOCUMENT               in number,  -- ���. ����� ������ ���������
    NRN                     out number  -- ���. ����� ����������� ������ ������
  )
  is
  begin
    /* ���������� ���. ����� */
    NRN := GEN_ID();
    /* ��������� ������ */
    insert into EXSRNLIST (RN, IDENT, DOCUMENT) values (NRN, NIDENT, NDOCUMENT);
  end RNLIST_BASE_INSERT;
  
  /* ������� �������� �� ������ ������ ���������� */
  procedure RNLINST_BASE_DELETE
  (
    NRN                     in number   -- ���. ����� ������ ������
  )
  is
  begin
    /* ������ ������ */
    delete from EXSRNLIST T where T.RN = NRN;
  end RNLINST_BASE_DELETE;
  
  /* ������� ������� ������ ������ ���������� */
  procedure RNLIST_BASE_CLEAR
  (
    NIDENT                  in number   -- ������������� ������
  )
  is
  begin
    /* ������� ����� */
    for C in (select T.RN from EXSRNLIST T where T.IDENT = NIDENT)
    loop
      /* ������� ��� ������ */
      RNLINST_BASE_DELETE(NRN => C.RN);
    end loop;
  end RNLIST_BASE_CLEAR;
  
  /* ��������� ������� */
  procedure SERVICE_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCSERVICE               out sys_refcursor -- ������ �� ������� ��������
  )
  is
  begin
    /* ����� ������ �������� � ���� ������� */
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
  
  /* ��������� ������� */
  procedure SERVICE_GET
  (
    NFLAG_SMART             in number,          -- ������� ������ ��������� �� ������
    NEXSSERVICE             in number,          -- ���. ����� ������ �������
    RCSERVICE               out sys_refcursor   -- ������ �� ������� ��������
  )
  is
    REXSSERVICE             EXSSERVICE%rowtype; -- ������ �������
    NIDENT                  PKG_STD.TREF;       -- ������������� ������
    NTMP                    PKG_STD.TREF;       -- ���. ����� ��������� ������ ������
  begin
    /* ������� ������ ������� */
    REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSSERVICE);
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ���. ����� ������� � ����� */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSSERVICE.RN, NEXSSERVICE), NRN => NTMP);
    /* �������� ������ � ���� ������� */
    SERVICE_GET(NIDENT => NIDENT, RCSERVICE => RCSERVICE);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICE_GET;
  
  /* ��������� ������ �������� */
  procedure SERVICES_GET
  (
    RCSERVICES              out sys_refcursor -- ������ �� ������� ��������
  )
  is
    NIDENT                  PKG_STD.TREF;     -- ������������� ������
    NTMP                    PKG_STD.TREF;     -- ���. ����� ��������� ������ ������
  begin
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ������ ������� */
    for C in (select T.RN from EXSSERVICE T)
    loop
      /* ���������� �� ���. ������ � ������ */
      RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => C.RN, NRN => NTMP);
    end loop;
    /* �������� ���������� ������� */
    SERVICE_GET(NIDENT => NIDENT, RCSERVICE => RCSERVICES);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICES_GET;  
  
  /* ��������� ������� ������� */
  procedure SERVICEFN_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCSERVICEFN             out sys_refcursor -- ������ �� ������� ������� �������
  )
  is
  begin
    /* ����� ������ ������� � ���� ������� */
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
  
  /* ��������� ������� ������� */
  procedure SERVICEFN_GET
  (
    NFLAG_SMART             in number,            -- ������� ������ ��������� �� ������
    NEXSSERVICEFN           in number,            -- ���. ����� ������� �������
    RCSERVICEFN             out sys_refcursor     -- ������ �� ������� ������� �������
  )
  is
    REXSSERVICEFN           EXSSERVICEFN%rowtype; -- ������ ������� �������
    NIDENT                  PKG_STD.TREF;         -- ������������� ������
    NTMP                    PKG_STD.TREF;         -- ���. ����� ��������� ������ ������
  begin
    /* ������� ������ ������� ������� */
    REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSSERVICEFN);
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ���. ����� ������� ������� � ����� */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSSERVICEFN.RN, NEXSSERVICEFN), NRN => NTMP);
    /* �������� ������ � ���� ������� */
    SERVICEFN_GET(NIDENT => NIDENT, RCSERVICEFN => RCSERVICEFN);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICEFN_GET;
  
  /* ��������� ������ ������� ������� */
  procedure SERVICEFNS_GET
  (
    NEXSSERVICE             in number,        -- ���. ����� ������ �������
    RCSERVICEFNS            out sys_refcursor -- ������ �� ������� �������
  )
  is
    NIDENT                  PKG_STD.TREF;     -- ������������� ������
    NTMP                    PKG_STD.TREF;     -- ���. ����� ��������� ������ ������
  begin
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ������� ������� */
    for C in (select T.RN from EXSSERVICEFN T where T.PRN = NEXSSERVICE)
    loop
      /* ���������� �� ���. ������ � ������ */
      RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => C.RN, NRN => NTMP);
    end loop;
    /* �������� ���������� ������� ������� */
    SERVICEFN_GET(NIDENT => NIDENT, RCSERVICEFN => RCSERVICEFNS);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end SERVICEFNS_GET;
  
  /* ����� ������� ������� ������ �� ���� ������� � ���� ������� */
  function SERVICEFN_FIND_BY_SRVCODE
  (
    NFLAG_SMART             in number,    -- ������� ��������� ���������� (0 - ��, 1 - ���)
    SEXSSERVICE             in varchar2,  -- �������� ������� ��� ���������
    SEXSSERVICEFN           in varchar2   -- �������� ������� ������� ��� ���������
  )
  return                    number        -- ���. ����� ������� ������� ������
  is
    NEXSSERVICEFN           PKG_STD.TREF; -- ���. ����� ������� ������� ���������  
  begin
    /* ������ ������� ������� ��������� */
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
                    '������� "%s" ������� ������ "%s" �� ����������',
                    SEXSSERVICEFN,
                    SEXSSERVICE);
    end;
    /* ������ ��������� */
    return NEXSSERVICEFN;
  end SERVICEFN_FIND_BY_SRVCODE;
  
  /* ���������� ������ ������� ������ */
  procedure LOG_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCLOG                   out sys_refcursor -- ������ �� ������� ������� ������� ������
  )
  is
  begin
    /* ����� ������ � ���� ������� */
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
  
  /* ���������� ������ ������� ������ */
  procedure LOG_GET
  (
    NFLAG_SMART             in number,        -- ������� ������ ��������� �� ������    
    NEXSLOG                 in number,        -- ���. ����� ������ �������
    RCLOG                   out sys_refcursor -- ������ �� ������� ������� ������� ������
  )
  is
    REXSLOG                 EXSLOG%rowtype;   -- ������ ������� ������
    NIDENT                  PKG_STD.TREF;     -- ������������� ������
    NTMP                    PKG_STD.TREF;     -- ���. ����� ��������� ������ ������
  begin
    /* ������� ������ ������� ������ */
    REXSLOG := GET_EXSLOG_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSLOG);
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ���. ����� ������ ������� ������ � ����� */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSLOG.RN, NEXSLOG), NRN => NTMP);
    /* �������� ������� ������� � ���� ������� */
    LOG_GET(NIDENT => NIDENT, RCLOG => RCLOG);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end LOG_GET;

  /* ���������� ������ � ������ ������ */
  procedure LOG_PUT
  (
    NLOG_STATE              in number,            -- ��� ������ (��. ��������� NLOG_STATE*)
    SMSG                    in varchar2,          -- ���������
    NEXSSERVICE             in number := null,    -- ���. ����� ���������� �������
    NEXSSERVICEFN           in number := null,    -- ���. ����� ��������� ������� �������
    NEXSQUEUE               in number := null,    -- ���. ����� ��������� ������ �������
    RCLOG                   out sys_refcursor     -- ������ �� ������� ��������
  )
  is
    NEXSSERVICE_            EXSSERVICE.RN%type;   -- ���. ����� ���������� ������� (��� ��������������� �����������)
    NEXSSERVICEFN_          EXSSERVICEFN.RN%type; -- ���. ����� ��������� ������� ������� (��� ��������������� �����������)
    NEXSLOG                 PKG_STD.TREF;         -- ���. ����� ����������� ������ �������
  begin
    /* ���������������� ���������������� ������� � ������ */
    NEXSSERVICE_   := NEXSSERVICE;
    NEXSSERVICEFN_ := NEXSSERVICEFN;
    /* ���� ������ ������� ������� - ���������� �� ��� ������ */
    if (NEXSSERVICEFN is not null) then
      begin
        select T.PRN into NEXSSERVICE_ from EXSSERVICEFN T where T.RN = NEXSSERVICEFN;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSSERVICEFN, SUNIT_TABLE => 'EXSSERVICEFN');
      end;
    end if;
    /* ���� ������ ������� ������� - ���������� �� ��� � ������� � ������ */
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
    /* ������� ������ � �������� ������ */
    P_EXSLOG_BASE_INSERT(DLOG_DATE     => sysdate,
                         NLOG_STATE    => NLOG_STATE,
                         SMSG          => SMSG,
                         NEXSSERVICE   => NEXSSERVICE_,
                         NEXSSERVICEFN => NEXSSERVICEFN_,
                         NEXSQUEUE     => NEXSQUEUE,
                         NRN           => NEXSLOG);
    /* ������ ����������� ������ */
    LOG_GET(NFLAG_SMART => 0, NEXSLOG => NEXSLOG, RCLOG => RCLOG);                         
  end LOG_PUT;

  /* ���������� ��������� �� ������� */
  procedure QUEUE_GET
  (
    NIDENT                  in number,        -- ������������� ������
    RCQUEUE                 out sys_refcursor -- ������ � �������� �������
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
  
  /* ���������� ��������� �� ������� */
  procedure QUEUE_GET
  (
    NFLAG_SMART             in number,        -- ������� ������ ��������� �� ������    
    NEXSQUEUE               in number,        -- ���. ����� ������ �������
    RCQUEUE                 out sys_refcursor -- ������ � �������� �������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
    NIDENT                  PKG_STD.TREF;     -- ������������� ������
    NTMP                    PKG_STD.TREF;     -- ���. ����� ��������� ������ ������
  begin
    /* ������� ������ ������� ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => NFLAG_SMART, NRN => NEXSQUEUE);
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ���. ����� ������ ������� � ����� */
    RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => NVL(REXSQUEUE.RN, NEXSQUEUE), NRN => NTMP);
    /* �������� ������� ������� � ���� ������� */
    QUEUE_GET(NIDENT => NIDENT, RCQUEUE => RCQUEUE);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end QUEUE_GET;
  
  /* �������� ������������� ���������� ������� ������� */
  function QUEUE_SRV_TYPE_SEND_EXEC_CHECK
  (
    NEXSQUEUE               in number -- ���. ����� ������ �������
  )
  return                    number    -- ���� ������������� ���������� ������� ������� (��. ��������� NQUEUE_EXEC_*)
  is
    REXSQUEUE               EXSQUEUE%rowtype;          -- ������ ������� �������
    REXSSERVICE             EXSSERVICE%rowtype;        -- ������ ������� ���������
    REXSSERVICEFN           EXSSERVICEFN%rowtype;      -- ������ ������� ���������
    NRESULT                 number(17); -- ��������� ������
  begin
    /* �������������� ��������� */
    NRESULT := NQUEUE_EXEC_NO;
    begin
      /* ������� ������ ������� */
      REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
      /* ������� ������ ������� ��������� */
      REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 0, NRN => REXSQUEUE.EXSSERVICEFN);
      /* ������� ������ ������� ��������� */
      REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => REXSSERVICEFN.PRN);
      /* �������� ������� ���������� - ���������, �������������, � �������� ������� */
      if ((REXSSERVICE.SRV_TYPE = NSRV_TYPE_SEND) and
         (REXSQUEUE.EXEC_STATE in
         (NQUEUE_EXEC_STATE_INQUEUE, NQUEUE_EXEC_STATE_APP_ERR, NQUEUE_EXEC_STATE_DB_ERR, NQUEUE_EXEC_STATE_ERR)) and
         (((REXSSERVICEFN.RETRY_SCHEDULE <> NRETRY_SCHEDULE_UNDEF) and
         (REXSQUEUE.EXEC_CNT < REXSSERVICEFN.RETRY_ATTEMPTS)) or
         ((REXSSERVICEFN.RETRY_SCHEDULE = NRETRY_SCHEDULE_UNDEF) and (REXSQUEUE.EXEC_CNT = 0))) and
         (UTL_SCHED_CHECK_EXEC(DEXEC_DATE      => REXSQUEUE.EXEC_DATE,
                                NRETRY_SCHEDULE => REXSSERVICEFN.RETRY_SCHEDULE,
                                NRETRY_STEP     => REXSSERVICEFN.RETRY_STEP))) then
        /* ���� ��������� */
        NRESULT := NQUEUE_EXEC_YES;
      end if;
    exception
      when others then
        NRESULT := NQUEUE_EXEC_NO;
    end;
    /* ����� ��������� */
    return NRESULT;
  end QUEUE_SRV_TYPE_SEND_EXEC_CHECK;
  
  /* ���������� ��������� ������ ��������� ��������� �� ������� */
  procedure QUEUE_SRV_TYPE_SEND_GET
  (
    NPORTION_SIZE           in number,        -- ���������� ���������� ���������
    RCQUEUES                out sys_refcursor -- ������ �� ������� ������� �������
  )
  is
    NIDENT                  PKG_STD.TREF;     -- ������������� ������
    NTMP                    PKG_STD.TREF;     -- ���. ����� ��������� ������ ������
  begin
    /* ���������� ������������� ������ */
    NIDENT := GEN_IDENT();
    /* ������� ��������� ��������� ��������� */
    for C in (select *
                from (select T.RN
                        from EXSQUEUE T
                       where QUEUE_SRV_TYPE_SEND_EXEC_CHECK(T.RN) = NQUEUE_EXEC_YES
                       order by T.IN_DATE)
               where ROWNUM <= NPORTION_SIZE)
    loop
      /* ���������� �� ���. ������ � ������ */
      RNLIST_BASE_INSERT(NIDENT => NIDENT, NDOCUMENT => C.RN, NRN => NTMP);
    end loop;
    /* �������� ���������� ������ ������� */
    QUEUE_GET(NIDENT => NIDENT, RCQUEUE => RCQUEUES);
    /* ������ ����� */
    RNLIST_BASE_CLEAR(NIDENT => NIDENT);
  end QUEUE_SRV_TYPE_SEND_GET;

  /* ��������� ��������� ������ ������� */
  procedure QUEUE_EXEC_STATE_SET
  (
    NEXSQUEUE               in number,        -- ���. ����� ������ �������
    NEXEC_STATE             in number,        -- ��������������� ���������
    SEXEC_MSG               in varchar2,      -- ��������� �����������
    NINC_EXEC_CNT           in number,        -- ���� ���������� �������� ���������� (��. ��������� NINC_EXEC_CNT_*, null - �� ������)
    RCQUEUE                 out sys_refcursor -- ������ � ��������� �������� �������    
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype; -- ������ ������� �������
  begin
    /* �������� ��������� */
    if (NEXSQUEUE is null) then
      P_EXCEPTION(0,
                  '�� ������ ������������� ������� ������� ��� ��������� ���������');
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
                  '��� ��������� "%s" ������� ������� �� ��������������',
                  TO_CHAR(NEXEC_STATE));
    end if;
    if (NVL(NINC_EXEC_CNT, NINC_EXEC_CNT_NO) not in (NINC_EXEC_CNT_YES, NINC_EXEC_CNT_NO)) then
      P_EXCEPTION(0,
                  '���� ��������� �������� ���������� "%s" ������� ������� �� ��������������',
                  TO_CHAR(NINC_EXEC_CNT));
    end if;
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* �������� ������� ���������� ������� ����������, ���� ������� */
    if (NVL(NINC_EXEC_CNT, NINC_EXEC_CNT_NO) = NINC_EXEC_CNT_YES) then
      REXSQUEUE.EXEC_CNT := REXSQUEUE.EXEC_CNT + 1;
    end if;
    /* �������� ��������� */
    update EXSQUEUE T
       set T.EXEC_DATE  = sysdate,
           T.EXEC_STATE = NEXEC_STATE,
           T.EXEC_CNT   = REXSQUEUE.EXEC_CNT,
           T.EXEC_MSG   = SEXEC_MSG
     where T.RN = NEXSQUEUE;
    if (sql%rowcount = 0) then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSQUEUE, SUNIT_TABLE => 'EXSQUEUE');
    end if;
    /* ������ ���������� ������� ������� */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => NEXSQUEUE, RCQUEUE => RCQUEUE);
  end QUEUE_EXEC_STATE_SET;
  
  /* ��������� ���������� ��������� ������ ������� */
  procedure QUEUE_RESP_SET
  (
    NEXSQUEUE               in number,        -- ���. ����� ������ �������  
    BRESP                   in blob,          -- ��������� ���������
    RCQUEUE                 out sys_refcursor -- ������ � ��������� �������� �������            
  )
  is
  begin
    /* �������� ��������� */
    update EXSQUEUE T set T.RESP = BRESP where T.RN = NEXSQUEUE;
    if (sql%rowcount = 0) then
      PKG_MSG.RECORD_NOT_FOUND(NFLAG_SMART => 0, NDOCUMENT => NEXSQUEUE, SUNIT_TABLE => 'EXSQUEUE');
    end if;
    /* ������ ���������� ������� ������� */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => NEXSQUEUE, RCQUEUE => RCQUEUE);
  end QUEUE_RESP_SET;

  /* ��������� ��������� ������ � ������� */
  procedure QUEUE_PUT
  (
    NEXSSERVICEFN           in number,         -- ���. ����� ������� ���������
    BMSG                    in blob,           -- ������
    NEXSQUEUE               in number := null, -- ���. ����� ��������� ������� �������
    RCQUEUE                 out sys_refcursor  -- ������ � ����������� �������� �������    
  )
  is
    NRN                     EXSQUEUE.RN%type;  -- ���. ����� ����������� ������ �������
  begin
    /* ��������� ��������� */
    if (NEXSSERVICEFN is null) then
      P_EXCEPTION(0, '�� ������ ������������� ������� ������� ������');
    end if;
    /* ������ ������ � ������� */
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
    /* ���������� ����������� ������� ������� */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => NRN, RCQUEUE => RCQUEUE);
  end QUEUE_PUT;

  /* ��������� ��������� ������ � ������� (�� ���� ������� � ������� ��������) */
  procedure QUEUE_PUT
  (
    SEXSSERVICE             in varchar2,       -- �������� ������� ��� ���������
    SEXSSERVICEFN           in varchar2,       -- �������� ������� ������� ��� ���������
    BMSG                    in blob,           -- ������
    NEXSQUEUE               in number := null, -- ���. ����� ��������� ������� �������
    RCQUEUE                 out sys_refcursor  -- ������ � ����������� �������� �������
  )
  is
    NEXSSERVICEFN           PKG_STD.TREF;      -- ���. ����� ������� ������� ���������
  begin
    /* ��������� ��������� */
    if (SEXSSERVICE is null) then
      P_EXCEPTION(0, '�� ������ ��� ������� ������');
    end if;
    if (SEXSSERVICEFN is null) then
      P_EXCEPTION(0, '�� ������ ��� ������� ������� ������');
    end if;
    /* ���������� ������� ������� */
    NEXSSERVICEFN := SERVICEFN_FIND_BY_SRVCODE(NFLAG_SMART   => 0,
                                               SEXSSERVICE   => SEXSSERVICE,
                                               SEXSSERVICEFN => SEXSSERVICEFN);
    /* ������ ������ � ������� */
    QUEUE_PUT(NEXSSERVICEFN => NEXSSERVICEFN, BMSG => BMSG, NEXSQUEUE => NEXSQUEUE, RCQUEUE => RCQUEUE);
  end QUEUE_PUT;
  
  /* ���������� ����������� ��� ��������� ������ */
  procedure QUEUE_PRC
  (
    NEXSQUEUE               in number,                 -- ���. ����� ������ �������
    RCQUEUE                 out sys_refcursor          -- ������ � ������������ �������� �������
  )
  is
    REXSQUEUE               EXSQUEUE%rowtype;          -- ������ ������� �������
    REXSSERVICE             EXSSERVICE%rowtype;        -- ������ ������� ���������
    REXSSERVICEFN           EXSSERVICEFN%rowtype;      -- ������ ������� ���������
    REXSMSGTYPE             EXSMSGTYPE%rowtype;        -- ������ �������� ��������� ������
    SERR                    EXSQUEUE.EXEC_MSG%type;    -- ��������� �� ������ �����������
    NIDENT                  PKG_STD.TREF;              -- ������������� �������� ���������
    PRMS                    PKG_CONTPRMLOC.TCONTAINER; -- ��������� ��� ���������� ��������� ��������� 
  begin
    /* ������� ������ ������� */
    REXSQUEUE := GET_EXSQUEUE_ID(NFLAG_SMART => 0, NRN => NEXSQUEUE);
    /* ������� ������ ������� ��������� */
    REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 0, NRN => REXSQUEUE.EXSSERVICEFN);
    /* ������� ������ ������� ��������� */
    REXSSERVICE := GET_EXSSERVICE_ID(NFLAG_SMART => 0, NRN => REXSSERVICEFN.PRN);
    /* ������� ������ �������� ��������� */
    REXSMSGTYPE := GET_EXSMSGTYPE_ID(NFLAG_SMART => 0, NRN => REXSSERVICEFN.EXSMSGTYPE);
    /* �������� ����������, ���� �� ���� */
    if (REXSMSGTYPE.PRC_RESP is not null) then
      /* ��������� ��������� ����������� */
      UTL_STORED_CHECK(NFLAG_SMART => 0,
                       SPKG        => REXSMSGTYPE.PKG_RESP,
                       SPRC        => REXSMSGTYPE.PRC_RESP,
                       SARGS       => SPRC_RESP_ARGS,
                       NRESULT     => NIDENT);
      /* ��������� ������������� �������� */
      NIDENT := GEN_IDENT();
      /* ��������� �������� ������������� ������� ���������� */
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
      /* ��������� ��������� */
      PKG_SQL_CALL.EXECUTE_STORED(SSTORED_NAME     => UTL_STORED_MAKE_LINK(SPACKAGE   => REXSMSGTYPE.PKG_RESP,
                                                                           SPROCEDURE => REXSMSGTYPE.PRC_RESP),
                                  RPARAM_CONTAINER => PRMS);
      /*
      TODO: owner="mikha" created="15.11.2018"
      text="�������������� ��� ����� ���� ��������� �� ���������� �������� ����� ����������� � ������ - ��� ��� �������� ��������, ����� ��������, ��� �� ����������� ��������"
      */
      /* �������� �������� � �������� ����������� */
      SERR := PRC_RESP_ARG_STR_GET(NIDENT => NIDENT, SARG => SCONT_FLD_SERR);
      /* ���� ���� ������ - ������ �� ���� */
      if (SERR is not null) then
        P_EXCEPTION(0, SERR);
      else
        /* ����������� ��������� ��������� (������ ��� �������� � ������ ���� ��� ������ ���������) */
        if (REXSSERVICE.SRV_TYPE = NSRV_TYPE_RECIVE) then
          QUEUE_RESP_SET(NEXSQUEUE => REXSQUEUE.RN,
                         BRESP     => PRC_RESP_ARG_BLOB_GET(NIDENT => NIDENT, SARG => SCONT_FLD_BRESP),
                         RCQUEUE   => RCQUEUE);
        end if;
      end if;
      /* ������� ��������� ���������� */
      PKG_CONTPRMLOC.PURGE(RCONTAINER => PRMS);
    end if;
    /* ���������� ������������ ������� ������� */
    QUEUE_GET(NFLAG_SMART => 0, NEXSQUEUE => REXSQUEUE.RN, RCQUEUE => RCQUEUE);
  end QUEUE_PRC;
  
end;
/
