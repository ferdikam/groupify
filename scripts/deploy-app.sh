#!/bin/bash
set -e

PROJECT_PATH=$1
APP_KEY=$2
DOMAIN_NAME=$3
SSL_EMAIL=$4

echo "🚀 Déploiement de l'application Laravel avec SQLite..."

cd "$PROJECT_PATH"

# Création du fichier .env pour SQLite
cat > .env << EOF
APP_NAME="Laravel Filament"
APP_ENV=production
APP_KEY=$APP_KEY
APP_DEBUG=false
APP_URL=https://$DOMAIN_NAME

# Configuration SQLite
DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite

# Variables pour Docker/SSL
DOMAIN_NAME=$DOMAIN_NAME
SSL_EMAIL=$SSL_EMAIL

# Cache et sessions
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync

# Logs
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error
EOF

# Création des répertoires nécessaires
echo "📁 Création des répertoires..."
mkdir -p storage/{app/public,framework/{cache,sessions,views},logs}
mkdir -p bootstrap/cache
mkdir -p database

# Création de la base SQLite
touch database/database.sqlite
chmod 664 database/database.sqlite

# Arrêt propre des conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker-compose down --remove-orphans || true
docker system prune -f || true

# Construction des images
echo "🔨 Construction des images Docker..."
docker-compose build --no-cache

# Démarrage initial (sans SSL)
echo "🚀 Démarrage des conteneurs..."
docker-compose up -d app

# Attente que le conteneur app soit prêt
echo "⏳ Attente du démarrage de l'application..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if docker-compose exec -T app php -v > /dev/null 2>&1; then
        echo "✅ Conteneur app prêt"
        break
    fi
    echo "⏳ Attente... ($counter/$timeout)"
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -eq $timeout ]; then
    echo "❌ Timeout - vérification des logs..."
    docker-compose logs app
    exit 1
fi

# Démarrage de Nginx
echo "🌐 Démarrage de Nginx..."
docker-compose up -d nginx

# Attente que Nginx soit prêt
sleep 10

# Configuration Laravel
echo "🔧 Configuration de Laravel..."

# Installation des dépendances (si pas fait dans le build)
docker-compose exec -T app composer install --no-dev --optimize-autoloader --no-interaction || echo "⚠️ Composer déjà installé"

# Génération de la clé si nécessaire
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:PLACEHOLDER" ]; then
    echo "🔑 Génération de la clé d'application..."
    docker-compose exec -T app php artisan key:generate --force
fi

# Migration de la base de données
echo "📊 Migration de la base de données..."
docker-compose exec -T app php artisan migrate --force

# Cache des configurations
echo "🗂️ Mise en cache des configurations..."
docker-compose exec -T app php artisan config:cache
docker-compose exec -T app php artisan route:cache
docker-compose exec -T app php artisan view:cache

# Création du lien de stockage
echo "🔗 Création du lien de stockage..."
docker-compose exec -T app php artisan storage:link || echo "⚠️ Lien déjà existant"

# Permissions finales
echo "🔐 Configuration des permissions..."
docker-compose exec -T app chown -R www:www /var/www/html/storage
docker-compose exec -T app chown -R www:www /var/www/html/bootstrap/cache
docker-compose exec -T app chown -R www:www /var/www/html/database
docker-compose exec -T app chmod -R 775 /var/www/html/storage
docker-compose exec -T app chmod -R 775 /var/www/html/bootstrap/cache
docker-compose exec -T app chmod 664 /var/www/html/database/database.sqlite

# Test de l'application
echo "🧪 Test de l'application..."
sleep 5
if curl -f -s http://localhost > /dev/null; then
    echo "✅ Application accessible sur HTTP"
else
    echo "⚠️ Application pas encore accessible - vérification des logs..."
    docker-compose logs --tail=20 app
    docker-compose logs --tail=20 nginx
fi

# Affichage du statut
echo "📊 Statut des conteneurs:"
docker-compose ps

echo "✅ Déploiement terminé"
echo "🌐 Application accessible sur: http://$DOMAIN_NAME"
echo "🔒 Configurez SSL ensuite avec le script setup-ssl.sh"
