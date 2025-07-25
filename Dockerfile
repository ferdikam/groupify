# Dockerfile - Version SQLite (ultra-léger)
FROM php:8.4-fpm-alpine

# Installation des dépendances - plus besoin de mysql-client !
RUN apk add --no-cache \
    git curl libpng-dev oniguruma-dev libxml2-dev zip unzip \
    nginx supervisor icu-dev libzip-dev sqlite && \
    git config --global --add safe.directory /var/www/html && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure zip && \
    docker-php-ext-install pdo_sqlite pdo_mysql mbstring exif pcntl bcmath gd opcache intl zip && \
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

# Permissions et création du fichier SQLite
RUN mkdir -p storage bootstrap/cache database && \
    touch database/database.sqlite && \
    chmod -R 775 storage bootstrap/cache database && \
    chown -R www:www /var/www/html

# Script d'entrée ultra-simple
RUN cat > /usr/local/bin/docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e
echo "🚀 Démarrage Laravel avec SQLite..."

# Vérifier/créer la base SQLite
if [ ! -f /var/www/html/database/database.sqlite ]; then
    echo "📄 Création du fichier SQLite..."
    touch /var/www/html/database/database.sqlite
    chown www:www /var/www/html/database/database.sqlite
fi

echo "✅ Démarrage supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

CMD ["/usr/local/bin/docker-entrypoint.sh"]
