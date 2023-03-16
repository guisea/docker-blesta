FROM docker.io/cybercinch/php7-alpine 
ARG PHP_VERSION=7.2
ARG TARGETARCH
ENV BLESTA_VERSION=5.6.1

# Install Supervisord and PHP Deps
RUN apk update \
    && apk add --no-cache supervisor \
                          php7-gmp \
                          php7-imap \
                          php7-mailparse \
                          php7-simplexml \
                          php7-soap \
                          tar

# Download ioncube loaders
RUN if [ "arm64" = "$TARGETARCH" ] ; then \
    curl -sSL -o /tmp/ioncube.zip http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.zip ; \
    else \
    curl -sSL -o /tmp/ioncube.zip http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip ; \
    fi

# Install ioncube into PHP
RUN unzip /tmp/ioncube.zip -d /usr/lib/php7/modules \
    && rm -Rf /tmp/ioncube.zip \
    && echo "zend_extension=ioncube/ioncube_loader_lin_${PHP_VERSION}.so" > /etc/php7/conf.d/00_docker-php-ext-ioncube.ini \
    && ln -sf /proc/self/fd/1 /var/log/apache2/access.log \
    && ln -sf /proc/self/fd/1 /var/log/apache2/error.log

ADD index.php /var/www/app/index.php

ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD conf/etc/apache2/httpd.conf /etc/apache2/httpd.conf
# ADD logformat.conf /etc/apache2/conf.d/logformat.conf
#ADD remoteip.conf /etc/apache2/conf.d/remoteip.conf
ADD entrypoint.sh /entrypoint.sh

RUN   mkdir -p /opt/scripts \
      && mkdir -p /var/www/app \
      && curl -o blesta.zip -sSL https://account.blesta.com/client/plugin/download_manager/client_main/download/223/blesta-5.6.1.zip \
      && unzip blesta.zip -d /var/www/app \
      && rm blesta.zip \
      && chown -R apache:apache /var/www/app/blesta/cache /var/www/app/uploads /var/www/app/blesta/config \
      && mv /var/www/app /var/www/docker-backup-app \
      && mkdir -p /var/www/app/uploads/system \
      && sed -ri -e 's!/var/www/html!/var/www/app/blesta!g' /etc/apache2/httpd.conf \
      && mkdir -p /etc/cron.d/ \
      # Setup crontab
      && touch /var/spool/cron/crontabs/apache \  
      && echo '*/5 * * * * /usr/bin/php -q /var/www/app/blesta/index.php cron > /dev/null 2>&1' > /var/spool/cron/crontabs/apache \
      && echo '0 9 * * 3  [ `date +\%d` -le 7 ] && /opt/scripts/update-geolite.sh' >> /var/spool/cron/crontabs/apache

ADD scripts/update-geolite.sh /opt/scripts/update-geolite.sh
VOLUME /var/www/app
WORKDIR /var/www/app
EXPOSE 80

HEALTHCHECK CMD curl --silent --fail localhost:80 || exit 1
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]