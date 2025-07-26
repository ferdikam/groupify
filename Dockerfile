# Dockerfile optimisé pour Laravel avec SQLite
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
    nginx \
    supervisor \
    icu-dev \
    libzip-dev \
    sqlite \
    sqlite-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure zip

# Installation des extensions PHP
RUN docker-php-ext-install \
    pdo_sqlite \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    opcache \
    intl \
    zip

# Configuration PHP optimisée
RUN echo "memory_limit=256M" > /usr/local/etc/php/conf.d/custom.ini && \
    echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "opcache.memory_consumption=64" >> /usr/local/etc/php/conf.d/custom.ini

# Création des utilisateurs et répertoires
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www && \
    mkdir -p /var/log/supervisor /var/run/supervisor /etc/supervisor/conf.d

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration du workdir
WORKDIR /var/www/html

# Copie des fichiers avec bonnes permissions
COPY --chown=www:www . /var/www/html

# Installation des dépendances Composer
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs || \
        (rm -f composer.lock && composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs); \
    fi

# Création des répertoires et permissions
RUN mkdir -p storage/{app/public,framework/{cache,sessions,views},logs} bootstrap/cache database && \
    touch database/database.sqlite && \
    chmod -R 775 storage bootstrap/cache database && \
    chown -R www:www /var/www/html

# Script d'entrée robuste
RUN cat > /usr/local/bin/docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting Laravel application..."

# Vérifier SQLite
if [ ! -f /var/www/html/database/database.sqlite ]; then
    echo "📄 Creating SQLite database..."
    touch /var/www/html/database/database.sqlite
    chown www:www /var/www/html/database/database.sqlite
    chmod 664 /var/www/html/database/database.sqlite
fi

# Vérifier les répertoires
mkdir -p storage/{app/public,framework/{cache,sessions,views},logs} bootstrap/cache
chown -R www:www storage bootstrap/cache database

# Vérifier les extensions critiques
echo "🔍 Checking critical PHP extensions:"
php -m | grep -E "(pdo_sqlite|mbstring|Core)" | head -3

# Test de base de la configuration
echo "🧪 Testing basic PHP functionality..."
php -r "echo 'PHP OK: ' . phpversion() . PHP_EOL;"

echo "✅ Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000

CMD ["/usr/local/bin/docker-entrypoint.sh"]
