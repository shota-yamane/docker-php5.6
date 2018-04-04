FROM php:5.6-apache

ENV ORACLE_HOME /opt/oracle/instantclient_11_2
ENV PHP_INI /usr/local/etc/php/php.ini

WORKDIR /tmp
RUN apt-get update -y && apt-get upgrade -y \
   && apt-get install -y \
        wget \
        unzip \
        vim \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libaio-dev \
        openssl libssl-dev \
        libxml2-dev

# Install Oracle Instantclient
COPY instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/
COPY instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/
COPY instantclient-sqlplus-linux.x64-11.2.0.4.0.zip /tmp/

RUN mkdir /opt/oracle \
    && cd /opt/oracle \
    && unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
    && unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
    && unzip /tmp/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
    && ln -s $ORACLE_HOME/libclntsh.so.11.1 $ORACLE_HOME/libclntsh.so \
    && ln -s $ORACLE_HOME/libclntshcore.so.11.1 $ORACLE_HOME/libclntshcore.so \
    && ln -s $ORACLE_HOME/libocci.so.11.1 $ORACLE_HOME/libocci.so \
    && rm -rf /tmp/*.zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && echo "instantclient,/opt/oracle/instantclient_11_2" | pecl install oci8-2.0.12 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,$ORACLE_HOME,11.2 \
    && pecl install redis \
    && docker-php-ext-install \
            iconv \
            mbstring \
            mcrypt \
            gd \
            mysqli \
            pdo_mysql \
            pdo_oci \
            soap \
            sockets \
            zip \
            ftp \
            xml \
            tokenizer \
    && docker-php-ext-enable \
            oci8 \
            redis

# set your project
WORKDIR /tmp
RUN mkdir -p $ORACLE_HOME/network/admin \
    && touch $PHP_INI \
    && echo 'date.timezone = Asia/Tokyo' >> $PHP_INI \
    && echo ' <?php phpinfo();' > /var/www/html/index.php

RUN wget https://phar.phpunit.de/phpunit-old.phar \
    && chmod +x phpunit-old.phar \
    && mv phpunit-old.phar /usr/local/bin/phpunit

RUN ln -s /path/to/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora

# enable rewrite
RUN a2enmod rewrite

# Define default command.
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]