#!/bin/bash

# Disable Strict Host checking for non interactive git clones

if [ ! -z "$SSH_KEY" ]; then
 echo $SSH_KEY > /root/.ssh/id_rsa.base64
 base64 -d /root/.ssh/id_rsa.base64 > /root/.ssh/id_rsa
 chmod 600 /root/.ssh/id_rsa
fi

PhpFpmFile='/usr/local/etc/php-fpm.d/www.conf'
PhpIniFile='/usr/local/etc/php/php.ini'

#if [ ! -z "$DOMAIN" ]; then
# sed -i "s#server_name _;#server_name ${DOMAIN};#g" /etc/nginx/sites-available/default.conf
# sed -i "s#server_name _;#server_name ${DOMAIN};#g" /etc/nginx/sites-available/default-ssl.conf
#fi

# Prevent config files from being filled to infinity by force of stop and restart the container
#lastlinephpconf="$(grep "." /usr/local/etc/php-fpm.conf | tail -1)"
#if [[ $lastlinephpconf == *"php_flag[display_errors]"* ]]; then
# sed -i '$ d' /usr/local/etc/php-fpm.conf
#fi

# Display PHP error's or not
if [ "$ERRORS" != "1" ] ; then
  sed -i "s/;php_flag\[display_errors\] = off/php_flag[display_errors] = off/g" $PhpFpmFile
else
 sed -i "s/;php_flag\[display_errors\] = off/php_flag[display_errors] = on/g" $PhpFpmFile
 sed -i "s/display_errors = Off/display_errors = On/g" $PhpIniFile
 if [ ! -z "$ERROR_REPORTING" ]; then sed -i "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = $ERROR_REPORTING/g" $PhpIniFile; fi
 sed -i "s#;error_log = syslog#error_log = /usr/local/var/log/php_error.log#g" $PhpIniFile
fi

# Display Version Details or not
if [[ "$HIDE_NGINX_HEADERS" != "0" ]] ; then
 sed -i "s/expose_php = On/expose_php = Off/g" $PhpIniFile
fi

# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
 sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" $PhpIniFile
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
 sed -i "s/post_max_size = 8M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" $PhpIniFile
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
 sed -i "s/upload_max_filesize = 2M/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}M/g" $PhpIniFile
fi

# Increase the max_execution_time
if [ ! -z "$PHP_MAX_EXECUTION_TIME" ]; then
 sed -i "s/max_execution_time = 30/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/g" $PhpIniFile
fi

# Enable xdebug
XdebugFile='/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini'
if [ "$ENABLE_XDEBUG" == "1" ] ; then
  echo "Enabling xdebug"
    # See if file contains xdebug text.
    if [ -f $XdebugFile ]; then
        echo "Xdebug already enabled... skipping"
    else
      docker-php-ext-enable xdebug
      # echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20180731/xdebug.so" >> $XdebugFile
      echo "xdebug.remote_enable=1"  >> $XdebugFile
      echo "xdebug.remote_log=/tmp/xdebug.log"  >> $XdebugFile
      echo "xdebug.remote_autostart=1"  >> $XdebugFile # I use the xdebug chrome extension instead of using autostart
      # echo "xdebug.remote_host=localhost "  >> $XdebugFile
      # echo "xdebug.remote_port=9000 "  >> $XdebugFile
      # NOTE: xdebug.remote_host is not needed here if you set an environment variable in docker-compose like so `- XDEBUG_CONFIG=remote_host=192.168.111.27`.
      #       you also need to set an env var `- PHP_IDE_CONFIG=serverName=docker`
    fi
else
  if [ -f $XdebugFile ]; then
      rm -rf $XdebugFile
  fi
  
fi

if [ ! -z "$PUID" ]; then
  if [ -z "$PGID" ]; then
    PGID=${PUID}
  fi
  #deluser nginx
  addgroup -g ${PGID} nginx
  #adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u ${PUID} nginx
else
  if [ -z "$SKIP_CHOWN" ]; then
    chown -Rf www-data:www-data /var/www/html
  fi
fi

# rm -rf /var/run/php/php7.2-fpm.pid
# Start supervisord and services
exec php-fpm