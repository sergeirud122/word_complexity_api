# Word Complexity API

🎯 REST API для асинхронного анализа сложности слов с использованием внешнего словарного API.

## 🚀 Быстрый старт

```bash
# 1. Клонирование и запуск
git clone <repository_url>
cd word_complexity_api
make up

# 2. Тестирование API
curl -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["hello", "world"]'

# 3. Получение результата (замените YOUR_JOB_ID)
curl http://localhost:3000/complexity-score/YOUR_JOB_ID
```

## 📚 API

### POST /complexity-score
Создаёт задачу для анализа сложности слов.

**Запрос:**
```json
["beautiful", "complex", "simple"]
```

**Ответ:**
```json
{"job_id": "df454e685b57f34b"}
```

### GET /complexity-score/:id
Получает результат анализа.

**Ответ:**
```json
{
  "status": "completed",
  "result": {
    "beautiful": 40.5,
    "complex": 4.8,
    "simple": 8.33
  }
}
```

**Статусы:** `pending` | `completed` | `failed`

## 🛠 Команды

```bash
# Основные
make up          # Запуск сервисов
make down        # Остановка
make logs        # Просмотр логов
make shell       # Вход в контейнер

# Тестирование  
make test        # Запуск тестов
make lint        # Проверка кода
make demo        # Демо API

# Отладка
make status      # Статус сервисов
make health      # Проверка здоровья
```

## ⚡ Особенности

- 🚀 **Асинхронная обработка** - Sidekiq
- ⚡ **Кэширование** - Redis
- 🛡️ **Валидация** - строгая проверка данных
- 🧪 **Тестирование** - 116 тестов, 0 ошибок
- 🐳 **Docker** - контейнеризация
- 📝 **Логирование** - детальные логи с stack traces

## 🏗 Архитектура

- **Backend**: Rails 8.0.2 (API-only)
- **Jobs**: ActiveJob + Sidekiq
- **Storage**: Redis
- **Testing**: RSpec
- **Deployment**: Docker Compose

## 🔧 Конфигурация

**Порты:**
- Rails API: http://localhost:3000
- Redis: localhost:6379

**Переменные окружения в `docker-compose.yml`**

## 📊 Производительность

- **Время обработки**: ~60-650ms на слово
- **Кэширование**: 6 часов для результатов, 1 день для слов
- **Retry**: до 3 попыток при ошибках
- **Конкурентность**: параллельная обработка через Sidekiq

---

Полная документация: [docs/](docs/) | Примеры: [EXAMPLES.md](EXAMPLES.md)