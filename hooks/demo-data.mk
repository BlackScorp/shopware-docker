HOOK_BUILD += install-demo-data-plugin

.PHONY: install-demo-data-plugin

install-demo-data-plugin:
	$(DOCKER_BACKEND_COMMAND) -c 'TARGET_DIR=custom/plugins/SwagPlatformDemoData; git -C "$$TARGET_DIR" pull || git clone --depth=1 https://github.com/shopware/SwagPlatformDemoData.git "$$TARGET_DIR"'
	$(DOCKER_BACKEND_COMMAND) -c "cd custom/plugins/SwagPlatformDemoData && composer require --no-install --no-update shopware/core:~6"
	$(DOCKER_BACKEND_COMMAND) -c "bin/console plugin:refresh --no-debug"
	$(DOCKER_BACKEND_COMMAND) -c "bin/console plugin:install -a -c SwagPlatformDemoData --no-debug"