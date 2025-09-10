# Simple Docker Container to start Shopware

This docker container is used to quickly create custom plugins for Shopware.
This repo is ment to be an example setup to copy and use.

## Usage

Clone the repo in your project
```
git clone https://github.com/BlackScorp/shopware-docker.git docker
cd docker
```
create a file .env.local and set your project name and shopware version
```
#.env.local
PROJECT=myawesomeproject
SW_VERSION=6.7.0.0
```
the project name is used to label the docker container so they can be removed later with filters

run command

``
make build
``
this command will build a docker container with shopware installed.
create a composer.override.yaml file with your own volumes in shop.
``
#example composer.override.yaml
volumes:
  - ./myplugin:/var/www/html/custom/plugins/MyPlugin
``
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
Admin Watcher: http://localhost:8080
Shopware Frontend: http://localhost
Storefront Watcher: http://localhost:9998
Mailhog: http://localhost/mailer
