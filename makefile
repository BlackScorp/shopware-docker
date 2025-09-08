.PHONY: help
.DEFAULT_GOAL := help

load-env = $(if $(wildcard $(1)), \
    $(foreach line,$(shell grep -v '^#' $(1)), \
        $(eval export $(line)) \
    ) \
)

ENV_FILE_BASE := .env
ENV_FILE_LOCAL := .env.local
$(call load-env,$(ENV_FILE_BASE))
$(call load-env,$(ENV_FILE_LOCAL))
SW_MAJOR_VERSION := $(shell echo $(SW_VERSION) | cut -d. -f1,2)
ENV_FILE_VERSION_EXACT := vars/$(SW_VERSION).env
ENV_FILE_VERSION_MAJOR := vars/$(SW_MAJOR_VERSION).env


ifeq ($(wildcard $(ENV_FILE_VERSION_EXACT)),)
    $(call load-env,$(ENV_FILE_VERSION_MAJOR))
else
    $(call load-env,$(ENV_FILE_VERSION_EXACT))
endif



DOCKER_RUN_COMMAND = docker compose up  --pull always -d



help:
	@echo "Shopware Setup"
	@echo "PROJECT=$(PROJECT)"
	@echo "SW_VERSION=$(SW_VERSION)"
	@echo "PHP_VERSION=$(PHP_VERSION)"
	@echo "NODE_VERSION=$(NODE_VERSION)"
	@echo "MARIADB_VERSION=$(MARIADB_VERSION)"
	@echo "ALPINE_VERSION=$(ALPINE_VERSION)"
	@echo "PROJECT COMMANDS"
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[33mInstallation:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##1 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##1 "}; {printf "\033[33m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[36mDevelopment:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##2 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##2 "}; {printf "\033[36m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[32mTests:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##3 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##3 "}; {printf "\033[32m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "---------------------------------------------------------------------------------------------------------"
	@printf "\033[35mDevOps:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##4 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##4 "}; {printf "\033[35m  - %-30s\033[0m %s\n", $$1, $$2}'

build: ##1 build a docker container, needed when you change variables
	make clean-docker
	make build-container
	make setup
	open $(HTTP_SCHEME)://$(DOMAIN)

run: ##1 command start container
	make stop-container
	make start-container
	open $(HTTP_SCHEME)://$(DOMAIN)


ssh: ##2 quick access into container
	docker exec -it backend sh


download-src: ##2 downloads the vendor code for code completion
	docker cp backend:/var/www/html/vendor ./../

watch-admin: ##2 start admin watcher
	docker exec -it backend sh -c "VITE_EXTENSIONS_SERVER_HOST=$(DOMAIN) VITE_EXTENSIONS_SERVER_SCHEME=$(HTTP_SCHEME) ADMIN_PORT=8888 HOST=0.0.0.0 bin/watch-administration.sh"

watch-sf: ##2 start storefront wathcer
	docker exec -it backend sh -c "bin/watch-storefront.sh"


#------------ private commands

start-container:
	$(DOCKER_RUN_COMMAND)

build-container:
	$(DOCKER_RUN_COMMAND) --build

stop-container:
	docker stop $$(docker ps -q) || true
	docker rm $$(docker ps -aq) || true

clean-docker:
	make stop-container
	docker image rm $$(docker image ls -q -f "label=com.docker.compose.project=$(PROJECT)") || true
	docker volume rm $$(docker volume ls -q -f "label=com.docker.compose.project=$(PROJECT)") || true

setup:
	docker exec -it backend sh -c 'bin/console system:generate-app-secret | sed "s/^/APP_SECRET=/" > .env.local'
	docker exec -it backend sh -c "echo APP_ENV=dev >> .env.local"
	docker exec -it backend sh -c "echo APP_URL=$(HTTP_SCHEME)://$(DOMAIN) >> .env.local"
	docker exec -it backend sh -c "echo DATABASE_URL=mysql://dev:dev@database/shopware >> .env.local"
	docker exec -it backend sh -c "echo MAILER_URL=smtp://mailer:1025 >> .env.local"
	docker exec -it backend sh -c "bin/console cache:clear"
	docker exec -it backend sh -c "bin/console system:install --drop-database --create-database --basic-setup -n -f"
	docker exec -it backend sh -c 'bin/console system:config:set core.frw.completedAt "2025-01-01 10:00:00"'
	make download-src