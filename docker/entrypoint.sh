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

echo "Starting ssh daemon"
/usr/sbin/sshd -D -f /var/www/.ssh/etc/ssh/sshd_config -e &

exec "$@"