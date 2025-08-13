.PHONY: help build up down restart logs shell test lint clean

# Colors for output
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

# Docker Compose настройки
COMPOSE=docker compose
WEB_SERVICE=web
REDIS_SERVICE=redis
SIDEKIQ_SERVICE=sidekiq

# Default target
help: ## Показать справку по командам
	@echo "$(BLUE)🐳 Word Complexity API - Docker Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# ============================================================================
# 🏗 Build & Setup
# ============================================================================

build: ## Собрать Docker образы
	@echo "$(BLUE)Building Docker images...$(NC)"
	$(COMPOSE) build
	@echo "$(GREEN)✅ Build complete$(NC)"

setup: build ## Полная настройка проекта (первый запуск)
	@echo "$(BLUE)Setting up project for first time...$(NC)"
	$(COMPOSE) run --rm $(WEB_SERVICE) bundle install
	@echo "$(GREEN)✅ Setup complete$(NC)"
	@echo "$(YELLOW)💡 Run 'make up' to start all services$(NC)"

# ============================================================================
# 🚀 Running Services
# ============================================================================

up: ## Запустить все сервисы
	@echo "$(BLUE)Starting all services...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✅ Services started$(NC)"
	@make status

up-build: ## Пересобрать и запустить
	@echo "$(BLUE)Building and starting services...$(NC)"
	$(COMPOSE) up -d --build
	@echo "$(GREEN)✅ Services built and started$(NC)"

down: ## Остановить все сервисы
	@echo "$(BLUE)Stopping all services...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✅ Services stopped$(NC)"

restart: down up ## Перезапустить все сервисы

restart-web: ## Перезапустить только web сервис
	@echo "$(BLUE)Restarting web service...$(NC)"
	$(COMPOSE) restart $(WEB_SERVICE)
	@echo "$(GREEN)✅ Web service restarted$(NC)"

# ============================================================================
# 📊 Status & Health
# ============================================================================

status: ## Показать статус сервисов
	@echo "$(BLUE)Service status:$(NC)"
	$(COMPOSE) ps

health: ## Проверить здоровье сервисов
	@echo "$(BLUE)Checking service health...$(NC)"
	@echo "$(YELLOW)Redis:$(NC)"
	@$(COMPOSE) exec $(REDIS_SERVICE) redis-cli ping && echo "$(GREEN)✅ Redis OK$(NC)" || echo "$(RED)❌ Redis FAILED$(NC)"
	@echo "$(YELLOW)Web:$(NC)"
	@curl -s http://localhost:3000/up > /dev/null && echo "$(GREEN)✅ Rails OK$(NC)" || echo "$(RED)❌ Rails FAILED$(NC)"

# ============================================================================
# 🧪 Testing & Development
# ============================================================================

test: ## Запустить тесты
	@echo "$(BLUE)Running tests...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec rspec

test-setup: ## Настроить тестовую среду
	@echo "$(BLUE)Setting up test environment...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle install

test-coverage: ## Тесты с покрытием
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bash -c "COVERAGE=true bundle exec rspec"

lint: ## Проверить код через RuboCop
	@echo "$(BLUE)Running RuboCop...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec rubocop

lint-fix: ## Автоисправление через RuboCop
	@echo "$(BLUE)Auto-fixing with RuboCop...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec rubocop -a

# ============================================================================
# 🔍 Code Analysis & Quality
# ============================================================================

security: ## Проверка безопасности через Brakeman
	@echo "$(BLUE)Running Brakeman security analysis...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec brakeman -A -q

best-practices: ## Проверка лучших практик Rails
	@echo "$(BLUE)Running Rails Best Practices...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec rails_best_practices .

code-smells: ## Поиск проблем кода через Reek
	@echo "$(BLUE)Running Reek code smell detection...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec reek app/ lib/

duplication: ## Поиск дублирования кода через Flay
	@echo "$(BLUE)Running Flay duplication detection...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec flay app/ lib/

complexity: ## Анализ сложности кода через Flog
	@echo "$(BLUE)Running Flog complexity analysis...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec flog app/ lib/

vulnerabilities: ## Проверка уязвимостей в гемах
	@echo "$(BLUE)Running Bundle Audit...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle exec bundle-audit check

quality-all: security best-practices code-smells duplication complexity vulnerabilities ## Запустить все анализаторы качества кода
	@echo "$(GREEN)✅ All code quality checks completed!$(NC)"

quality-summary: ## Краткий отчет по качеству кода
	@echo "$(BLUE)📊 Code Quality Summary$(NC)"
	@echo "$(YELLOW)1. Security (Brakeman):$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) bundle exec brakeman -A -q | grep -E "(No warnings found|warnings found)" || echo "Security check completed"
	@echo "$(YELLOW)2. Best Practices:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) bundle exec rails_best_practices . | grep -E "(Found.*warnings|No warnings)" || echo "Best practices check completed"
	@echo "$(YELLOW)3. Code Smells:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) bundle exec reek app/ lib/ | grep "total warnings" || echo "Code smells check completed"
	@echo "$(YELLOW)4. Duplication:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) bundle exec flay app/ lib/ | grep "Total score" || echo "Duplication check completed"
	@echo "$(YELLOW)5. Vulnerabilities:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) bundle exec bundle-audit check | grep -E "(No vulnerabilities|vulnerabilities found)" || echo "Vulnerability check completed"
	@echo "$(GREEN)✅ Quality summary completed!$(NC)"

# ============================================================================
# 🔍 Development Tools
# ============================================================================

shell: ## Войти в контейнер Rails
	$(COMPOSE) exec $(WEB_SERVICE) bash

console: ## Rails консоль
	$(COMPOSE) exec $(WEB_SERVICE) rails console

logs: ## Показать логи всех сервисов
	$(COMPOSE) logs -f

logs-web: ## Логи web сервиса
	$(COMPOSE) logs -f $(WEB_SERVICE)

logs-sidekiq: ## Логи sidekiq сервиса
	$(COMPOSE) logs -f $(SIDEKIQ_SERVICE)

logs-redis: ## Логи Redis
	$(COMPOSE) logs -f $(REDIS_SERVICE)

# ============================================================================
# 🎯 API Testing
# ============================================================================

api-test: ## Тест API через curl
	@echo "$(BLUE)Testing API endpoints...$(NC)"
	@echo "$(YELLOW)1. Health check...$(NC)"
	@curl -s http://localhost:3000/up > /dev/null && echo "$(GREEN)✅ Health OK$(NC)" || echo "$(RED)❌ Health FAILED$(NC)"
	@echo "$(YELLOW)2. Creating job...$(NC)"
	@job_id=$$(curl -s -X POST http://localhost:3000/complexity-score \
		-H "Content-Type: application/json" \
		-d '{"words": ["test"], "locale": "en"}' | jq -r '.job_id'); \
	echo "Job ID: $$job_id"; \
	sleep 3; \
	echo "$(YELLOW)3. Checking result...$(NC)"; \
	curl -s http://localhost:3000/complexity-score/$$job_id | jq '.'

demo: ## Демонстрация API
	@echo "$(BLUE)🎭 API Demo$(NC)"
	@echo "$(YELLOW)Creating complexity analysis job...$(NC)"
	@job_id=$$(curl -s -X POST http://localhost:3000/complexity-score \
		-H "Content-Type: application/json" \
		-d '{"words": ["beautiful", "complex", "simple"], "locale": "en"}' | jq -r '.job_id'); \
	echo "$(GREEN)Job created: $$job_id$(NC)"; \
	echo "$(YELLOW)Waiting for processing...$(NC)"; \
	sleep 5; \
	echo "$(BLUE)Result:$(NC)"; \
	curl -s http://localhost:3000/complexity-score/$$job_id | jq '.'

# ============================================================================
# 🧽 Cleanup & Maintenance
# ============================================================================

clean: ## Очистить неиспользуемые Docker ресурсы
	@echo "$(BLUE)Cleaning up Docker resources...$(NC)"
	docker system prune -f
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-all: down ## Полная очистка (удалить volumes)
	@echo "$(BLUE)Full cleanup (removing volumes)...$(NC)"
	$(COMPOSE) down -v
	docker system prune -f --volumes
	@echo "$(GREEN)✅ Full cleanup complete$(NC)"

clean-build: ## Очистить и пересобрать образы
	@echo "$(BLUE)Cleaning and rebuilding...$(NC)"
	$(COMPOSE) down -v
	$(COMPOSE) build --no-cache
	@echo "$(GREEN)✅ Clean build complete$(NC)"

cache-clear: ## Очистить Rails кэш
	@echo "$(BLUE)Clearing Rails cache...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) rails cache:clear
	@echo "$(GREEN)✅ Cache cleared$(NC)"

# ============================================================================
# 📦 Dependencies
# ============================================================================

bundle-install: ## Установить gem зависимости
	@echo "$(BLUE)Installing gems...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle install
	@echo "$(GREEN)✅ Gems installed$(NC)"

bundle-update: ## Обновить gem зависимости
	@echo "$(BLUE)Updating gems...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bundle update
	@echo "$(GREEN)✅ Gems updated$(NC)"

# ============================================================================
# 🎯 Quick Commands
# ============================================================================

dev: setup up ## Быстрый старт для разработки

full-test: lint test ## Полное тестирование

ci: build test lint ## CI pipeline

# ============================================================================
# 📝 Info & Debug
# ============================================================================

info: ## Информация о проекте
	@echo "$(BLUE)📊 Project Information$(NC)"
	@echo "Docker Compose version: $$($(COMPOSE) version --short)"
	@echo "Services:"
	@$(COMPOSE) config --services
	@echo ""
	@make status

routes: ## Показать маршруты Rails
	$(COMPOSE) exec $(WEB_SERVICE) rails routes

stats: ## Статистика Redis и задач
	@echo "$(BLUE)System Statistics:$(NC)"
	@$(COMPOSE) exec $(REDIS_SERVICE) redis-cli info memory | grep used_memory_human
	@$(COMPOSE) exec $(WEB_SERVICE) rails runner "puts 'Cache keys: ' + Redis.new.keys('batch:*').count.to_s" 2>/dev/null || echo "No cache keys found" 