FROM php:8.4-fpm-bullseye AS build

COPY --from=composer:2.3.3 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN set -eux; apt-get update && apt-get install -y \
        nginx \
        unzip \
        git \
        make \
        libicu-dev \
        libpq-dev \
        librdkafka-dev

RUN mkdir -p -m 0700 ~/.ssh && touch ~/.ssh/known_hosts && ssh-keyscan -T 60 github.com >> ~/.ssh/known_hosts

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN set -eux; docker-php-ext-install \
        intl \
        pdo \
        pdo_pgsql \
        pgsql \
        shmop

RUN docker-php-ext-enable opcache

#WORKDIR /app
#COPY . .