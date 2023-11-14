/*
  Сервис интеграции ПП Парус 8 с WEB API
  Дополнительный модуль: Интеграция с ГАР (GAR) - пул обработчиков
*/

//------------------------------
// Подключаем внешние библиотеки
//------------------------------

const { Worker } = require("worker_threads"); //Параллельные обработчики
const { WRK_MSG_TYPE, logInf, logWrn, makeStopMessage } = require("./utils"); //Вспомогательные функции

//--------------------------
// Глобальные идентификаторы
//--------------------------

//Название модудля для протокола
const MODULE = "GAR_WORKERS_POOL";

//Размер пула по умолчанию
const DEFAULT_POOL_SIZE = 10;

//Таймаут ожидания останова воркеров
const WRK_TERMINATE_TIMEOUT = 1000;

//------------
// Тело модуля
//------------

//Пул обработчиков
class WorkersPool {
    //Конструктор класса
    constructor({ workerPath, timeout, limit, drainTimeout } = {}) {
        //Воркеры
        this.items = [];
        //Колбэки воркеров
        this.cb = [];
        //Флаги доступности воркеров
        this.free = [];
        //Флаги терминированности воркеров
        this.terminated = [];
        //Очередь ожидания освободившихся воркеров
        this.queue = [];
        //Таймаут ожидания освобождения воркера
        this.timeout = timeout || 0;
        //Текущий воркер
        this.current = 0;
        //Текущий размер пула
        this.size = 0;
        //Количество свободных воркеров в пуле
        this.available = 0;
        //Предельный размер пула
        this.limit = limit || DEFAULT_POOL_SIZE;
        //Количество запущенных и работающих обработчиков
        this.online = 0;
        //Путь к алгоритму воркера пула
        if (!workerPath) throw new Error("Не указан путь к файлу обработчика.");
        this.workerPath = workerPath;
        //Флаг запущенности пула
        this.started = false;
        //Флаг выполнения останова пула
        this.draining = false;
        //Таймаут останова пула
        if (drainTimeout !== undefined && drainTimeout < WRK_TERMINATE_TIMEOUT)
            throw new Error(`Таймаут ожидания останова пула не может быть меньше чем ${WRK_TERMINATE_TIMEOUT} мс.`);
        this.drainTimeout = drainTimeout || WRK_TERMINATE_TIMEOUT;
    }

    //Запуск пула
    start({ dbBuferSize, fileChunkSize, loadLog, dbConn }) {
        //Проверим возможность запуска
        if (this.started) throw new Error("Пул уже запущен");
        if (!this.workerPath) throw new Error("Не указан путь к файлу обработчика.");
        //Формируем пул заданного размера
        for (let i = 0; i < this.limit; i++) {
            //Создаём воркер
            let wrk = new Worker(this.workerPath, {
                workerData: {
                    number: i,
                    dbBuferSize,
                    fileChunkSize,
                    loadLog: JSON.stringify(loadLog),
                    dbConn
                }
            });
            //Подписываемся на запуск обработчика
            wrk.on("online", () => {
                logInf(`Обработчик #${i} запущен.`, MODULE, loadLog);
                this.online++;
                logInf(`Всего запущено: ${this.online}`, MODULE, loadLog);
            });
            //Подписываемся на останов обработчика
            wrk.on("exit", exitCode => {
                logInf(`Обработчик #${i} остановлен. Код выхода - ${exitCode}`, MODULE, loadLog);
                this.online--;
                logInf(`Всего запущено: ${this.online}`, MODULE, loadLog);
            });
            //Подписываемся на сообщения от обработчика
            wrk.on("message", data => {
                //Если пришел результат работы
                if (data?.type === WRK_MSG_TYPE.RESULT) {
                    //И есть колбэк его ожидающий
                    if (this.cb[i]) {
                        //Вызываем колбэк
                        this.cb[i](data.err, data.payload);
                        //Забываем колбэк
                        this.cb[i] = null;
                    }
                    this.release(wrk);
                }
                if (data?.type == WRK_MSG_TYPE.STOP) {
                    this.items[i].terminate();
                }
            });
            //Добавляем воркер в пул
            this.add(wrk);
        }
        //Говорим, что запустились
        return new Promise(async resolve => {
            while (this.online < this.limit) {
                await new Promise(resolve => setTimeout(resolve, 0));
            }
            this.started = true;
            resolve();
        });
    }

    //Останов пула
    async stop(loadLog) {
        //Устанавливаем флаг останова - чтобы не принимать новые задачи в пул
        this.draining = true;
        //Всех кто ждет освобождения обработчиков = сбрасываем с ошибкой
        while (this.queue.length > 0) {
            const { reject, timer } = this.queue.shift();
            if (timer) clearTimeout(timer);
            if (reject) setTimeout(reject, 0, new Error("Пул закрывается - размещение задач недопустимо."));
        }
        //Инициализируем количество неостановленных обработчиков и количество попыток останова
        let more = 0;
        let cntTry = 0;
        //Пока есть кого останавливать
        do {
            //Сброс счётчика неостановленных с предыдущей итерации останова
            more = 0;
            //Проверим, что ещё не нарушен таймаут останова пула
            if (cntTry * WRK_TERMINATE_TIMEOUT > this.drainTimeout) {
                logWrn("Истёк таймаут ожидания останова пула - занятые обработчики будут остановлены принудительно.", MODULE, loadLog);
            }
            //Останавливаем всех свободных обработчиков (или всех подряд если уже нарушен таймаут останова пула)
            for (let i = 0; i < this.items.length; i++) {
                if (this.free[i] || (!this.free[i] && !this.terminated[i] && cntTry * WRK_TERMINATE_TIMEOUT > this.drainTimeout)) {
                    this.terminated[i] = true;
                    this.items[i].postMessage(makeStopMessage());
                } else more++;
            }
            //Если ещё осталось кого останавливать - ждем и пробуем снова
            if (more > 0) {
                await new Promise(resolve => setTimeout(resolve, WRK_TERMINATE_TIMEOUT));
                logInf(`Ожидаю освобождение обработчиков...(ещё занято ${more})`, MODULE, loadLog);
            }
            cntTry++;
        } while (more != 0);
        do {
            await new Promise(resolve => setTimeout(resolve, 0));
        } while (this.online > 0);
        this.started = false;
    }

    //Извлечение ближайшего свободного обработчика из пула
    async next() {
        //Проверим возможность извлечения обработчика
        if (this.draining) return null;
        if (this.size === 0) return null;
        //Если доступных нет - ставим запрос на ожидание в очередь
        if (this.available === 0) {
            return new Promise((resolve, reject) => {
                const waiting = { resolve, reject, timer: null };
                if (this.timeout > 0) {
                    waiting.timer = setTimeout(() => {
                        waiting.resolve = null;
                        this.queue.shift();
                        reject(new Error("Истёк таймаут ожидания освобождения обработчика."));
                    }, this.timeout);
                }
                this.queue.push(waiting);
            });
        }
        //Ищем первый свободный обработчик
        let item = null;
        let free = false;
        do {
            item = this.items[this.current];
            free = this.free[this.current];
            this.current++;
            if (this.current === this.size) this.current = 0;
        } while (!item || !free);
        //Возвращаем его
        return item;
    }

    //Добавление обработчика
    add(item) {
        //Проверим возможность добавления
        if (this.items.includes(item)) throw new Error("Обработчик уже существет в пуле.");
        //Увеличиваем фактический размер пула и количество доступных обработчиков
        this.size++;
        this.available++;
        //Добавляем обработчик, флаг его доступности/терминированности и слот для его колбэков
        this.items.push(item);
        this.free.push(true);
        this.terminated.push(false);
        this.cb.push(null);
    }

    //Захват обработчика
    async capture() {
        //Ожидаем ближайший свободный
        const item = await this.next();
        if (!item) return null;
        //Если дождались его - выставляем флаг недоступности и уменьшаем количество доступных
        const index = this.items.indexOf(item);
        this.free[index] = false;
        this.available--;
        //Возвращаем полученный свободный обработчик
        return item;
    }

    //Высвобождение обработчика
    release(item) {
        //Найдем высвобождаемый обработчик
        const index = this.items.indexOf(item);
        //Проверим, что его можно освободить
        if (index < 0) throw new Error("Попытка освободить несуществующий обработчик.");
        if (this.free[index]) throw new Error("Попытка осободить незанятый обработчик.");
        //Выставляем флаг - обработчик доступен и увеличиваем количество доступных
        this.free[index] = true;
        this.available++;
        //Если кто-то есть в очереди ожидания доступных обработчиков (и мы не останавливаем пул сейчас)
        if (this.queue.length > 0 && !this.draining) {
            //Отдаём ему высвободившийся обработчик
            const { resolve, timer } = this.queue.shift();
            if (timer) clearTimeout(timer);
            if (resolve) setTimeout(resolve, 0, item);
        }
    }

    //Добавление задачи пулу
    async sendTask(task, cb) {
        //Проверим, что можно добавить новую задачу
        if (this.draining) throw new Error("Пул закрывается - размещение задач недопустимо.");
        if (!this.started) throw new Error("Пул не запущен - размещение задач недопустимо.");
        //Захватим обработчик
        let item = await this.capture();
        //Если удалось
        if (item) {
            //Найдем его в пуле
            const index = this.items.indexOf(item);
            if (index < 0) throw new Error("Выбран обработчик, отсуствующий в пуле.");
            //Запомним колбэк для его результата
            this.cb[index] = cb;
            //Отправим ему задачу
            item.postMessage(task);
        } else {
            //Не смогли захватить обработчик
            throw new Error("Не удалось выбрать обработчик из пула.");
        }
    }
}

//-----------------
// Интерфейс модуля
//-----------------

exports.WorkersPool = WorkersPool;
