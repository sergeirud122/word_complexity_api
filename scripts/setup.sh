#!/bin/bash

# Автоматическая настройка Word Complexity API
# Этот скрипт подготавливает проект к работе

set -e  # Выход при любой ошибке

echo "🚀 Настройка Word Complexity API"
echo "================================="

# Проверка зависимостей
echo "📋 Проверка зависимостей..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker не установлен. Установите Docker: https://docs.docker.com/get-docker/"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose не установлен"; exit 1; }

echo "✅ Docker и Docker Compose найдены"

# Выбор режима хранения
echo ""
echo "🎛 Выберите режим хранения:"
echo "1) Hybrid (PostgreSQL + Redis кэш) - рекомендуется"
echo "2) Redis-Only (только Redis) - быстрее, но менее надежно"
read -p "Введите номер (1 или 2) [1]: " choice
choice=${choice:-1}

if [ "$choice" = "2" ]; then
    echo "📦 Настройка Redis-Only режима..."
    cp .env.redis-only .env
    export REDIS_ONLY_STORAGE=true
else
    echo "🔄 Настройка Hybrid режима..."
    cp .env.hybrid .env
    export REDIS_ONLY_STORAGE=false
fi

echo "✅ Режим настроен"

# Создание папки для логов
mkdir -p logs

# Запуск инфраструктуры
echo ""
echo "🐳 Запуск Docker контейнеров..."
docker-compose down -v || true  # Очистка предыдущих данных
docker-compose up -d

# Ожидание готовности сервисов
echo ""
echo "⏳ Ожидание готовности сервисов..."
echo "Это может занять до 30 секунд..."

# Ждем Redis
for i in {1..30}; do
    if redis-cli -p 6380 ping >/dev/null 2>&1; then
        echo "✅ Redis готов"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Redis не запустился"
        exit 1
    fi
    sleep 1
done

# Ждем PostgreSQL
for i in {1..30}; do
    if docker-compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
        echo "✅ PostgreSQL готов"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ PostgreSQL не запустился"
        exit 1
    fi
    sleep 1
done

# Ждем веб-сервер
echo "⏳ Ожидание готовности веб-сервера..."
sleep 10

# Настройка базы данных
echo ""
echo "🗄 Настройка базы данных..."
docker-compose exec -T web rails db:create db:migrate

echo "✅ База данных настроена"

# Проверка системы
echo ""
echo "🔍 Проверка системы..."

# Проверка контейнеров
echo "📊 Статус контейнеров:"
docker-compose ps

# Проверка режима хранения
echo ""
echo "🎛 Текущий режим хранения:"
make status || echo "Не удалось определить режим"

# Тест API
echo ""
echo "🧪 Тестирование API..."
RESPONSE=$(curl -s -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '["hello", "world"]' || echo "FAILED")

if [[ $RESPONSE == *"job_id"* ]]; then
    JOB_ID=$(echo $RESPONSE | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
    echo "✅ API работает! Job ID: $JOB_ID"
    
    echo "⏳ Ожидание обработки задачи..."
    sleep 5
    
    RESULT=$(curl -s -X GET "http://localhost:3000/complexity-score/$JOB_ID" || echo "FAILED")
    if [[ $RESULT == *"status"* ]]; then
        echo "✅ Задача обработана успешно"
    else
        echo "⚠️ Задача еще обрабатывается или произошла ошибка"
    fi
else
    echo "❌ API не отвечает правильно: $RESPONSE"
fi

# Информация о доступных командах
echo ""
echo "🎉 Настройка завершена!"
echo ""
echo "📋 Доступные команды:"
echo "  make status      - Проверить режим хранения"
echo "  make test-api    - Быстрый тест API"
echo "  make logs        - Просмотр логов"
echo "  make hybrid      - Переключиться на Hybrid режим"
echo "  make redis-only  - Переключиться на Redis-Only режим"
echo "  make cleanup     - Очистить старые задачи"
echo "  make help        - Показать все команды"
echo ""
echo "🌐 API доступен по адресу: http://localhost:3000"
echo "📚 Полная документация: README.md"
echo "🚀 Быстрый старт: QUICKSTART.md"
echo ""
echo "Для полного тестирования запустите: ./scripts/test-full.sh" 