HOOK_BUILD += setup-wikimedia

.PHONY: setup-wikimedia

setup-wikimedia:
	$(DOCKER_BACKEND_EXEC_COMMAND) "composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true"
	$(DOCKER_BACKEND_EXEC_COMMAND) "composer require wikimedia/composer-merge-plugin:*"
