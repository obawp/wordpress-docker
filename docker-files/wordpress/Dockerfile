FROM wordpress:php7.4-apache

# Install dependencies for WP-CLI
RUN apt-get update -y
RUN apt-get install -y curl
RUN apt-get install -y nano
RUN rm -rf /var/lib/apt/lists/*

# Download and install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

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