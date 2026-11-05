#! /bin/sh

#stop at the first error
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Init, only for the first time
if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-dbn --user=mysql --datadir=/var/lib/mysql
	mariadbd --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
if

exec mariadbd --user=mysql
