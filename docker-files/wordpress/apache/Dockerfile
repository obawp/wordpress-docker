ARG IMAGE_PHP_VERSION
ARG WEBSERVER
FROM wordpress:php$IMAGE_PHP_VERSION-$WEBSERVER

# Install dependencies for WP-CLI
RUN apt-get update -y
RUN apt-get install -y sudo
RUN apt-get install -y unzip
RUN apt-get install -y nano
RUN apt-get install -y htop
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y iputils-ping
RUN apt-get install -y procps
RUN apt-get install -y tzdata
RUN apt-get install -y cron

# Install MySQLi and PDO extensions
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo
RUN docker-php-ext-install pdo_mysql

# Install GD extension
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

RUN apt-get install -y default-mysql-client

# Copying Wordpress files
RUN cp -Rp /usr/src/wordpress/. /var/www/html/

# Setting permissions
RUN chown www-data:www-data -R /var/www/html/
RUN find /var/www/html -type d -exec chmod 0750 {} \;
RUN find /var/www/html -type f -exec chmod 0640 {} \;

# apache modules
RUN a2enmod ssl
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod proxy_fcgi setenvif

RUN a2ensite 000-default.conf
RUN a2ensite default-ssl.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf
RUN rm /etc/apache2/sites-enabled/default-ssl.conf


COPY wordpress.conf /etc/apache2/sites-available/wordpress.conf
RUN sed -i -e 's|your-domain.com|wordpress.local|g' /etc/apache2/sites-available/wordpress.conf

# Adding  Non-interactive self-signed Certificate and 10 years expiration
WORKDIR /etc/letsencrypt/live/wordpress.local/
RUN openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out fullchain.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=wordpress.local"
WORKDIR /var/www/html
RUN a2ensite wordpress.conf


COPY cmd.sh /cmd.sh
RUN chmod +x /cmd.sh

# Start services
CMD ["sh", "/cmd.sh"]
