FROM php:fpm

ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_ini /usr/local/etc/php/php.ini

RUN apt-get -y update && \
    pecl install xdebug && \
    cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-enable pdo_mysql && \
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
        ${php_ini} && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

COPY script/start.sh /usr/local/bin/start.sh

RUN chmod 755 /usr/local/bin/start.sh

EXPOSE 9000

CMD ["/usr/local/bin/start.sh"]
