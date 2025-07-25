#!/bin/bash
set -e

PROJECT_PATH=$1
DOMAIN_NAME=$2

echo "🔒 Configuration SSL..."

cd "$PROJECT_PATH"

# Vérification du certificat
CERT_PATH="/var/lib/docker/volumes/$(docker volume ls -q | grep certbot_certs | head -1)/_data/live/$DOMAIN_NAME"

if [ ! -d "$CERT_PATH" ]; then
    echo "📜 Génération du certificat SSL..."
    sleep 10
    docker-compose run --rm certbot || echo "Erreur SSL - continuons"
    sleep 5
    docker-compose restart nginx
else
    echo "✅ Certificat SSL déjà configuré"
fi

# Nettoyage
docker system prune -f

echo "✅ SSL configuré"
