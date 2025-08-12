# 📋 Примеры использования API

## Базовые запросы

### Создание задачи
```bash
curl -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["hello", "world", "complexity"]'
```

**Ответ:**
```json
{"job_id": "6406828ec2827a07"}
```

### Получение результата
```bash
curl -X GET http://localhost:3000/complexity-score/6406828ec2827a07
```

**Ответ (в процессе):**
```json
{"status": "pending"}
```

**Ответ (завершено):**
```json
{
  "status": "completed",
  "result": {
    "hello": 1.2,
    "world": 1.5,
    "complexity": 3.8
  }
}
```

## Примеры запросов

### Простые слова
```bash
curl -X POST http://localhost:3000/complexity-score \
  -d '["cat", "dog", "run", "walk", "eat"]'
```

### Сложные слова
```bash
curl -X POST http://localhost:3000/complexity-score \
  -d '["metamorphosis", "consciousness", "epistemology"]'
```

### Технические термины
```bash
curl -X POST http://localhost:3000/complexity-score \
  -d '["algorithm", "database", "authentication", "optimization"]'
```

## Обработка ошибок

### Неверный формат данных
```bash
curl -X POST http://localhost:3000/complexity-score \
  -d '{"invalid": "format"}'

# Ответ:
{
  "error": "Validation failed",
  "errors": ["Request must be a JSON array of words"]
}
```

### Превышение лимитов
```bash
curl -X POST http://localhost:3000/complexity-score \
  -d '[Array with 101 words...]'

# Ответ:
{
  "error": "Validation failed", 
  "errors": ["Words Too many words. Maximum 100 allowed"]
}
```

### Неверный Job ID
```bash
curl -X GET http://localhost:3000/complexity-score/invalid-id

# Ответ:
{
  "error": "Invalid job ID format",
  "job_id": "invalid-id"
}
```

## Bash скрипт для тестирования

```bash
#!/bin/bash

# Функция создания и проверки задачи
test_api() {
    local words="$1"
    echo "Testing: $words"
    
    # Создание задачи
    response=$(curl -s -X POST http://localhost:3000/complexity-score \
      -H "Content-Type: application/json" \
      -d "$words")
    
    job_id=$(echo $response | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
    echo "Job ID: $job_id"
    
    # Ожидание результата
    sleep 3
    
    # Получение результата
    result=$(curl -s -X GET "http://localhost:3000/complexity-score/$job_id")
    echo "Result: $result"
    echo ""
}

# Тестирование
test_api '["test", "example"]'
test_api '["complex", "sophisticated"]'
```

## Мониторинг

```bash
# Проверка статуса API
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/up

# Проверка логов
make logs

# Статус сервисов  
make status
```