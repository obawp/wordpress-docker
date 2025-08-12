#!/bin/bash
set -e

TZ=${TZ:-America/Sao_Paulo}
WEB_PORT=${WEB_PORT:-80}
WEBS_PORT=${WEBS_PORT:-443}
DOMAIN=${DOMAIN:-wordpress.local}
ENABLE_CRON=${ENABLE_CRON:-true}
export TZ WEB_PORT WEBS_PORT DOMAIN

# Set timezone
rm /etc/localtime && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# Start Cron service if ENABLE_CRON is set to true, else show a message
if [ "${ENABLE_CRON}" = "true" ]; then
    /etc/init.d/cron start & # do not remove the &
else
    /etc/init.d/cron stop
fi

# Start PHP-FPM in the background
php-fpm --nodaemonize 
