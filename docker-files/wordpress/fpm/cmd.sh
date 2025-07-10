#!/bin/bash
set -e

# Set VARIABLE to default value if not already set
TZ=${TZ:-America/Sao_Paulo}
WEB_PORT=${WEB_PORT:-80}
WEBS_PORT=${WEBS_PORT:-443}
DOMAIN=${DOMAIN:-wordpress.local}
export TZ WEB_PORT WEBS_PORT DOMAIN

# Set timezone
rm /etc/localtime && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata



# Start PHP-FPM in the background
php-fpm --nodaemonize 