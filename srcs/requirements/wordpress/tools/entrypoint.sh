#! /bin/sh

set -e

: "${WP_ADMIN_EMAIL:?Invalide email}"
if echo "$WP_ADMIN_USER" | grep -qi admin; then
	echo "Error: WP_ADMIN_USER contains admin" >&2
	exit 1
fi

if [ ! -f /var/www/html/wp-config.php ]; then
	wp core download --allow-root --path=/var/www/html

	wp config create --allow-root --path=/var/www/html \
		--dbname="$(cat /run/secrets/db_password.txt)" --dbuser="$SQL_USER" \
		--dbpass="$(cat /run/secrets/db_root_password.txt)" --dbhost=mariadb

	wp core install --allow-root --path=/var/www/html \
		--url="https://$DOMAIN_NAME" --title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" --admin_password="$(cat /run/secrets/wp_admin_password)" \
		--admin_email="$WP_ADMIN_EMAIL" --skip-email

	wp config set WP_REDIS_HOST redis --allow-root --path=/var/www/html
	wp config set WP_REDIS_PORT --raw 6379 --allow-root --path=/var/www/html

	wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root --path=/var/www/html \
		--role=author --user_pass="$(cat /run/secrets/wp_user_password)"

	chown -R nobody:nobody /var/www/html
fi

exec php-fpm83 -F
