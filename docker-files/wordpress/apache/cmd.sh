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

a2dissite wordpress.conf

# Update Nginx configuration to use the specified web port
sed -i "s|wordpress.local|$DOMAIN|g" /etc/apache2/sites-available/wordpress.conf
sed -i "s/Listen 80/Listen $WEB_PORT/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:$WEB_PORT>/" /etc/apache2/sites-available/wordpress.conf
sed -i "s/Listen 443/Listen $WEBS_PORT/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:443>/<VirtualHost *:$WEBS_PORT>/" /etc/apache2/sites-available/wordpress.conf

mkdir -p /etc/letsencrypt/live/$DOMAIN/ || true
cd /etc/letsencrypt/live/$DOMAIN/
sed -i -e "s|SSLCertificateFile      /etc/letsencrypt/live/wordpress.local/fullchain.pem|SSLCertificateFile      /etc/letsencrypt/live/$DOMAIN/fullchain.pem|g" /etc/apache2/sites-available/wordpress.conf
sed -i -e "s|SSLCertificateKeyFile   /etc/letsencrypt/live/wordpress.local/privkey.pem|SSLCertificateKeyFile   /etc/letsencrypt/live/$DOMAIN/privkey.pem|g" /etc/apache2/sites-available/wordpress.conf
openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out fullchain.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=$DOMAIN"
cd /var/www/html

a2ensite wordpress.conf

# Start Cron service if ENABLE_CRON is set to true, else show a message
if [ "${ENABLE_CRON}" = "true" ]; then
    /etc/init.d/cron start & # do not remove the &
else
    /etc/init.d/cron stop
fi

# Start Apache in the foreground
apache2ctl -D FOREGROUND &

# Restart Apache every 12 hours to apply certbot renewal
while true; do
    sleep 12h
    apache2ctl graceful
done
