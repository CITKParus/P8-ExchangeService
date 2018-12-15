/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с Яндекс-Диалогами (голосовым помошником "Алиса")
*/

//------------
// Тело модуля
//------------

//ДО функции "Алиса/Начало сеанса"
const beforeLogin = async prms => {};

//ПОСЛЕ функции "Алиса/Начало сеанса"
const afterLogin = async prms => {};

//ДО функции "Алиса/Поиск контрагента"
const beforeFindAgent = async prms => {};

//ПОСЛЕ функции "Алиса/Поиск контрагента"
const afterFindAgent = async prms => {};

//ДО функции "Алиса/Поиск договора"
const beforeFindContract = async prms => {};

//ПОСЛЕ функции "Алиса/Поиск договора"
const afterFindContract = async prms => {};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeLogin = beforeLogin;
exports.afterLogin = afterLogin;
exports.beforeFindAgent = beforeFindAgent;
exports.afterFindAgent = afterFindAgent;
exports.beforeFindContract = beforeFindContract;
exports.afterFindContract = afterFindContract;
