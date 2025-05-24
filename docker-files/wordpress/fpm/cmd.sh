#!/bin/bash
set -e

# Set VARIABLE to default value if not already set
: "${TZ:=America/Sao_Paulo}"
: "${WEB_PORT:=80}"
: "${WEBS_PORT:=443}"
: "${DOMAIN:=wordpress.local}"

# Set timezone
rm /etc/localtime && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata



# Start PHP-FPM in the background
php-fpm --nodaemonize 