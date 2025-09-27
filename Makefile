# Makefile for Directus with ENV support

BACKEND_SERVICE_NAME=directus
DATABASE_SERVICE_NAME=postgres
DIRECTUS_SYNC_SERVICE_NAME=directus-sync

DIRECTUS_SYNC_CONFIG_PATH=/directus-sync/directus-sync.config.js
DIRECTUS_SYNC_TOOL_FLAGS=--profile tools run --rm --no-deps

#NAMED_COMPOSE_FILE = docker-compose.prod.yml
NAMED_COMPOSE_FILE = docker-compose.yml


# Default environment (dev)
# prod command: make up ENV=prod   # will use docker-compose.prod.yml
#ENV ?= dev

#ifeq ($(ENV),prod)
#  NAMED_COMPOSE_FILE = docker-compose.prod.yml
#else
#  NAMED_COMPOSE_FILE = docker-compose.yml
#endif

## -------------------------
## Base Commands (ENV aware)
## -------------------------

# Directus Container's Commands

up: ## Start Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) up -d

rebuild: ## Rebuild Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) up --build -d

down: ## Stop Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) down

build: ## Build Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) build

build-no-cache: ## Build without Cache
	@docker compose -f $(NAMED_COMPOSE_FILE) build --no-cache

logs: ## Show logs
	@docker compose -f $(NAMED_COMPOSE_FILE) logs -f

restart: ## Restart
	@docker compose -f $(NAMED_COMPOSE_FILE) restart

shell: ## Exec Shell
	@docker compose -f $(NAMED_COMPOSE_FILE) exec -it $(BACKEND_SERVICE_NAME) sh

psql:
	@docker compose -f $(NAMED_COMPOSE_FILE) exec -it $(DATABASE_SERVICE_NAME) psql -d directus_dev -U directus_dev


# Directus-Sync CLI Tool Commands
# cmd 1: docker compose -f ./docker-compose.yml --profile tools run --rm directus-sync pull --config-path /directus-sync/directus-sync.config.js
# cmd 2: docker run --rm directus-sync diff --directus-url "secrets.DIRECTUS_URL" --directus-email "secrets.DIRECTUS_EMAIL" --directus-password "secrets.DIRECTUS_PASSWORD" --debug

sync-build:
	@docker compose -f $(NAMED_COMPOSE_FILE) build $(DIRECTUS_SYNC_SERVICE_NAME) --no-cache

sync-pull:
	@docker compose -f $(NAMED_COMPOSE_FILE) $(DIRECTUS_SYNC_TOOL_FLAGS) directus-sync pull --config-path $(DIRECTUS_SYNC_CONFIG_PATH)

sync-diff:
	@docker compose -f $(NAMED_COMPOSE_FILE) $(DIRECTUS_SYNC_TOOL_FLAGS) directus-sync diff --config-path $(DIRECTUS_SYNC_CONFIG_PATH)

sync-push:
	@docker compose -f $(NAMED_COMPOSE_FILE) $(DIRECTUS_SYNC_TOOL_FLAGS) directus-sync push --config-path $(DIRECTUS_SYNC_CONFIG_PATH)

sync-shell:
	@docker compose -f $(NAMED_COMPOSE_FILE) run --rm --entrypoint sh $(DIRECTUS_SYNC_SERVICE_NAME)

# Others, Testings

volumes-ls-back:
	@docker inspect -f '{{ .Mounts }}' $(BACKEND_SERVICE_NAME)

volumes-ls-db:
	@docker inspect -f '{{ .Mounts }}' $(DATABASE_SERVICE_NAME)


.PHONY: up rebuild down build build-no-cache logs restart shell psql sync-build sync-pull sync-diff sync-push sync-shell volumes-ls-back volumes-ls-db
