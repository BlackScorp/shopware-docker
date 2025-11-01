HOOK_BUILD += setup-wikimedia

.PHONY: setup-wikimedia

setup-wikimedia:
	$(DOCKER_BACKEND_COMMAND) -c "composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true"
	$(DOCKER_BACKEND_COMMAND) -c "composer require wikimedia/composer-merge-plugin:*"
