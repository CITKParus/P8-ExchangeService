/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: тестовый модуль для ПМИ - получение сведений о контрагентах на тестовом стенде
*/

//------------
// Тело модуля
//------------

//Формирование запроса к тестовому стенду на получение сведений о контрагенте
const buildAgentQuery = async prms => {
    console.log(`Начал обработку ДО - ${prms.queue.nId}`);
    console.log(`Закончил обработку ДО - ${prms.queue.nId}`);
};

//Обработка ответа тестового стенда на запрос сведений о контрагенте
const parseAgentInfo = async prms => {
    console.log(`Начал обработку ПОСЛЕ - ${prms.queue.nId}`);
    console.log(`Закончил обработку ПОСЛЕ - ${prms.queue.nId}`);
};

//-----------------
// Интерфейс модуля
//-----------------

exports.buildAgentQuery = buildAgentQuery;
exports.parseAgentInfo = parseAgentInfo;
