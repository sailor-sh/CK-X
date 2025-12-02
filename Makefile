SHELL := /bin/bash

# Environment
ENV_FILE ?= .env
COMPOSE ?= docker compose

.PHONY: help
help:
	@echo "Common targets:"
	@echo "  make up              # Start all services (reads .env)"
	@echo "  make down            # Stop all services"
	@echo "  make restart         # Restart services"
	@echo "  make pull            # Pull images"
	@echo "  make reset           # Down + remove volumes, then pull"
	@echo "  make check-answers   # Verify answers.md paths exist"
	@echo "  make release-exam3   # Build and push multi-arch images for exam3"
	@echo "  make test            # Run repository tests"

.PHONY: up
up:
	$(COMPOSE) up -d

.PHONY: down
down:
	$(COMPOSE) down

.PHONY: restart
restart: down up

.PHONY: pull
pull:
	$(COMPOSE) pull

.PHONY: reset
reset:
	$(COMPOSE) down -v || true
	$(COMPOSE) pull

.PHONY: reset-up
reset-up: reset up

.PHONY: check-answers
check-answers:
	bash scripts/check_answers.sh

# Usage: DOCKERHUB_NAMESPACE=<ns> VERSION=<tag> make release-exam3
.PHONY: release-exam3
release-exam3:
	@if [[ -z "$$DOCKERHUB_NAMESPACE" || -z "$$VERSION" ]]; then \
		echo "Set DOCKERHUB_NAMESPACE and VERSION, e.g. DOCKERHUB_NAMESPACE=je01 VERSION=exam3-v2"; \
		exit 1; \
	fi
	bash scripts/buildx_multiarch_exam3.sh

.PHONY: build-and-push
build-and-push: release-exam3

.PHONY: test
test:
	bash tests/run_all.sh
