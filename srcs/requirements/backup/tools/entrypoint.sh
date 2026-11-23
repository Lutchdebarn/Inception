#!/bin/sh

set -e

echo "$BACKUP_SCHEDULE SQL_USER=$SQL_USER SQL_DATABASE=$SQL_DATABASE /usr/local/bin/backup.sh" > /etc/crontabs/root

exec crond -f
