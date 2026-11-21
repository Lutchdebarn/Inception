#! /bin/sh

set -e 

if [ ! -s /run/secrets/redis_password ]; then
  echo "Error, no password for redis" >&2
  exit 1
fi

exec redis-server --bind 0.0.0.0 --requirepass "$(cat /run/secrets/redis_password)"