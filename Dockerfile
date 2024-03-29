FROM php:7.4-fpm

ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_ini /usr/local/etc/php/php.ini
ENV php_fpm_conf /usr/local/etc/php-fpm.conf

RUN apt-get -y update && \
    apt-get -y install libmcrypt-dev libpng-dev libzip-dev ffmpeg && \
    pecl install xdebug && \
    printf "\n" | pecl install mcrypt && \
    cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini && \
    docker-php-ext-install pdo_mysql mysqli bcmath gd zip && \
    docker-php-ext-enable pdo_mysql mysqli bcmath mcrypt gd zip && \
    sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 10/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/listen = 127.0.0.1:9000/listen = [::]:9000/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        ${fpm_conf} && \
    sed -i \
        -e "s/;session.save_path = \"\/tmp\"/session.save_path = \"\/tmp\"/g" \
        -e "s/;curl.cainfo =/curl.cainfo = \"\/usr\/local\/etc\/php\/cacert.pem\"/g" \
        -e "s/;openssl.cafile=/openssl.cafile = \"\/usr\/local\/etc\/php\/cacert.pem\"/g" \
        ${php_ini} && \
    sed -i \
        -e "s/;pid = run\/php-fpm.pid/pid = run\/php-fpm.pid/g" \
        ${php_fpm_conf} && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

COPY script/start.sh /usr/local/bin/start.sh
COPY pem/cacert.pem /usr/local/etc/php/cacert.pem

RUN chmod 755 /usr/local/bin/start.sh

EXPOSE 9000

CMD ["/usr/local/bin/start.sh"]
