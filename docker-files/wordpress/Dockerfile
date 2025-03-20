FROM wordpress:php7.4-apache

# Install dependencies for WP-CLI
RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN apt-get install -y curl
RUN apt-get install -y nano
RUN apt-get install -y sudo

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

# Download and install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/.wp-cli/cache/
RUN chown www-data:www-data /var/www/.wp-cli/cache/

# Verify WP-CLI installation
RUN wp --info

# Updating WP-CLI
RUN wp cli update

# Set up working directory
WORKDIR /var/www/html

# Ensure permissions for WordPress files
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache server
CMD ["apache2-foreground"]