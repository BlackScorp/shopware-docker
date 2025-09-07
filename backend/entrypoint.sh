echo "Check user on container"
whoami

echo "start php-fpm"
php-fpm
echo "start nginx"
nginx
echo "start crond"
crond

exec "$@"

tail -f /var/log/**/*