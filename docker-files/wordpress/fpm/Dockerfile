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

COPY cmd.sh /cmd.sh
RUN chmod +x /cmd.sh

# Start services
CMD ["sh", "/cmd.sh"]
