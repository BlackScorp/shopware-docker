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


if [ -f "$ZIP_FILE" ]; then
    echo "Unpacking Shopware..."
    unzip -q "$ZIP_FILE" -d "$TARGET_DIR"
    rm "$ZIP_FILE"
    echo "Unpack done."
fi


exec "$@"