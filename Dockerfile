FROM php:8.4-fpm-bullseye AS build

COPY --from=composer:2.8.6 /usr/bin/composer /usr/bin/composer
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

COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN set -eux; docker-php-ext-install \
        intl \
        pdo \
        pdo_pgsql \
        pgsql \
        shmop \
        bcmath

RUN docker-php-ext-enable opcache

RUN docker-php-ext-enable bcmath

COPY config/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

FROM build AS prod

ENV APP_ENV=prod
ENV APP_DEBUG=0

RUN --mount=type=ssh composer install --no-dev

RUN composer dump-env prod --empty

FROM build AS dev
ENV APP_ENV=dev
ENV APP_DEBUG=1
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN pecl install xdebug && docker-php-ext-enable xdebug
COPY config/php/dev/xdebug.ini "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
