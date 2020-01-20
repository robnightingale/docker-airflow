# sone default settings
ROOT = $(shell git rev-parse --show-toplevel)

# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

.DEFAULT_GOAL := help
default: help

# this works by finding all the double-hashes and printing the text beside.
# Useful way to list all your targets
.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

shell: ## run a docker bash shell
	docker-compose -f docker-compose.yml exec $(servicename) sh

start: ## docker-compose up -d
	docker-compose -f docker-compose.yml up -d
	docker-compose -f docker-compose.yml ps

stop: ## docker-compose down
	docker-compose -f docker-compose.yml down

ps: ## docker-compose up -d
	docker-compose -f docker-compose.yml ps

.PHONY: logs
logs: ## view the docker stack logs
	docker-compose -f docker-compose.yml logs ${servicename}

build: ## build a fresh image
	docker build -t ${IMAGE_NAME}:${VERSION} .