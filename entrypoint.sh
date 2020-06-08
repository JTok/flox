#!/bin/bash
set -eux

# Set env variables
ENV APACHE_RUN_USER user
ENV APACHE_RUN_USER_ID 1000
ENV APACHE_RUN_GROUP user
ENV APACHE_RUN_GROUP_ID 1000

# Check if user exists
if ! id -u ${APACHE_RUN_USER} > /dev/null 2>&1; then
	echo "The user ${APACHE_RUN_USER} does not exist, creating..."
	groupadd -f -g ${APACHE_RUN_GROUP_ID} ${APACHE_RUN_GROUP}
	useradd -u ${APACHE_RUN_USER_ID} -g ${APACHE_RUN_GROUP} ${APACHE_RUN_USER}
fi

# Check Setup on first run only
if [ ! -e /var/www/html/backend/.env ];  then
	echo "[flox first install]"
	mysql_host="${FLOX_DB_HOST:-mysql}"
	mysql_port="${FLOX_DB_PORT:-3306}"
	/wait-for-it.sh $mysql_host:$mysql_port -t 120 -- /init-run.sh
fi

exec "$@"
