# scripts/deploy-app.sh
#!/bin/bash
set -e

PROJECT_PATH=$1
APP_KEY=$2
DB_DATABASE=$3
DB_USERNAME=$4
DB_PASSWORD=$5
DOMAIN_NAME=$6
SSL_EMAIL=$7

echo "🚀 Déploiement de l'application..."

cd "$PROJECT_PATH"

# Création du fichier .env
cat > .env << EOF
APP_NAME="Laravel Filament"
APP_ENV=production
APP_KEY=$APP_KEY
APP_DEBUG=false
APP_URL=https://$DOMAIN_NAME

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=$DB_DATABASE
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD

DOMAIN_NAME=$DOMAIN_NAME
SSL_EMAIL=$SSL_EMAIL

CACHE_DRIVER=file
SESSION_DRIVER=file
EOF

# Création des répertoires
mkdir -p storage/{app/public,framework/{cache,sessions,views},logs}
mkdir -p bootstrap/cache

# Arrêt et construction des conteneurs
docker-compose down || true
docker-compose build --no-cache
docker-compose up -d

# Attente du démarrage
sleep 45

# Configuration Laravel
docker-compose exec -T app composer install --no-dev --optimize-autoloader --no-interaction
docker-compose exec -T app php artisan migrate --force
docker-compose exec -T app php artisan config:cache
docker-compose exec -T app php artisan route:cache
docker-compose exec -T app php artisan view:cache
docker-compose exec -T app php artisan storage:link

# Permissions
docker-compose exec -T app chown -R www:www /var/www/html/storage
docker-compose exec -T app chown -R www:www /var/www/html/bootstrap/cache

echo "✅ Application déployée"
