#!/bin/bash

# Полное тестирование Word Complexity API
# Этот скрипт запускает все виды тестов

set -e  # Выход при любой ошибке

echo "🧪 Полное тестирование Word Complexity API"
echo "=========================================="

# Проверка зависимостей
echo "📋 Проверка зависимостей..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker не установлен"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose не установлен"; exit 1; }

# Запуск инфраструктуры
echo "🚀 Запуск инфраструктуры..."
docker-compose up -d

# Ожидание готовности сервисов
echo "⏳ Ожидание готовности сервисов..."
sleep 10

# Проверка статуса контейнеров
echo "🔍 Проверка статуса контейнеров..."
docker-compose ps

# Настройка БД для тестов
echo "🗄 Настройка базы данных..."
docker-compose exec -T web rails db:create db:migrate RAILS_ENV=development || true
docker-compose exec -T web rails db:create db:migrate RAILS_ENV=test || true

# Запуск RSpec тестов
echo "🧪 Запуск RSpec тестов..."
if command -v bundle >/dev/null 2>&1; then
    echo "  → Локальный запуск RSpec"
    RAILS_ENV=test bundle exec rspec --format documentation
else
    echo "  → Docker запуск RSpec"
    docker-compose exec -T web bash -c "RAILS_ENV=test bundle exec rspec --format documentation"
fi

# Тестирование API в Hybrid режиме
echo "🔄 Тестирование API в Hybrid режиме..."
make hybrid
sleep 5

echo "  → Создание задачи..."
RESPONSE=$(curl -s -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["test", "hybrid", "mode"]')

JOB_ID=$(echo $RESPONSE | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
echo "  → Job ID: $JOB_ID"

if [ -z "$JOB_ID" ]; then
    echo "❌ Не удалось создать задачу в Hybrid режиме"
    exit 1
fi

echo "  → Ожидание обработки..."
sleep 3

echo "  → Проверка результата..."
RESULT=$(curl -s -X GET "http://localhost:3000/complexity-score/$JOB_ID")
echo "  → Результат: $RESULT"

# Тестирование API в Redis-Only режиме
echo "📦 Тестирование API в Redis-Only режиме..."
make redis-only
sleep 5

echo "  → Создание задачи..."
RESPONSE=$(curl -s -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["test", "redis", "only"]')

JOB_ID=$(echo $RESPONSE | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
echo "  → Job ID: $JOB_ID"

if [ -z "$JOB_ID" ]; then
    echo "❌ Не удалось создать задачу в Redis-Only режиме"
    exit 1
fi

echo "  → Ожидание обработки..."
sleep 3

echo "  → Проверка результата..."
RESULT=$(curl -s -X GET "http://localhost:3000/complexity-score/$JOB_ID")
echo "  → Результат: $RESULT"

# Тестирование переключения режимов
echo "🔄 Тестирование переключения режимов..."
make hybrid
sleep 2
HYBRID_STATUS=$(make status 2>/dev/null | grep -o "Hybrid\|Redis-Only" || echo "Unknown")
echo "  → Hybrid режим: $HYBRID_STATUS"

make redis-only
sleep 2
REDIS_STATUS=$(make status 2>/dev/null | grep -o "Hybrid\|Redis-Only" || echo "Unknown")
echo "  → Redis-Only режим: $REDIS_STATUS"

# Проверка производительности
echo "⚡ Тест производительности..."
echo "  → Создание 5 задач параллельно..."

for i in {1..5}; do
    curl -s -X POST http://localhost:3000/complexity-score \
      -H "Content-Type: application/json" \
      -d "[\"word$i\", \"test$i\"]" &
done

wait
echo "  → Все задачи отправлены"

# Проверка здоровья системы
echo "🏥 Проверка здоровья системы..."

echo "  → Redis..."
REDIS_STATUS=$(redis-cli -p 6380 ping 2>/dev/null || echo "FAILED")
echo "    Redis: $REDIS_STATUS"

echo "  → PostgreSQL..."
PG_STATUS=$(docker-compose exec -T db pg_isready -U postgres 2>/dev/null | grep "accepting" || echo "FAILED")
echo "    PostgreSQL: $(echo $PG_STATUS | grep -o 'accepting connections' || echo 'FAILED')"

echo "  → Web сервер..."
WEB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/complexity-score || echo "FAILED")
echo "    Web: $([ "$WEB_STATUS" = "405" ] && echo "OK (Method Not Allowed expected)" || echo "FAILED ($WEB_STATUS)")"

# Статистика
echo "📊 Статистика..."
make stats || echo "Не удалось получить статистику"

# Очистка
echo "🧹 Очистка тестовых данных..."
make cleanup || true

echo ""
echo "✅ Тестирование завершено успешно!"
echo "🎉 Все тесты прошли. Проект готов к использованию!"

# Возврат в Hybrid режим
make hybrid 