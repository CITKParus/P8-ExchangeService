create or replace view v_exsservice
(nrn, ncrn, scode, sname, nsrv_type, ssrv_root, ssrv_user, ssrv_pass, nunavlbl_ntf_sign, nunavlbl_ntf_time, sunavlbl_ntf_mail, nis_auth, ncnt_login)
as
select
  T.RN,                                 -- NRN
  T.CRN,                                -- NCRN
  T.CODE,                               -- SCODE
  T.NAME,                               -- SNAME
  T.SRV_TYPE,                           -- NSRV_TYPE
  T.SRV_ROOT,                           -- SSRV_ROOT
  T.SRV_USER,                           -- SSRV_USER
  T.SRV_PASS,                           -- SSRV_PASS
  T.UNAVLBL_NTF_SIGN,                   -- NUNAVLBL_NTF_SIGN
  T.UNAVLBL_NTF_TIME,                   -- NUNAVLBL_NTF_TIME
  T.UNAVLBL_NTF_MAIL,                   -- SUNAVLBL_NTF_MAIL
  T.IS_AUTH,                            -- NIS_AUTH
  (select count(F.RN)
     from EXSSERVICEFN F
    where F.PRN = T.RN
      and F.FN_TYPE = 1)                -- NCNT_LOGIN
from
  EXSSERVICE T
where exists (select null from V_USERPRIV UP where UP.CATALOG = T.CRN);
