require 'redis'

begin
  # Простая конфигурация Redis - используем переменную из docker-compose.yml
  redis_url = ENV.fetch("REDIS_URL")

  # Создаем простое соединение Redis
  $redis = Redis.new(url: redis_url)
  
  # Проверяем соединение
  $redis.ping
  Rails.logger.info "Redis connected successfully"

  # Используем тот же Redis без namespace для простоты
  $cache_redis = $redis
rescue => e
  Rails.logger.error "Redis connection failed: #{e.message}"
  Rails.logger.error "Fallback to in-memory cache"
  
  # Заглушка для Redis если не удается подключиться
  $redis = nil
  $cache_redis = nil
end 