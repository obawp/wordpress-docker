include ./.env
export

build:
	- docker build -t ${REPO} ./docker-files/wordpress/

build_verbose:
	- docker build --progress=plain -t ${REPO} ./docker-files/wordpress/

build_no_cache:
	- docker build --no-cache --pull -t ${REPO} ./docker-files/wordpress/

login:
	- echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin

push:
	- docker push ${REPO}

pull:
	- docker pull ${REPO}

run:
	- docker run -d --name ${STACK}_aux ${REPO}

mkdir:
	- sudo mkdir -p ./vol/mysql/data
	- sudo mkdir -p ./vol/wordpress/html
	- sudo chown $$USER:www-data ./vol/mysql/data
	- sudo chown $$USER:www-data ./vol/wordpress/html
	- docker cp ${STACK}_aux:/var/www/html ./vol/wordpress/

rmdir:
	- sudo rm -Rf ./vol/wordpress/html
	- sudo rm -Rf ./vol/mysql/data

up:
	- docker compose -p ${STACK} -f "./docker-compose.yml" up -d

perm:
	-  docker exec -u 0 ${STACK}_web chown www-data:www-data -R /var/www/html/
	-  docker exec -u 0 ${STACK}_web find /var/www/html -type d -exec chmod 0750 {} \;
	-  docker exec -u 0 ${STACK}_web find /var/www/html -type f -exec chmod 0640 {} \;

perm_dev:
	-  sudo chown $$USER:www-data -R ./vol/wordpress/html
	-  sudo find ./vol/wordpress/html -type d -exec chmod 0770 {} \;
	-  sudo find ./vol/wordpress/html -type f -exec chmod 0660 {} \;

perm_db:
	-  docker exec -u 0 ${STACK}_db chown -R mysql:mysql /var/lib/mysql

install:
	- docker exec -u www-data -w /var/www/html/ ${STACK}_web wp core install --url=${DOMAIN} --title=${TITLE} --admin_user=${ADMIN_USER} --admin_password=${ADMIN_PASS} --admin_email=${ADMIN_EMAIL}
	- docker exec -u 0 -w /var/www/html/ ${STACK}_web rm -Rf /var/www/html/wp-content/plugins/akismet
	- docker exec -u 0 -w /var/www/html/ ${STACK}_web rm -f  /var/www/html/wp-content/plugins/hello.php

rm:
	- docker rm ${STACK}_aux -f
	- docker compose -p ${STACK} -f "./docker-compose.yml" down
