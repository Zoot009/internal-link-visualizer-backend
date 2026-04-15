.PHONY: help build up down logs restart clean dev-up dev-down migrate shell db redis

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build Docker images
	docker-compose build

up: ## Start all services (production)
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## View logs from all services
	docker-compose logs -f

restart: ## Restart all services
	docker-compose restart

clean: ## Stop services and remove volumes
	docker-compose down -v

dev-up: ## Start database and Redis for local development
	docker-compose -f docker-compose.dev.yml up -d

dev-down: ## Stop development services
	docker-compose -f docker-compose.dev.yml down

migrate: ## Run Prisma migrations
	docker-compose exec app npx prisma migrate deploy

shell: ## Open shell in app container
	docker-compose exec app sh

db: ## Access PostgreSQL database
	docker-compose exec postgres psql -U postgres -d internal_linking

redis: ## Access Redis CLI
	docker-compose exec redis redis-cli

rebuild: ## Rebuild and restart services
	docker-compose up -d --build
