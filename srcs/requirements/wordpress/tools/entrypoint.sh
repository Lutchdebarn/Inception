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
		--dbname="$SQL_DATABASE" --dbuser="$SQL_USER" \
		--dbpass="$SQL_PASSWORD" --dbhost=mariadb

	wp core install --allow-root --path=/var/www/html \
		--url="https://$DOMAIN_NAME" --title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" --admin_password="$(cat /run/secrets/wp_admin_password.txt)" \
		--admin_email="$WP_ADMIN_EMAIL" --skip-email
	wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root --path=/var/www/html \
		--role=author --user_pass="$(cat /run/secrets/wp_user_password.txt)"
	chown -R nobody:nobody /var/www/html
fi

exec php-fpm83 -F
