.PHONY: help hook-start hook-build
.DEFAULT_GOAL := help


ROOT_DIR:=$(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
WORKING_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# variables from env files
# we want to overwrite variables based on file priority
# .env > .env.local > var/6.4.env > var/6.4.20.2.env  more specific file wins
ENV_FILE_BASE := $(ROOT_DIR)/.env
ENV_FILE_LOCAL := $(WORKING_DIR)/.env.local
-include $(ENV_FILE_BASE) $(ENV_FILE_LOCAL)
SW_MAJOR_VERSION := $(strip $(shell echo $(SW_VERSION) | cut -d. -f1,2))
ENV_FILE_VERSION_EXACT := $(ROOT_DIR)/vars/$(SW_VERSION).env
ENV_FILE_VERSION_MAJOR := $(ROOT_DIR)/vars/$(SW_MAJOR_VERSION).env
-include $(ENV_FILE_VERSION_MAJOR) $(ENV_FILE_VERSION_EXACT)
# this line exports the variables from env file so docker compose up use the correct variables
export $(shell sed -n 's/^[[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\)[[:space:]]*=.*/\1/p' $(ENV_FILE_BASE) $(ENV_FILE_LOCAL) $(ENV_FILE_VERSION_MAJOR) $(ENV_FILE_VERSION_EXACT) 2>/dev/null)

# base docker commands
DOCKER_RUN_COMMAND = docker compose -f $(ROOT_DIR)/compose.yaml -f $(WORKING_DIR)/compose.override.yaml up -d --wait
DOCKER_BACKEND_COMMAND = docker exec -it $(SHOP_CONTAINER) sh
DOCKER_ROOT_BACKEND_COMMAND = docker exec -u root -it $(SHOP_CONTAINER) sh

PROJECT_URL := $(HTTP_SCHEME)://$(DOMAIN)
# helper to check different SW versions
IS_SW_64 :=$(filter 6.4,$(SW_MAJOR_VERSION))
IS_SW_65 :=$(filter 6.5,$(SW_MAJOR_VERSION))
IS_SW_66 :=$(filter 6.6,$(SW_MAJOR_VERSION))
IS_SW_67 :=$(filter 6.7,$(SW_MAJOR_VERSION))

SHOPWARE_ENV_FILE := .env.local
ifneq ($(IS_SW_64),)
	SHOPWARE_ENV_FILE := .env
endif
# in case we need the variable for bind mount
export SHOPWARE_ENV_FILE
# hooks without numbers are executed first. then numbered hooks are executed. higher number means executed as last
ALPHA_HOOKS := $(wildcard $(ROOT_DIR)/hooks/[a-z]*.mk hooks/[a-z]*.mk)
NUM_HOOKS   := $(sort $(wildcard $(ROOT_DIR)/hooks/[0-9]*.mk hooks/[0-9]*.mk))
HOOKS := $(ALPHA_HOOKS) $(NUM_HOOKS)

-include $(HOOKS)

hook-start: $(HOOK_START)
hook-build: $(HOOK_BUILD)

help:
	@echo "Included files: $(MAKEFILE_LIST)"
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
	@grep -h -E '^[a-zA-Z_-]+:.*?##1 .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##1 "}; {printf "\033[33m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[36mDevelopment:%-30s\033[0m %s\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?##2 .*$$'  $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##2 "}; {printf "\033[36m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[32mTests:%-30s\033[0m %s\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?##3 .*$$'  $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##3 "}; {printf "\033[32m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "---------------------------------------------------------------------------------------------------------"
	@printf "\033[35mDevOps:%-30s\033[0m %s\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?##4 .*$$'  $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##4 "}; {printf "\033[35m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "---------------------------------------------------------------------------------------------------------"
	@printf "\033[37mLocal:%-30s\033[0m %s\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?##5 .*$$'  $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##5 "}; {printf "\033[37m  - %-30s\033[0m %s\n", $$1, $$2}'

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

kill: ##4 clear volumes
	make stop
	docker volume rm $$(docker volume ls -q -f "label=com.docker.compose.project=$(PROJECT)") || true

setup: ##4 initial setup
	$(DOCKER_BACKEND_COMMAND) -c "echo APP_ENV=dev > $(SHOPWARE_ENV_FILE)"
	$(DOCKER_BACKEND_COMMAND) -c "echo APP_URL=$(PROJECT_URL) >> $(SHOPWARE_ENV_FILE)"
	$(DOCKER_BACKEND_COMMAND) -c "echo DATABASE_URL=mysql://dev:dev@database/shopware >> $(SHOPWARE_ENV_FILE)"
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
	$(DOCKER_BACKEND_COMMAND) -c 'bin/console sales-channel:update:domain $(DOMAIN) -q'
ifneq ($(IS_SW_64),)
	$(DOCKER_BACKEND_COMMAND) -c 'mkdir -p /var/www/html/var/test/jwt && cp /var/www/html/config/jwt/*.pem /var/www/html/var/test/jwt && chmod 0660 /var/www/html/var/test/jwt/*.pem'
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-js.sh"
endif
ifneq ($(IS_SW_65),)
	$(DOCKER_BACKEND_COMMAND) -c "bin/build-storefront.sh"
endif

open:
	open $(PROJECT_URL)
	open $(PROJECT_URL)/admin