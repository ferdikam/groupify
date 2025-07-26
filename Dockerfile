# Dockerfile ultra-simplifié pour Laravel avec SQLite
FROM php:8.3-fpm-alpine

# Installation des packages système
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    supervisor \
    icu-dev \
    libzip-dev \
    sqlite \
    sqlite-dev

# Configuration et installation des extensions PHP
RUN docker-php-ext-configure intl && \
    docker-php-ext-configure zip && \
    docker-php-ext-install \
        pdo_sqlite \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        opcache \
        intl \
        zip

# Configuration PHP
RUN echo "memory_limit=256M" > /usr/local/etc/php/conf.d/custom.ini && \
    echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/custom.ini

# Création utilisateur www
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

# Installation Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration workdir
WORKDIR /var/www/html

# Copie des fichiers
COPY --chown=www:www . /var/www/html

# Installation dépendances Composer
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs || \
        (rm -f composer.lock && composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs); \
    fi

# Création répertoires Laravel
RUN mkdir -p storage/{app/public,framework/{cache,sessions,views},logs} bootstrap/cache database && \
    touch database/database.sqlite && \
    chmod -R 775 storage bootstrap/cache database && \
    chown -R www:www /var/www/html

# Créer répertoires supervisor
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d

EXPOSE 9000

# Commande simple : juste php-fpm
CMD ["php-fpm"]
