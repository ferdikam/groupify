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
    supervisor \
    icu-dev \
    libzip-dev

# Configuration Git AVANT la copie des fichiers
RUN git config --global --add safe.directory /var/www/html

# Installation des extensions PHP avec configuration explicite
RUN docker-php-ext-configure intl && \
    docker-php-ext-configure zip && \
    docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        opcache \
        intl \
        zip

# Vérification que les extensions sont bien installées
RUN echo "🔍 Vérification des extensions PHP..." && \
    php -m | grep intl && \
    php -m | grep zip && \
    php -m | grep pdo_mysql && \
    echo "✅ Extensions PHP OK" || (echo "❌ Extensions manquantes" && php -m && exit 1)

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration PHP optimisée pour 1Go RAM
RUN echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini && \
    echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini && \
    echo "opcache.memory_consumption=64" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini && \
    echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini && \
    echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini

# Création du répertoire de travail
WORKDIR /var/www/html

# Configuration des permissions
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

# Copie des fichiers de l'application
COPY --chown=www:www . /var/www/html

# Installation des dépendances PHP avec gestion d'erreurs robuste
RUN if [ -f composer.json ]; then \
        echo "📦 Diagnostic Composer..." && \
        composer diagnose && \
        echo "📋 Extensions PHP disponibles:" && \
        php -m | grep -E "(intl|zip|pdo_mysql)" && \
        echo "🔧 Installation des dépendances..." && \
        composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs; \
    else \
        echo "⚠️ Aucun composer.json trouvé"; \
    fi

# Configuration des permissions Laravel
RUN chown -R www:www /var/www/html && \
    chmod -R 755 /var/www/html && \
    mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage && \
    chmod -R 775 /var/www/html/bootstrap/cache

# Créer les répertoires pour les configurations
RUN mkdir -p /var/log/supervisor /var/run/supervisor /etc/supervisor/conf.d && \
    touch /var/log/supervisor/supervisord.log && \
    chown -R www:www /var/log/supervisor /var/run/supervisor

# Copier le script wait-for-mysql
COPY scripts/wait-for-mysql.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-mysql.sh

# Créer un script d'entrée personnalisé
RUN cat > /usr/local/bin/docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Démarrage du conteneur Laravel..."

# Vérifier les extensions PHP
echo "🔍 Extensions PHP actives:"
php -m | grep -E "(intl|zip|pdo_mysql)" || echo "⚠️ Certaines extensions manquent"

# Attendre que MySQL soit prêt si les variables DB sont définies
if [ -n "$DB_HOST" ] && [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ]; then
    echo "⏳ Attente de MySQL..."
    /usr/local/bin/wait-for-mysql.sh "$DB_HOST" || echo "⚠️ MySQL timeout - continuons"
fi

# Finaliser l'installation Composer si nécessaire
if [ -f composer.json ] && [ ! -f /tmp/composer-scripts-done ]; then
    echo "📦 Finalisation Composer..."
    composer run-script post-autoload-dump --no-interaction || echo "⚠️ Scripts Composer échoués"
    touch /tmp/composer-scripts-done
fi

# Démarrer supervisord
echo "✅ Démarrage des services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

CMD ["/usr/local/bin/docker-entrypoint.sh"]
