FROM --platform=linux/amd64 debian:wheezy
MAINTAINER Hans-Peter Buniat <hans-peter.buniat@invia.de>

ENV DEBIAN_FRONTEND noninteractive

# update debian
COPY sources.list /etc/apt/
COPY dotdeb.gpg /tmp/

RUN apt-get update && \
    apt-get upgrade -y && \
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
    apt-get upgrade -y && \
    apt-get install --no-install-recommends --yes --force-yes \
        make \
        apache2 \
        ca-certificates \
        curl \
        mc \
        openssl \
        nano \
        libapache2-mod-php5 \
        filter \
        libphp5-embed \
        php5-apcu \
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
        php-pear \
        libssh2-php \
        supervisor \
        sudo \
        ssl-cert \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -rf /var/www && \
    mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/httpdocs /var/www/log && \
    chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www && \
    chmod 777 /var/www/log

# Apache + PHP requires preforking Apache for best results
RUN a2enmod rewrite && a2enmod php5
RUN a2enmod rewrite && a2enmod php5

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Update the default apache site with the config we created.
COPY apache2/apache2.conf /etc/apache2/sites-enabled/000-default
COPY apache2/ports.conf /etc/apache2/ports.conf

EXPOSE 80

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]