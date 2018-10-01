debian 9.5 php7.2

docker-compose file example:


version: '3'

services:
  php-fpm:
    image: debian-php-fpm:latest
    container_name: wp-fpm
    volumes:
      - ./wordpress:/var/www/html
    links:
      - mariadb:db
    depends_on:
      - mariadb
    environment:
      - ERRORS=1
      - ENABLE_XDEBUG=1
      - XDEBUG_CONFIG=remote_host=192.168.1.3 remote_port=9001
      - XDEBUG_REMOTE_HOST=192.168.1.3
      - XDEBUG_REMOTE_PORT=9001
  web:
    image: debian-nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./wordpress:/var/www/html
    container_name: wp-web
    links:
      - php-fpm:fpm
    depends_on:
      - php-fpm