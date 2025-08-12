# API Architecture

## Архитектура

Модульная архитектура на базе Rails Concerns:

### 1. LocaleHelpers
- Интернационализация (EN/RU)
- Автоматическое определение языка из Accept-Language

### 2. SimpleErrorHandling  
- Глобальная обработка ошибок
- Структурированные JSON ответы
- Логирование с stack traces

### 3. ResponseHelpers
- Стандартизированные HTTP ответы
- Унифицированное форматирование

## Форматы ответов

**Успешные ответы:**
```json
{"job_id": "6406828ec2827a07"}
```

**Результаты:**
```json
{
  "status": "completed",
  "result": {
    "angry": 12.0,
    "happy": 17.6,
    "sad": 16.0
  }
}
```

**Ошибки валидации:**
```json
{
  "error": "Validation failed",
  "errors": ["Request must be a JSON array of words"]
}
```

**Системные ошибки:**
```json
{
  "error": "Invalid job ID format",
  "job_id": "invalid-id"
}
```

## Обработка ошибок

### Validation Errors (422)
- Неверный формат массива слов
- Пустой массив  
- Превышен лимит слов (100)
- Неверный формат слова

### Not Found Errors (404)
- Задача не найдена

### Bad Request (400)
- Неверный формат job_id

### Service Errors (503)
- Ошибка Redis
- Сервис недоступен

## Производительность

### Кэширование
- **Redis**: Статусы и результаты задач (6 часов)
- **Rails.cache**: Результаты слов (1 день)

### Асинхронная обработка
- Sidekiq для фоновой обработки
- Retry механизм при ошибках
- Параллельная обработка слов

## Интернационализация

**Поддерживаемые языки:** English (en), Russian (ru)

**Определение языка:** Accept-Language header

**Пример:**
```bash
curl -H "Accept-Language: ru-RU,ru;q=0.9" \
     -X POST /complexity-score \
     -d '["слово"]'
```

## Тестирование

```bash
# Валидация
curl -X POST /complexity-score -d '[]'
# Returns 422

# Неверный ID  
curl /complexity-score/invalid-id
# Returns 400

# Успешный запрос
curl -X POST /complexity-score -d '["test"]'
# Returns 202
```

## Преимущества архитектуры

1. **Модульность** - разделение ответственности через Concerns
2. **Консистентность** - единообразная обработка ошибок  
3. **Производительность** - Redis кэширование и async обработка
4. **Надежность** - retry механизмы и graceful error handling
5. **Поддерживаемость** - чистая структура кода и полные тесты