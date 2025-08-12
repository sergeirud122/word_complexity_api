# Используем официальный Ruby образ
FROM ruby:3.2.1-alpine

# Устанавливаем системные зависимости
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    curl \
    bash \
    tzdata

# Создаем директорию приложения
WORKDIR /app

# Копируем Gemfile и Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Устанавливаем зависимости
RUN bundle config --global frozen 1 && \
    bundle install --jobs 4 --retry 3

# Копируем код приложения
COPY . .

# Создаем пользователя для безопасности
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# Устанавливаем права доступа
RUN chown -R appuser:appgroup /app

# Переключаемся на обычного пользователя
USER appuser

# Открываем порт
EXPOSE 3000

# Команда по умолчанию
CMD ["rails", "server", "-b", "0.0.0.0"]