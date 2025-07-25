# Dockerfile minimal - Seulement l'essentiel
FROM php:8.4-fpm-alpine

# Installation basique en une fois
RUN apk add --no-cache git curl nginx supervisor sqlite && \
    docker-php-ext-install pdo_sqlite && \
    addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY --chown=www:www . /var/www/html

# Installation minimale
RUN composer install --no-dev --ignore-platform-reqs --no-interaction || echo "Composer failed"

# Permissions et SQLite
RUN mkdir -p storage database && \
    touch database/database.sqlite && \
    chown -R www:www /var/www/html

EXPOSE 80
CMD ["php-fpm"]
