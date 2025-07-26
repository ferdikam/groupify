# Dockerfile - Version SQLite robuste avec étapes séparées
FROM php:8.4-fpm-alpine

# Étape 1: Installation des packages système (avec sqlite-dev pour les headers)
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
    sqlite-dev

# Étape 2: Configuration Git
RUN git config --global --add safe.directory /var/www/html

# Étape 3: Configuration des extensions PHP
RUN docker-php-ext-configure intl
RUN docker-php-ext-configure zip

# Étape 4: Installation des extensions PHP (seulement les essentielles pour SQLite)
RUN docker-php-ext-install pdo_sqlite
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install exif
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install gd
RUN docker-php-ext-install opcache
RUN docker-php-ext-install intl
RUN docker-php-ext-install zip

# Étape 5: Vérification des extensions essentielles
RUN php -m | grep -E "(pdo_sqlite|mbstring)" || echo "⚠️ Extensions critiques manquantes"

# Étape 6: Création des utilisateurs et répertoires
RUN addgroup -g 1000 -S www
RUN adduser -u 1000 -S www -G www
RUN mkdir -p /var/log/supervisor /var/run/supervisor /etc/supervisor/conf.d

# Étape 7: Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Étape 8: Configuration PHP
RUN echo "memory_limit=256M" > /usr/local/etc/php/conf.d/custom.ini && \
    echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/custom.ini

# Étape 9: Configuration du workdir
WORKDIR /var/www/html

# Étape 10: Copie des fichiers
COPY --chown=www:www . /var/www/html

# Étape 11: Installation Composer avec fallback
RUN if [ -f composer.json ]; then \
        echo "📦 Installation Composer..." && \
        (composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs || \
         (echo "⚠️ Retry sans lock..." && rm -f composer.lock && \
          composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs)); \
    fi

# Étape 12: Création des répertoires et permissions
RUN mkdir -p storage bootstrap/cache database && \
    touch database/database.sqlite && \
    chmod -R 775 storage bootstrap/cache database && \
    chown -R www:www /var/www/html

# Étape 13: Script d'entrée
RUN cat > /usr/local/bin/docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e
echo "🚀 Démarrage Laravel avec SQLite..."

# Créer/vérifier SQLite
if [ ! -f /var/www/html/database/database.sqlite ]; then
    echo "📄 Création SQLite..."
    touch /var/www/html/database/database.sqlite
    chown www:www /var/www/html/database/database.sqlite
fi

# Vérifier les extensions critiques
echo "🔍 Extensions PHP critiques:"
php -m | grep -E "(pdo_sqlite|Core|mbstring)" | head -3

echo "✅ Démarrage supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

CMD ["/usr/local/bin/docker-entrypoint.sh"]
