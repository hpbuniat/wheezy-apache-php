FROM --platform=linux/amd64 debian:wheezy
MAINTAINER Hans-Peter Buniat <hans-peter.buniat@invia.de>

ENV DEBIAN_FRONTEND noninteractive

# update debian
COPY sources.list /etc/apt/
COPY dotdeb.gpg /tmp/

RUN apt-get update && \
    apt-get upgrade --yes --force-yes && \
    apt-get install --no-install-recommends --yes --force-yes \
        apt-transport-https  \
        ca-certificates \
        debian-keyring  \
        debian-archive-keyring \
        git \
    && apt-key update

RUN echo "Acquire::Check-Valid-Until false;" | tee -a /etc/apt/apt.conf.d/10-nocheckvalid && \
    apt-key add /tmp/dotdeb.gpg && \
    apt-get update && \
    apt-get upgrade --yes --force-yes && \
    apt-get install --no-install-recommends --yes --force-yes \
        make \
        apache2 \
        ca-certificates \
        curl \
        mc \
        openssl \
        nano \
        filter \
        libapache2-mod-php5 \
        libphp5-embed \
        php5-cli \
        php5-common \
        php5-curl \
        php5-dev \
        php5-gd \
        php5-imagick \
        php5-intl \
        php5-ldap \
        php5-mcrypt \
        php5-memcache \
        php5-mongo \
        php5-mysqlnd \
        php5-sqlite \
        php5-xdebug \
        php-pear \
        libssh2-php \
        supervisor \
        sudo \
        locales \
        ssl-cert \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo en_US.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo en_GB.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo en_IE.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo de_DE.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo fr_FR.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo it_IT.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo es_ES.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo nl_NL.UTF-8 UTF-8 >> /etc/locale.gen && \
    echo pl_PL.UTF-8 UTF-8 >> /etc/locale.gen && \
    locale-gen && \
    dpkg-reconfigure locales

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN rm -rf /var/www && \
    mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/httpdocs /var/www/log && \
    chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www && \
    chmod 777 /var/www/log

# Apache + PHP requires preforking Apache for best results
RUN a2enmod rewrite && \
    a2enmod php5 && \
    a2enmod authnz_ldap && \
    a2enmod expires && \
    a2enmod headers && \
    a2enmod ssl && \
    a2enmod status

RUN a2ensite default-ssl

# install xdebug and use our own xdebug configuration
RUN pecl channel-update pecl.php.net && \
    pecl install xdebug-2.4.1
COPY php/xdebug.ini /etc/php5/apache2/conf.d/20-xdebug.ini
RUN sed -i -e '1izend_extension=\'`find / -name "xdebug.so"` /etc/php5/apache2/conf.d/20-xdebug.ini

# edit php.ini
RUN sed -i 's/^;date\.timezone.*$/date.timezone = UTC/' /etc/php5/apache2/php.ini
RUN sed -i 's/^;date\.timezone.*$/date.timezone = UTC/' /etc/php5/cli/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Update the default apache site with the config we created.
COPY apache2/apache2.conf /etc/apache2/sites-enabled/000-default
COPY apache2/ports.conf /etc/apache2/ports.conf
COPY apache2/docker.conf /etc/apache2/conf.d/docker.conf
COPY apache2/default-ssl.conf /etc/apache2/sites-available/default-ssl


EXPOSE 80 443

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]