create or replace procedure UDO_P_FISCDOCS_MAKE_MSG_ATOL
(
  NCOMPANY                  in number,            -- Организация
  NFISCDOC                  in number,            -- Регистрационный номер фискального документа
  NEXSQUEUE                 out number            -- Регистрационный номер добавленной позиции очереди обмена
)
as
  /* Локальные переменные */
  CDATA                     clob;                 -- Буфер для XML-посылки
  NTMP_RN                   PKG_STD.TREF;         -- Буфер для вычислений  
  REXSSERVICEFN             EXSSERVICEFN%rowtype; -- Запись функции сервиса интеграции
  BTEST_SRV                 boolean := false;     -- Признак тестового сервиса

  /* Добавление пустой открытой ветки */
  procedure NODE
  (
    SNAME                   varchar2              -- Имя ветки
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
    SNAME                   varchar2,             -- Имя ветки
    SVALUE                  varchar2              -- Значение ветки (строка)
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
    SNAME                   varchar2,             -- Имя ветки
    NVALUE                  number                -- Значение ветки (число)
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
    SNAME                   varchar2,             -- Имя ветки
    DVALUE                  date                  -- Значение ветки (дата)
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
  /* Определим сервис интеграции и его функцию, через которые будем отправлять сообщение */
  REXSSERVICEFN := GET_EXSSERVICEFN_ID(NFLAG_SMART => 0,
                                       NRN         => UDO_PKG_EXS_ATOL.UTL_FISCDOC_GET_EXSFN_REG(NFISCDOC => NFISCDOC));
  /* Выставим флаг тестового сервиса */
  BTEST_SRV := UDO_PKG_EXS_ATOL.UTL_EXSSERVICE_IS_TEST(NEXSSERVICE => REXSSERVICEFN.PRN);
  /* Инициализируем сборку документа для отправки */
  PKG_XMLFAST.PROLOGUE(NENCODING   => PKG_XMLFAST.ENCODING_UTF8_,
                       NSTANDALONE => PKG_XMLFAST.STANDALONE_YES_,
                       BALINE      => true);
  /* Открываем корень XML документа */
  NODE(SNAME => 'FISCDOC');
  /* Курсорный цикл для доступа к данным фискального документа */
  for D in (select T.*
              from UDO_FISCDOCS T
             where T.RN = NFISCDOC
               and T.COMPANY = NCOMPANY)
  loop
    /* Данные заголовка фискального документа */
    NODE(SNAME => 'NRN', NVALUE => D.RN);
    NODE(SNAME => 'DDOC_DATE', DVALUE => D.DOC_DATE);
    NODE(SNAME => 'SDDOC_DATE', SVALUE => TO_CHAR(D.DOC_DATE, 'dd.mm.yyyy hh24:mi:ss'));
    /* Список свойств фискального документа */
    NODE('FISCDOC_PROPS');
    for SP in (select A.CODE SCODE,
                      A.NAME SNAME,
                      UDO_GET_FISCDOCSPROP_VALUE(T.RN) SVALUE,
                      T.VAL_STR SVAL_STR,
                      T.VAL_NUMB NVAL_NUMB,
                      T.VAL_DATE DVAL_DATE,
                      T.VAL_DATETIME DVAL_DATETIME
                 from UDO_FISCDOCSPROP T,
                      UDO_FDKNDATT     P,
                      UDO_FISCDOCATT   A
                where T.PRN = D.RN
                  and T.PROP = P.RN
                  and P.ATTRIBUTE = A.RN)
    loop
      /* Свойство фискального документа */
      NODE(SNAME => 'FISCDOC_PROP');
      /* Для некоторых тэгов необходим тестовый набор данных, если это тестовый сервис */
      if (BTEST_SRV) then
        /* Подставим тестовый ИНН */
        if (SP.SCODE = '1018') then
          SP.SVALUE   := UDO_PKG_EXS_ATOL.STEST_INN;
          SP.SVAL_STR := UDO_PKG_EXS_ATOL.STEST_INN;
        end if;
        /* Подставим тестовый адрес расчётов */
        if (SP.SCODE = '1187') then
          SP.SVALUE   := UDO_PKG_EXS_ATOL.STEST_ADDR;
          SP.SVAL_STR := UDO_PKG_EXS_ATOL.STEST_ADDR;
        end if;
      end if;
      /* Данные свойства фискального документа */
      NODE(SNAME => 'SCODE', SVALUE => SP.SCODE);
      NODE(SNAME => 'SNAME', SVALUE => SP.SNAME);
      NODE(SNAME => 'VALUE', SVALUE => SP.SVALUE);
      NODE(SNAME => 'SVALUE', SVALUE => SP.SVAL_STR);
      NODE(SNAME => 'NVALUE', NVALUE => SP.NVAL_NUMB);
      NODE(SNAME => 'DVALUE', DVALUE => SP.DVAL_DATE);
      NODE(SNAME => 'DTVALUE', DVALUE => SP.DVAL_DATETIME);
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
  PKG_EXS.QUEUE_PUT(NEXSSERVICEFN => REXSSERVICEFN.RN,
                    BMSG          => CLOB2BLOB(LCDATA => CDATA, SCHARSET => 'UTF8'),
                    NLNK_COMPANY  => NCOMPANY,
                    NLNK_DOCUMENT => NFISCDOC,
                    SLNK_UNITCODE => 'UDO_FiscalDocuments',
                    NNEW_EXSQUEUE => NEXSQUEUE);
end;
/
