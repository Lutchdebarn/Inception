#! /bin/sh

set -e

WP_PATH=/var/www/html

: "${WP_ADMIN_EMAIL:?Invalide email}"
if echo "$WP_ADMIN_USER" | grep -qi admin; then
	echo "Error: WP_ADMIN_USER contains admin" >&2
	exit 1
fi

# 1. Download: version.php proves the core files are there
if [ ! -f "$WP_PATH/wp-includes/version.php" ]; then
	wp core download --allow-root --path="$WP_PATH"
fi

# 2. Config: wp-config.php proves the config is done
if [ ! -f "$WP_PATH/wp-config.php" ]; then
	wp config create --allow-root --path="$WP_PATH" \
		--dbname="$SQL_DATABASE" --dbuser="$SQL_USER" \
		--dbpass="$(cat /run/secrets/db_password)" --dbhost=mariadb
fi
if ! wp plugin is-installed redis-cache; then
	wp config set WP_REDIS_HOST redis --allow-root --path="$WP_PATH"
	wp config set WP_REDIS_PORT --raw 6379 --allow-root --path="$WP_PATH"
	wp config set WP_REDIS_PASSWORD "$(cat /run/secrets/redis_password)" --allow-root --path="$WP_PATH"
fi

# 3. Install: asks the database if WordPress is installed
if ! wp core is-installed --allow-root --path="$WP_PATH"; then
	wp core install --allow-root --path="$WP_PATH" \
		--url="https://$DOMAIN_NAME" --title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" --admin_password="$(cat /run/secrets/wp_admin_password)" \
		--admin_email="$WP_ADMIN_EMAIL" --skip-email

	wp plugin install redis-cache --activate --allow-root --path="$WP_PATH"
	wp redis enable --allow-root --path="$WP_PATH"
fi

# 4. Second user: created only if it does not exist yet
if ! wp user get "$WP_USER" --allow-root --path="$WP_PATH" > /dev/null 2>&1; then
	wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root --path="$WP_PATH" \
		--role=author --user_pass="$(cat /run/secrets/wp_user_password)"
fi

# Every start: php-fpm runs as nobody
chown -R nobody:nobody "$WP_PATH"

exec php-fpm83 -F
