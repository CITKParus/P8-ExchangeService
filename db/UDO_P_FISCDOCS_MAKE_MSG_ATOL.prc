create or replace procedure UDO_P_FISCDOCS_MAKE_MSG_ATOL
(
  NCOMPANY                  in number,              -- Организация
  NFISCDOC                  in number,              -- Регистрационный номер фискального документа
  NEXSQUEUE                 out number              -- Регистрационный номер добавленной позиции очереди обмена
)
as
  /* Локальные переменные */
  CDATA                     clob;                   -- Буфер для XML-посылки
  SEXSSERVICE               EXSSERVICEFN.CODE%type; -- Код сервиса-обработчика
  SEXSSERVICEFN             EXSSERVICEFN.CODE%type; -- Код функции отправки
  NTMP_RN                   PKG_STD.TREF;           -- Буфер для вычислений

  /* Добавление пустой открытой ветки */
  procedure NODE
  (
    SNAME                   varchar2                -- Имя ветки
  )
  as
  begin
    /* Открываем ветку */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* Добавляем её */
    PKG_XMLFAST.NODE;
  end NODE;
  
  /* Добавление ветки со значением (строка) */
  procedure NODE
  (
    SNAME                   varchar2,               -- Имя ветки
    SVALUE                  varchar2                -- Значение ветки
  )
  as
  begin
    /* Открываем ветку */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* Добавляем её */
    PKG_XMLFAST.NODE;
    /* Выставляем значение */
    PKG_XMLFAST.VALUE(SVALUE => SVALUE);
    /* Закрываем ветку */
    PKG_XMLFAST.UP;
  end NODE;  

  /* Добавление ветки со значением (число) */
  procedure NODE
  (
    SNAME                   varchar2,               -- Имя ветки
    NVALUE                  number                  -- Значение ветки
  )
  as
  begin
    /* Открываем ветку */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* Добавляем её */
    PKG_XMLFAST.NODE;
    /* Выставляем значение */
    PKG_XMLFAST.VALUE(NVALUE => NVALUE);
    /* Закрываем ветку */
    PKG_XMLFAST.UP;
  end NODE;  

  /* Добавление ветки со значением (дата) */
  procedure NODE
  (
    SNAME                   varchar2,               -- Имя ветки
    DVALUE                  date                    -- Значение ветки
  )
  as
  begin
    /* Открываем ветку */
    PKG_XMLFAST.DOWN(SNAME => SNAME);
    /* Добавляем её */
    PKG_XMLFAST.NODE;
    /* Выставляем значение */
    PKG_XMLFAST.VALUE(DVALUE => DVALUE);
    /* Закрываем ветку */
    PKG_XMLFAST.UP;
  end NODE;  

begin
  /* Проверим наличие документа */
  UDO_P_FISCDOCS_EXISTS(NRN => NFISCDOC, NCOMPANY => NCOMPANY, NCRN => NTMP_RN, NJUR_PERS => NTMP_RN);
  /* Инициализируем сборку документа для отправки */
  PKG_XMLFAST.PROLOGUE(NENCODING   => PKG_XMLFAST.ENCODING_UTF8_,
                       NSTANDALONE => PKG_XMLFAST.STANDALONE_YES_,
                       BALINE      => true);
  /* Открываем корень XML документа */
  NODE(SNAME => 'FISCDOC');
  /* Курсорный цикл для доступа к данным фискального документа */
  for D in (select T.*
              from UDO_V_FISCDOCS T
             where T.NRN = UDO_P_FISCDOCS_MAKE_MSG_ATOL.NFISCDOC
               and T.NCOMPANY = UDO_P_FISCDOCS_MAKE_MSG_ATOL.NCOMPANY)
  loop
    /* Выбираем API обмена в зависимости от версии фискального документа */
    case D.STYPE_VERSION
      /* ФФД 1.05 */
      when '1.05' then
        begin
          SEXSSERVICE   := 'АТОЛ_V4_ИСХ';
          SEXSSERVICEFN := 'V4_ФФД1.05_РегистрацияЧекаРПВ';
        end;
      /* Неизвестная версия ФФД */
      else
        begin
          P_EXCEPTION(0,
                      'Версия фискального документа "%s" не поддерживается!',
                      D.STYPE_VERSION);
        end;
    end case;
    /* Данные заголовка фискального документа */
    NODE(SNAME => 'NRN', NVALUE => D.NRN);
    NODE(SNAME => 'NCOMPANY', NVALUE => D.NCOMPANY);
    NODE(SNAME => 'NCRN', NVALUE => D.NCRN);
    NODE(SNAME => 'NJUR_PERS', NVALUE => D.NJUR_PERS);
    NODE(SNAME => 'SJUR_PERS', SVALUE => D.SJUR_PERS);
    NODE(SNAME => 'SDOC_PREF', SVALUE => trim(D.SDOC_PREF));
    NODE(SNAME => 'SDOC_NUMB', SVALUE => trim(D.SDOC_NUMB));
    NODE(SNAME => 'NDOC_TYPE', NVALUE => D.NDOC_TYPE);
    NODE(SNAME => 'NDOC_TYPE_CODE', NVALUE => D.NDOC_TYPE_CODE);
    NODE(SNAME => 'NTYPE_VERSION', NVALUE => D.NTYPE_VERSION);
    NODE(SNAME => 'STYPE_VERSION', SVALUE => D.STYPE_VERSION);
    NODE(SNAME => 'DDOC_DATE', DVALUE => D.DDOC_DATE);
    NODE(SNAME => 'SDDOC_DATE', SVALUE => TO_CHAR(D.DDOC_DATE, 'dd.mm.yyyy hh24:mi:ss'));
    NODE(SNAME => 'NAGENT', NVALUE => D.NAGENT);
    NODE(SNAME => 'SAGENT', SVALUE => D.SAGENT);
    NODE(SNAME => 'NCALC_KIND', NVALUE => D.NCALC_KIND);
    NODE(SNAME => 'NBASE_SUM', NVALUE => D.NBASE_SUM);
    NODE(SNAME => 'SAUTHID', SVALUE => D.SAUTHID);
    NODE(SNAME => 'DEDIT_TIME', DVALUE => D.DEDIT_TIME);
    NODE(SNAME => 'SDEDIT_TIME', SVALUE => TO_CHAR(D.DEDIT_TIME, 'dd.mm.yyyy hh24:mi:ss'));
    NODE(SNAME => 'SNOTE', SVALUE => D.SNOTE);
    NODE(SNAME => 'NSTATUS', NVALUE => D.NSTATUS);
    NODE(SNAME => 'DSEND_TIME', DVALUE => D.DSEND_TIME);
    NODE(SNAME => 'SDSEND_TIME', SVALUE => TO_CHAR(D.DSEND_TIME, 'dd.mm.yyyy hh24:mi:ss'));
    NODE(SNAME => 'DCONFIRM_DATE', DVALUE => D.DCONFIRM_DATE);
    NODE(SNAME => 'SDCONFIRM_DATE', SVALUE => TO_CHAR(D.DCONFIRM_DATE, 'dd.mm.yyyy hh24:mi:ss'));
    NODE(SNAME => 'SNUMB_FD', SVALUE => D.SNUMB_FD);
    NODE(SNAME => 'NFACEACC', NVALUE => D.NFACEACC);
    NODE(SNAME => 'SFACEACC', SVALUE => D.SFACEACC);
    NODE(SNAME => 'SADD_PROP', SVALUE => D.SADD_PROP);
    NODE(SNAME => 'SSRC_UNITCODE', SVALUE => D.SSRC_UNITCODE);
    NODE(SNAME => 'SSRC_UNITNAME', SVALUE => D.SSRC_UNITNAME);
    NODE(SNAME => 'NSRC_TYPE', NVALUE => D.NSRC_TYPE);
    NODE(SNAME => 'SSRC_TYPE', SVALUE => D.SSRC_TYPE);
    NODE(SNAME => 'SSRC_NUMB', SVALUE => D.SSRC_NUMB);
    NODE(SNAME => 'DSRC_DATE', DVALUE => D.DSRC_DATE);
    NODE(SNAME => 'SDSRC_DATE', SVALUE => TO_CHAR(D.DSRC_DATE, 'dd.mm.yyyy hh24:mi:ss'));
    NODE(SNAME => 'NVALID_TYPE', NVALUE => D.NVALID_TYPE);
    NODE(SNAME => 'SVALID_TYPE', SVALUE => D.SVALID_TYPE);
    NODE(SNAME => 'SVALID_NUMB', SVALUE => D.SVALID_NUMB);
    NODE(SNAME => 'DVALID_DATE', DVALUE => D.DVALID_DATE);
    NODE(SNAME => 'SDVALID_DATE', SVALUE => TO_CHAR(D.DVALID_DATE, 'dd.mm.yyyy hh24:mi:ss'));
    NODE(SNAME => 'SDOC_URL', SVALUE => D.SDOC_URL);
    NODE(SNAME => 'NCORRECT_TYPE', NVALUE => D.NCORRECT_TYPE);
    /* Список свойств фискального документа */
    NODE('FISCDOC_PROPS');
    for SP in (select T.*,
                      A.CODE SCODE,
                      A.NAME SNAME
                 from UDO_FISCDOCSPROP T,
                      UDO_FDKNDATT     P,
                      UDO_FISCDOCATT   A
                where T.PRN = D.NRN
                  and T.PROP = P.RN
                  and P.ATTRIBUTE = A.RN)
    loop
      /* Свойство фискального документа */
      NODE(SNAME => 'FISCDOC_PROP');
      /* Данные свойства фискального документа */
      NODE(SNAME => 'SCODE', SVALUE => SP.SCODE);
      NODE(SNAME => 'SNAME', SVALUE => SP.SNAME);
      NODE(SNAME => 'VALUE', SVALUE => UDO_GET_FISCDOCSPROP_VALUE(SP.RN));
      NODE(SNAME => 'SVALUE', SVALUE => SP.VAL_STR);
      NODE(SNAME => 'NVALUE', NVALUE => SP.VAL_NUMB);
      NODE(SNAME => 'DVALUE', DVALUE => SP.VAL_DATE);
      NODE(SNAME => 'DTVALUE', DVALUE => SP.VAL_DATETIME);
      /* Закрываем свойство фискального документа */
      PKG_XMLFAST.UP;
    end loop;
    /* Закрываем список свойств фискального документа */
    PKG_XMLFAST.UP;
  end loop;
  /* Закрываем корневой тэг XML-документа */
  PKG_XMLFAST.UP;
  /* Финализируем сборку XML-документа */
  PKG_XMLFAST.EPILOGUE(LDATA => CDATA);
  /* Отправляем сформированный документ */
  PKG_EXS.QUEUE_PUT(SEXSSERVICE   => SEXSSERVICE,
                    SEXSSERVICEFN => SEXSSERVICEFN,
                    BMSG          => CLOB2BLOB(LCDATA => CDATA, SCHARSET => 'UTF8'),
                    NLNK_COMPANY  => NCOMPANY,
                    NLNK_DOCUMENT => NFISCDOC,
                    SLNK_UNITCODE => 'UDO_FiscalDocuments',                    
                    NNEW_EXSQUEUE => NEXSQUEUE);
end;
/
