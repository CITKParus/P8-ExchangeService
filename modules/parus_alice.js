/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Взаимодействие с Яндекс-Диалогами (голосовым помошником "Алиса")
*/

//------------
// Тело модуля
//------------

//ДО функции "Алиса/Поиск контрагента"
const beforeFindAgent = async prms => {};

//ПОСЛЕ функции "Алиса/Поиск контрагента"
const afterFindAgent = async prms => {};

//ДО функции "Алиса/Поиск договора"
const beforeFindContract = async prms => {};

//ПОСЛЕ функции "Алиса/Поиск договора"
const afterFindContract = async prms => {};

//ДО функции "Алиса/Поиск заказа потребителя"
const beforeFindConsumerOrd = async prms => {};

//ПОСЛЕ функции "Алиса/Поиск заказа потребителя"
const afterFindConsumerOrd = async prms => {};

//ДО функции "Алиса/Поиск контактной информации"
const beforeFindContact = async prms => {};

//ПОСЛЕ функции "Алиса/Поиск контактной информации"
const afterFindContact = async prms => {};

//-----------------
// Интерфейс модуля
//-----------------

exports.beforeFindAgent = beforeFindAgent;
exports.afterFindAgent = afterFindAgent;
exports.beforeFindContract = beforeFindContract;
exports.afterFindContract = afterFindContract;
exports.beforeFindConsumerOrd = beforeFindConsumerOrd;
exports.afterFindConsumerOrd = afterFindConsumerOrd;
exports.beforeFindContact = beforeFindContact;
exports.afterFindContact = afterFindContact;
