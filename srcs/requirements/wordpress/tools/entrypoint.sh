#! /bin/sh

set -e

if [ ! -f /var/www/html/wp-config.php ]; then
	wp core download --allow-root --path=/var/www/html

	wp config create --allow-root --path=/var/www/html \
		--dbname="$SQL_DATABASE" --dbuser="$SQL_USER" \
		--dbpass="$SQL_PASSWORD" --dbhost=mariadb

	wp core install --allow-root --path=/var/www/html \
		--url="$DOMAIN_NAME" --title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" --skip-email

	wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root --path=/var/www/html \
		--role=author --user_pass="$WP_USER_PASSWORD"
	chown -R nobody:nobody /var/www/html
fi

exec php-fpm83 -F
