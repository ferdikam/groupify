# Dockerfile - Version simplifiée et robuste
FROM php:8.4-fpm-alpine

# Installation de tout en une fois pour éviter les problèmes
RUN apk add --no-cache \
    git curl libpng-dev oniguruma-dev libxml2-dev zip unzip \
    mysql-client nginx supervisor icu-dev libzip-dev && \
    git config --global --add safe.directory /var/www/html && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure zip && \
    docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd opcache intl zip && \
    addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www && \
    mkdir -p /var/log/supervisor /var/run/supervisor /etc/supervisor/conf.d

# Copier Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration PHP simple
RUN echo "memory_limit=256M" > /usr/local/etc/php/conf.d/custom.ini && \
    echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www/html

# Copier les fichiers
COPY --chown=www:www . /var/www/html

# Installation Composer simplifiée
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs || \
    (echo "⚠️ Première tentative échouée, essai sans lock file..." && \
     rm -f composer.lock && \
     composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs)

# Permissions finales
RUN mkdir -p storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache && \
    chown -R www:www /var/www/html

# Script wait-for-mysql
COPY scripts/wait-for-mysql.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-mysql.sh

# Script d'entrée simple
RUN cat > /usr/local/bin/docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e
echo "🚀 Démarrage Laravel..."

# Attendre MySQL si configuré
if [ -n "$DB_HOST" ]; then
    echo "⏳ Attente MySQL..."
    /usr/local/bin/wait-for-mysql.sh "$DB_HOST" || echo "⚠️ Timeout MySQL"
fi

echo "✅ Démarrage supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

CMD ["/usr/local/bin/docker-entrypoint.sh"]
