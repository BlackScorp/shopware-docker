.PHONY: help hook-start hook-build
.DEFAULT_GOAL := help

ENV_FILE_BASE := .env
ENV_FILE_LOCAL := .env.local
-include $(ENV_FILE_BASE) $(ENV_FILE_LOCAL)

SW_MAJOR_VERSION := $(strip $(shell echo $(SW_VERSION) | cut -d. -f1,2))


ENV_FILE_VERSION_EXACT := vars/$(SW_VERSION).env
ENV_FILE_VERSION_MAJOR := vars/$(SW_MAJOR_VERSION).env

-include $(ENV_FILE_VERSION_MAJOR) $(ENV_FILE_VERSION_EXACT)
export $(shell sed -n 's/^[[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\)[[:space:]]*=.*/\1/p' $(ENV_FILE_BASE) $(ENV_FILE_LOCAL) 2>/dev/null)

-include hooks/demo-data.mk
-include hooks/*.local.mk
-include hooks/merge-plugin.mk

DOCKER_RUN_COMMAND = docker compose up -d
DOCKER_BACKEND_COMMAND = docker exec -it $(SHOP_CONTAINER) sh
DOCKER_ROOT_BACKEND_COMMAND = docker exec -u root -it $(SHOP_CONTAINER) sh


hook-start: $(HOOK_START)
hook-build: $(HOOK_BUILD)

IS_SW_64 :=$(filter 6.4,$(SW_MAJOR_VERSION))
IS_SW_65 :=$(filter 6.5,$(SW_MAJOR_VERSION))
IS_SW_66 :=$(filter 6.6,$(SW_MAJOR_VERSION))
IS_SW_67 :=$(filter 6.7,$(SW_MAJOR_VERSION))


SHOPWARE_ENV_FILE := .env.local
ifneq ($(IS_SW_64),)
	SHOPWARE_ENV_FILE := .env
endif


help:
	@echo $(MAKEFILE_LIST)
	@echo "Shopware Setup"
	@echo "PROJECT=$(PROJECT)"
	@echo "SW_VERSION=$(SW_VERSION)"
	@echo "SW_MAJOR_VERSION=$(SW_MAJOR_VERSION)"
	@echo "ENV_FILE=$(SHOPWARE_ENV_FILE)"
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

init: ##1 build a docker container, use this when you change shopware version or need a clean setup
	make kill
	make build
	make setup
	make hook-build
	make hook-start
	make download-vendor
	make open

run: ##1 command start container, use this command if you already build the container
	make stop
	make start
	make hook-start
	make open


ssh: ##2 quick access into container
	$(DOCKER_BACKEND_COMMAND)

ussh: ##2 quick access into container as root
	$(DOCKER_ROOT_BACKEND_COMMAND)


download-src: ##2 downloads the complete shop code for code completion
	docker cp $(SHOP_CONTAINER):/var/www/html $(PROJECT_DIR)

download-vendor: ##2 downloads the vendor code for code completion
	docker cp $(SHOP_CONTAINER):/var/www/html/vendor $(PROJECT_DIR)

watch-admin: ##2 start admin watcher
ifneq ($(IS_SW_65),)
	$(DOCKER_BACKEND_COMMAND) -c "APP_URL=http://$(SHOP_CONTAINER) HOST=0.0.0.0 bin/watch-administration.sh"
else ifneq ($(IS_SW_67),)
	$(DOCKER_BACKEND_COMMAND) -c "ADMIN_PORT=8080 VITE_HOST=0.0.0.0 HOST=0.0.0.0 bin/watch-administration.sh"
else
	$(DOCKER_BACKEND_COMMAND) -c "HOST=0.0.0.0 bin/watch-administration.sh"
endif

build-admin: ##2 build administration
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-administration.sh"

build-sf: ##2 build storefront
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-storefront.sh"

build-js: ##2 build storefront and admin
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-js.sh"

watch-sf: ##2 start storefront watcher
ifneq ($(IS_SW_65),)
	$(DOCKER_BACKEND_COMMAND) -c "IPV4FIRST=1 bin/watch-storefront.sh"
else ifneq ($(IS_SW_67),)
	$(DOCKER_BACKEND_COMMAND) -c "VITE_EXTENSIONS_SERVER_HOST=$(DOMAIN) VITE_EXTENSIONS_SERVER_SCHEME=$(HTTP_SCHEME) bin/watch-storefront.sh"
else
	$(DOCKER_BACKEND_COMMAND) -c "bin/watch-storefront.sh"
endif

cc: ##2 clear cache
	$(DOCKER_BACKEND_COMMAND) -c "rm -rf var/cache/* && bin/console cache:clear --no-debug"

start: ##4 start docker container
	$(DOCKER_RUN_COMMAND)

build: ##4 build container
	$(DOCKER_RUN_COMMAND) --build

stop: ##4 stop container
	docker stop $$(docker ps -aq) || true
	docker rm $$(docker ps -aq) || true

kill: ##4 clear images and volumes
	make stop
	docker image rm $$(docker image ls -q -f "label=com.docker.compose.project=$(PROJECT)") || true
	docker volume rm $$(docker volume ls -q -f "label=com.docker.compose.project=$(PROJECT)") || true

setup: ##4 initial setup
	$(DOCKER_BACKEND_COMMAND) -c "echo APP_ENV=dev > $(SHOPWARE_ENV_FILE)"
	$(DOCKER_BACKEND_COMMAND) -c "echo APP_URL=$(HTTP_SCHEME)://$(DOMAIN) >> $(SHOPWARE_ENV_FILE)"
	$(DOCKER_BACKEND_COMMAND) -c "echo DATABASE_URL=mysql://dev:dev@database/shopware >> $(SHOPWARE_ENV_FILE)"
	$(DOCKER_BACKEND_COMMAND) -c "echo APP_SECRET=my-secret >> $(SHOPWARE_ENV_FILE)"
ifneq ($(IS_SW_64),)
	$(DOCKER_BACKEND_COMMAND) -c "echo MAILER_URL=smtp://mailer:1025 >> $(SHOPWARE_ENV_FILE)"
	$(DOCKER_ROOT_BACKEND_COMMAND) -c "wget https://getcomposer.org/download/2.2.9/composer.phar && chmod a+x composer.phar && mv composer.phar /usr/local/bin/composer"
else
	$(DOCKER_BACKEND_COMMAND) -c "echo MAILER_DSN=smtp://mailer:1025 >> $(SHOPWARE_ENV_FILE)"
	$(DOCKER_BACKEND_COMMAND) -c "composer require --dev shopware/dev-tools"
endif
	make cc
	$(DOCKER_BACKEND_COMMAND) -c "bin/console system:install --drop-database --create-database --basic-setup -n --no-debug -f"
	$(DOCKER_BACKEND_COMMAND) -c 'bin/console system:generate-app-secret | sed "s/^/APP_SECRET=/" >> $(SHOPWARE_ENV_FILE)'
	$(DOCKER_BACKEND_COMMAND) -c 'bin/console system:config:set core.frw.completedAt "2025-01-01 01:01:01" -q'
ifneq ($(IS_SW_64),)
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-js.sh"
endif
ifneq ($(IS_SW_65),)
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-storefront.sh"
endif

open:
	open $(HTTP_SCHEME)://$(DOMAIN)
	open $(HTTP_SCHEME)://$(DOMAIN)/admin