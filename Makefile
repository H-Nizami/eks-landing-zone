SHELL := /bin/bash
.DEFAULT_GOAL := help

# Pinned binaries from `make tools` (.bin/) first; PATH only as a fallback.
tool = $(shell if [ -x .bin/$(1) ]; then echo .bin/$(1); else command -v $(1) || echo .bin/$(1); fi)
ACTIONLINT := $(call tool,actionlint)
SHELLCHECK := $(call tool,shellcheck)
D2 := $(call tool,d2)
export D2

UP_DOWN_MSG := live deployment is disabled until an approved, time-boxed AWS run (needs AWS credits)

.PHONY: all help tools lint test test-iac security diagram up down

all: lint test diagram ## Run lint, test and diagram

help: ## List targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-z]+:.*## / {printf "  %-8s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tools: ## Install pinned tool binaries into .bin/ (sha256-verified)
	scripts/tools.sh d2 actionlint gitleaks trivy terraform tofu tflint

lint: ## actionlint, shellcheck, d2 validate, hygiene checks
	$(ACTIONLINT)
	$(SHELLCHECK) scripts/*.sh
	$(D2) validate docs/architecture.d2
	scripts/check-hygiene.sh
	$(call tool,terraform) fmt -check -recursive .
	$(call tool,tofu) fmt -check -recursive .
	$(call tool,tflint) --recursive

test: ## Offline contract tests with both CLIs
	scripts/check-hygiene.sh
	scripts/check-iac-safety.py
	scripts/test-iac.sh terraform
	scripts/test-iac.sh tofu

test-iac: ## Run provider-mocked plan tests for CLI=terraform|tofu
	scripts/test-iac.sh $(CLI)

security: ## Run local secret and configuration scanners
	scripts/check-security.sh

diagram: ## Render docs/architecture.d2 to docs/img/architecture.{svg,png}
	scripts/render-diagram.sh

up: ## Bring up the local environment
	@echo "$(UP_DOWN_MSG)" >&2; exit 1

down: ## Tear down the local environment
	@echo "$(UP_DOWN_MSG)" >&2; exit 1
