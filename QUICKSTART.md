# 🚀 Быстрый старт

## За 2 минуты

```bash
# 1. Запуск
docker-compose up -d

# 2. Тест API
curl -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["hello", "world"]'

# 3. Результат (замените JOB_ID)
curl http://localhost:3000/complexity-score/YOUR_JOB_ID
```

## Команды

```bash
make up          # Запуск
make test        # Тесты  
make demo        # Демо
make logs        # Логи
make down        # Остановка
```

## Troubleshooting

```bash
make status      # Проверить статус
make health      # Проверить здоровье
make restart     # Перезапуск
```

Подробнее: [README.md](README.md)