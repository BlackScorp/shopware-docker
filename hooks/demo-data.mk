HOOK_BUILD += install-demo-data-plugin

.PHONY: install-demo-data-plugin

install-demo-data-plugin:
	$(DOCKER_BACKEND_EXEC_COMMAND) 'TARGET_DIR=custom/plugins/SwagPlatformDemoData; git -C "$$TARGET_DIR" pull || git clone --depth=1 https://github.com/shopware/SwagPlatformDemoData.git "$$TARGET_DIR"'
	$(DOCKER_BACKEND_EXEC_COMMAND) "cd custom/plugins/SwagPlatformDemoData && composer require --no-install --no-update shopware/core:~6"
	$(DOCKER_BACKEND_EXEC_COMMAND) "bin/console plugin:refresh --no-debug"
	$(DOCKER_BACKEND_EXEC_COMMAND) "bin/console plugin:install -a -c SwagPlatformDemoData --no-debug"