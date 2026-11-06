#! /bin/sh

set -e

if [ ! -d /var/www/html/wp-config.php]; then
...
fi

exec php-fpm83 -F
