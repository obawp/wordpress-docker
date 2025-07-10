include ./.env
export

REPO_NAME := ${REPO}:php${PHP_VERSION}-${WEBSERVER}
STACK_NAME := ${STACK}_wordpress
STACK_VOLUME := ${VOLUME_DIR}/${STACK_NAME}
STACK_SRC := ./src/${STACK_NAME}

build:
	- docker build --build-arg PHP_VERSION=${PHP_VERSION} --build-arg WEBSERVER=${WEBSERVER} -t ${REPO_NAME} ./docker-files/wordpress/${WEBSERVER}/

build_verbose:
	- docker build --build-arg PHP_VERSION=${PHP_VERSION} --build-arg WEBSERVER=${WEBSERVER} --progress=plain -t ${REPO_NAME} ./docker-files/wordpress/${WEBSERVER}/

build_no_cache:
	- docker build --build-arg PHP_VERSION=${PHP_VERSION} --build-arg WEBSERVER=${WEBSERVER} --no-cache --pull -t ${REPO_NAME} ./docker-files/wordpress/${WEBSERVER}/

login:
	- echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin

push:
	- docker push ${REPO_NAME}

pull:
	- docker pull ${REPO_NAME}

run:
	- docker run -d --name ${STACK_NAME}_aux ${REPO_NAME}

mkdir:

	- sudo mkdir -p ${STACK_VOLUME}/mysql/data
	- sudo mkdir ./src/
	- sudo chown $$USER:www-data ./src/
	- sudo mkdir -p ${STACK_SRC}
	- sudo chown $$USER:www-data ${VOLUME_DIR}
	- sudo chown $$USER:www-data ${STACK_VOLUME}
	- sudo chown $$USER:www-data ${STACK_VOLUME}/mysql/data
	- sudo chown $$USER:www-data ${STACK_SRC}
	- make --no-print-directory mkdir_certbot
	make --no-print-directory copy_config_extra
	- make --no-print-directory cp_aux

cp_aux:
	@if docker ps -a --format '{{.Names}}' | grep -q "^${STACK_NAME}_aux$$"; then \
		sudo rm -Rf ${STACK_SRC}; \
		docker cp ${STACK_NAME}_aux:/var/www/html ${STACK_SRC}; \
	else \
		echo "Skipping src folder copy of the container ${STACK_NAME}_aux."; \
	fi

copy_config_extra:
	@if [ ! -f ./config/wp/config.extra.php ]; then \
		cp ./config/wp/config.extra.sample.php ./config/wp/config.extra.php; \
		sudo chown $$USER:www-data ./config/wp/config.extra.php; \
    fi

mkdir_certbot:
	- sudo mkdir -p ${STACK_VOLUME}/wordpress/certbot/www/.well-known/acme-challenge/
	- sudo mkdir -p ${STACK_VOLUME}/wordpress/certbot/conf
	- sudo chown $$USER:$$USER -R ${STACK_VOLUME}/wordpress/certbot
	- sudo chmod 755 ${STACK_VOLUME}/wordpress/certbot
	- sudo chown $$USER:$$USER ${STACK_VOLUME}/wordpress/certbot/www
	- sudo chmod 755 ${STACK_VOLUME}/wordpress/certbot/www
	- sudo chown $$USER:$$USER ${STACK_VOLUME}/wordpress/certbot/conf
	- sudo chmod 755 ${STACK_VOLUME}/wordpress/certbot/conf

rmdir_certbot:
	- sudo rm -Rf ${STACK_VOLUME}/wordpress/certbot/www/
	- sudo rm -Rf ${STACK_VOLUME}/wordpress/certbot/conf/

rmdir:
	- sudo rm -Rf ${STACK_SRC}
	- make --no-print-directory rmdir_db

rmdir_db:
	- sudo rm -Rf ${STACK_VOLUME}/mysql/data

cp_certbot:
	docker cp ${STACK_NAME}_aux:/etc/letsencrypt ${STACK_VOLUME}/wordpress/certbot/conf;
	sudo find ${STACK_VOLUME}/wordpress/certbot/conf -type d -exec chmod 0700 {} \;
	sudo find ${STACK_VOLUME}/wordpress/certbot/conf -type f -exec chmod 0600 {} \;
	sudo chown -R root:root ${STACK_VOLUME}/wordpress/certbot/conf

pre_up:
	- docker network rm  ${STACK_NAME}_apache -f || true
	- docker network rm  ${STACK_NAME}_nginx -f || true
	- docker network rm  ${STACK_NAME}_pma -f || true
	if sudo test ! -d "${STACK_VOLUME}/wordpress/certbot/conf/live/${DOMAIN}"; then \
		mkdir -p ${STACK_VOLUME}/wordpress/certbot/conf/live/${DOMAIN}; \
		openssl req -x509 -newkey rsa:4096 -keyout ${STACK_VOLUME}/wordpress/certbot/conf/live/${DOMAIN}/privkey.pem -out ${STACK_VOLUME}/wordpress/certbot/conf/live/${DOMAIN}/fullchain.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=wordpress.local"; \
	else \
		echo "Certificate exists. Skipping."; \
	fi

# It was needed to pass the fpm container Ip to the hosts file in the webserver container. I tried to avoid the restart twice but I think it is the best way to do it. This change is waste of time.
up:
	make --no-print-directory pre_up
	- docker network create ${STACK_NAME}_cli_network || true
	- docker network create ${STACK_NAME}_fpm_network || true
	@if [ "$(WEBSERVER)" = "fpm" ]; then \
		FPM_IP=127.0.0.1 docker compose -p ${STACK_NAME} --project-directory ./ -f ./docker-compose/docker-compose.${WEBSERVER}.yml -f ./docker-compose/fpm/docker-compose.${FPM}.yml up -d --remove-orphans; \
		FPM_IP=$$(docker inspect -f '{{.NetworkSettings.Networks.${STACK_NAME}_fpm_network.IPAddress}}' ${STACK_NAME}_web/); \
		FPM_IP=$$FPM_IP docker compose -p ${STACK_NAME} --project-directory ./ -f ./docker-compose/docker-compose.${WEBSERVER}.yml -f ./docker-compose/fpm/docker-compose.${FPM}.yml up -d --remove-orphans; \
	else \
		docker compose -p ${STACK_NAME} --project-directory ./ -f ./docker-compose/docker-compose.${WEBSERVER}.yml up -d --remove-orphans; \
	fi

perm:
	-  docker exec -u 0 ${STACK_NAME}_web chown www-data:www-data -R /var/www/html/
	-  docker exec -u 0 ${STACK_NAME}_web find /var/www/html -type d -exec chmod 0755 {} \;
	-  docker exec -u 0 ${STACK_NAME}_web find /var/www/html -type f -exec chmod 0644 {} \;

perm_dev:
	-  sudo chown $$USER:www-data -R ${STACK_SRC}
	-  sudo find ${STACK_SRC} -type d -exec chmod 0775 {} \;
	-  sudo find ${STACK_SRC} -type f -exec chmod 0664 {} \;

perm_db:
	-  docker exec -u 0 ${STACK_NAME}_db chown -R mysql:mysql /var/lib/mysql


mysql:
	- docker exec -it ${STACK_NAME}_db mysql -u root -p${MYSQL_ROOT_PASSWORD}

rm:
	- docker rm ${STACK_NAME}_aux -f
	$(eval COMPOSE_FILES=-f ./docker-compose/docker-compose.${WEBSERVER}.yml)
	@if [ "$(WEBSERVER)" = "fpm" ]; then \
		COMPOSE_FILES="$$COMPOSE_FILES -f ./docker-compose/fpm/docker-compose.${FPM}.yml"; \
		FPM_IP=127.0.0.1 docker compose -p ${STACK_NAME} --project-directory ./ $$COMPOSE_FILES down --remove-orphans; \
	else \
		docker compose -p ${STACK_NAME} --project-directory ./ $(COMPOSE_FILES) down --remove-orphans; \
	fi
	- docker network rm ${STACK_NAME}_cli_network || true

bash:
	- docker exec -it -u 0 -w /var/www/html ${STACK_NAME}_web bash

# make cli cmd="wp --info"
cli:
	docker run -u www-data -it --rm \
		--user "$$(docker exec ${STACK_NAME}_web id -u www-data):$$(docker exec ${STACK_NAME}_web id -g www-data)" \
		--name ${STACK_NAME}_cli \
		--volumes-from ${STACK_NAME}_web \
		--network ${STACK_NAME}_cli_network \
		-e WORDPRESS_DB_HOST=${STACK_NAME}_db \
		-e WORDPRESS_DB_NAME=${DB_NAME} \
		-e WORDPRESS_DB_USER=${DB_USER} \
		-e WORDPRESS_DB_PASSWORD=${DB_PASSWORD} \
		-e WORDPRESS_TABLE_PREFIX=${DB_PREFIX} \
		-e HOME=/tmp \
		wordpress:cli-php${PHP_VERSION} $(cmd)

cli_config_create:
	- make --no-print-directory cli cmd="wp config create --dbhost=${STACK_NAME}_db --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PASSWORD} --dbprefix=${DB_PREFIX} --skip-check"

cli_install_db:
	- make --no-print-directory cli cmd="wp core install --url=${WP_SITEURL} --title=${TITLE} --admin_user=${ADMIN_USER} --admin_password=${ADMIN_PASS} --admin_email=${ADMIN_EMAIL}"

install:
	@if [ ! -f ${STACK_SRC}/wp-config.php ]; then \
		sudo cp ${STACK_SRC}/wp-config-docker.php ${STACK_SRC}/wp-config.php; \
		sudo chown $$USER:www-data ${STACK_SRC}/wp-config.php; \
		sudo chmod 644 ${STACK_SRC}/wp-config.php; \
	fi
	make --no-print-directory cli_install_db
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web rm -Rf /var/www/html/wp-content/plugins/akismet
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web rm -f  /var/www/html/wp-content/plugins/hello.php

smtp_install:
	make cli cmd="wp plugin install wp-mail-smtp --activate"

smtp_config:
	make cli cmd="wp config set WPMS_ON true --raw"
	make cli cmd="wp config set WPMS_MAIL_FROM \"${SMTP_FROM}\""
	make cli cmd="wp config set WPMS_MAIL_FROM_NAME \"${SMTP_FROM_NAME}\""
	make cli cmd="wp config set WPMS_MAILER \"smtp\""
	make cli cmd="wp config set WPMS_SMTP_HOST \"${SMTP_HOST}\""
	make cli cmd="wp config set WPMS_SMTP_PORT ${SMTP_PORT}"
	make cli cmd="wp config set WPMS_SSL \"${SMTP_SECURE}\""
	make cli cmd="wp config set WPMS_SMTP_AUTH true --raw"
	make cli cmd="wp config set WPMS_SMTP_USER \"${SMTP_USER}\""
	make cli cmd="wp config set WPMS_SMTP_PASS \"${SMTP_PASS}\""

smtp_db:
	make cli cmd="wp option update wp_mail_smtp '{ \
	\"mail\": { \
		\"from_email\": \"${SMTP_FROM}\", \
		\"from_name\": \"${SMTP_FROM_NAME}\", \
		\"mailer\": \"smtp\", \
		\"return_path\": true \
	}, \
	\"smtp\": { \
		\"host\": \"${SMTP_HOST}\", \
		\"port\": ${SMTP_PORT}, \
		\"encryption\": \"${SMTP_SECURE}\", \
		\"auth\": true, \
		\"user\": \"${SMTP_USER}\", \
		\"pass\": \"${SMTP_PASS}\" \
	} \
	}' --format=json"
smtp_test:
	- make cli cmd="wp eval 'wp_mail(\"${SMTP_TEST_EMAIL}\", \"SMTP Test\", \"This is a test email.\");'"
