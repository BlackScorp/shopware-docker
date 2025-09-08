# Simple Docker Container to start Shopware

This docker container is used to quickly create custom plugins for Shopware.
This repo is ment to be an example setup to copy and use.

## Usage

Clone the repo in your project
```
git clone https://github.com/BlackScorp/shopware-docker.git docker
cd docker
```
edit the make file. set shopware version and project name

run command

``
make build
``
this command will build a docker container with shopware installed.

now mount your plugin folder into the backend container in the docker-compose.yml file.
and run the command
``
make run
``
this command will restart the container so that the new mounted folder is available.

adjust the make run command to your needs. e.g. run migrations, install plugins, etc.

## Configuration

you can add a .env file into vars folder for specific shopware version. here you can set php and node version for each shopware version.
the version requirements are defined here
https://developer.shopware.com/docs/guides/installation/requirements.html

## URLs
Shopware Admin: http://localhost/admin
Shopware Frontend: http://localhost
Mailhog: http://localhost/mailer
