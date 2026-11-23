#!/bin/sh
set -e

DIR=/backup
FILE="$DIR/${SQL_DATABASE}_$(date +%Y-%m-%d_%H-%M).sql"

MYSQL_PWD="$(cat /run/secrets/db_password)" \
	mariadb-dump -h mariadb -u "$SQL_USER" --single-transaction "$SQL_DATABASE" > "$FILE"

find "$DIR" -name '*.sql' -mmin +60 -delete
