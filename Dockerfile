# Dockerfile
FROM php:8.4-fpm-alpine

# Installation des dépendances système minimales
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    mysql-client \
    nginx \
    supervisor

# Installation des extensions PHP nécessaires
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    opcache

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration PHP optimisée pour 1Go RAM
RUN echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini \
    && echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini \
    && echo "opcache.memory_consumption=64" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini \
    && echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini \
    && echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini \
    && echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini

# Création du répertoire de travail
WORKDIR /var/www/html

# Configuration des permissions
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

# Copie des fichiers de l'application
COPY --chown=www:www . /var/www/html

# Installation des dépendances PHP (seulement si composer.json existe)
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

# Configuration des permissions Laravel
RUN chown -R www:www /var/www/html \
    && chmod -R 755 /var/www/html \
    && mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Créer les répertoires pour les configurations
RUN mkdir -p /etc/supervisor/conf.d /etc/nginx/conf.d

EXPOSE 80

# Script de démarrage qui sera overridé par les volumes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

