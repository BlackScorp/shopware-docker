#!/bin/bash
set -e

echo "Check user on container"
whoami

echo "Starting php-fpm..."
php-fpm &

echo "Starting nginx..."
nginx -g 'daemon off;' &

echo "Starting crond..."
crond &


TARGET_DIR="/var/www/html"
ZIP_FILE="/var/www/shopware.zip"
INSTALLED_FILE="/var/www/html/shop.installed"

ls -la $TARGET_DIR

if [ ! -f "$INSTALLED_FILE" ] && [ -f "$ZIP_FILE" ]; then
    echo "Unpacking Shopware..."
    unzip -q "$ZIP_FILE" -d "$TARGET_DIR"
    find $TARGET_DIR -type f -name '.temp.docker' -delete
    rm "$ZIP_FILE"
    touch "$INSTALLED_FILE"
    echo "Unpack done."
fi

touch $TARGET_DIR/var/log/dev.log

exec "$@"

tail -F -s 2 /var/log/**/* $TARGET_DIR/var/log/*.log