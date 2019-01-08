create or replace view v_exsqueue
(nrn, din_date, sin_authid, nexsservicefn, sexsservicefn_code, dexec_date, nexec_cnt, nexec_state, sexec_msg, bmsg, bresp, nexsqueue, nexsservice, sexsservice_code, nexsservice_srv_type, nexsmsgtype, nretry_schedule, nretry_step, nretry_attempts, sexsmsgtype_code, nlnk_company, slnk_company, nlnk_document, slnk_unitcode, slnk_unitname, bmsg_original, bresp_original, nchild_count, soptions)
as
select
  T.RN,                                 -- NRN
  T.IN_DATE,                            -- DIN_DATE
  T.IN_AUTHID,                          -- SIN_AUTHID
  T.EXSSERVICEFN,                       -- NEXSSERVICEFN
  E.CODE,                               -- SEXSSERVICEFN_CODE
  T.EXEC_DATE,                          -- DEXEC_DATE
  T.EXEC_CNT,                           -- NEXEC_CNT
  T.EXEC_STATE,                         -- NEXEC_STATE
  T.EXEC_MSG,                           -- SEXEC_MSG
  T.MSG,                                -- BMSG
  T.RESP,                               -- BRESP
  T.EXSQUEUE,                           -- NEXSQUEUE
  E.PRN,                                -- NEXSSERVICE
  S.CODE,                               -- SEXSSERVICE_CODE
  S.SRV_TYPE,                           -- NEXSSERVICE_SRV_TYPE
  E.EXSMSGTYPE,                         -- NEXSMSGTYPE
  E.RETRY_SCHEDULE,                     -- NRETRY_SCHEDULE
  E.RETRY_STEP,                         -- NRETRY_STEP
  E.RETRY_ATTEMPTS,                     -- NRETRY_ATTEMPTS
  M.CODE,                               -- SEXSMSGTYPE_CODE
  T.LNK_COMPANY,                        -- NLNK_COMPANY
  C.NAME,                               -- SLNK_COMPANY
  T.LNK_DOCUMENT,                       -- NLNK_DOCUMENT
  T.LNK_UNITCODE,                       -- SLNK_UNITCODE
  U.UNITNAME,                           -- SLNK_UNITNAME
  T.MSG_ORIGINAL,                       -- BMSG_ORIGINAL
  T.RESP_ORIGINAL,                      -- BRESP_ORIGINAL
  F_EXSQUEUE_GET_CHILD_COUNT(T.RN),     -- NCHILD_COUNT
  T.OPTIONS                             -- SOPTIONS
from
  EXSQUEUE T,
  EXSSERVICE S,
  EXSSERVICEFN E,
  EXSMSGTYPE M,
  COMPANIES C,
  UNITLIST U
where T.EXSSERVICEFN = E.RN
  and E.EXSMSGTYPE = M.RN
  and E.PRN = S.RN
  and T.LNK_COMPANY = C.RN (+)
  and T.LNK_UNITCODE = U.UNITCODE (+)
  and exists (select null from V_USERPRIV UP where UP.UNITCODE = 'EXSQueue')
;
