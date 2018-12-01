create global temporary table EXSRNLIST
(
  RN                        number(17),
  IDENT                     number(17) not null,
  DOCUMENT                  number(17) not null,
  constraint C_EXSRNLIST_PK primary key(RN),
  constraint C_EXSRNLIST_UK unique(IDENT, DOCUMENT)
)
on commit preserve rows;
