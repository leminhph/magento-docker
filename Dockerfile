FROM php:7.1-apache

ENV DEBIAN_FRONTEND=noninteractive

COPY config/php.ini /usr/local/etc/php/conf.d

# Enable Apache mod_rewrite
RUN a2enmod rewrite && service apache2 restart

# Dependencies
RUN apt update && apt install -y \
        # im a peasant
        nano \
        # git
        git \
        # zip
        zip unzip \
        # gd, iconv, mcrypt
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        # intl
        libicu-dev \
        # xsl
        libxslt1-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) bcmath gd iconv intl mcrypt opcache pdo_mysql soap xsl zip

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Bypass SSH authentication prompt
RUN mkdir /root/.ssh
COPY id_rsa /root/.ssh
RUN chmod 400 /root/.ssh/id_rsa && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

# Get the Magento software
COPY auth.json /root/.composer
RUN composer create-project --repository-url=https://repo.magento.com/ magento/project-enterprise-edition .

# Install sample data
COPY auth.json /var/www/html
RUN ./bin/magento sampledata:deploy
