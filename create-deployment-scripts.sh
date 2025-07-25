#!/bin/bash
# create-deployment-scripts.sh
# Script pour créer automatiquement tous les scripts de déploiement

set -e

echo "🚀 Création des scripts de déploiement..."

# Créer le répertoire scripts
mkdir -p scripts

# Script 1: install-environment.sh
cat > scripts/install-environment.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Installation de l'environnement de production..."

# Mise à jour du système
sudo apt update

# Installation de Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    rm get-docker.sh
else
    echo "✅ Docker déjà installé"
fi

# Installation de Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installation de Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker Compose déjà installé"
fi

# Installation des outils
sudo apt install -y git curl

# Configuration du swap
if ! swapon --show | grep -q swapfile; then
    echo "💾 Configuration du swap..."
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# Configuration du pare-feu
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "✅ Environnement installé avec succès"
EOF

# Script 2: setup-project.sh
cat > scripts/setup-project.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_PATH=$1
GITHUB_REPO=$2

echo "📂 Configuration du projet..."

if [ ! -d "$PROJECT_PATH" ]; then
    echo "📥 Clonage du repository..."
    mkdir -p "$PROJECT_PATH"
    git clone "https://github.com/$GITHUB_REPO.git" "$PROJECT_PATH"
else
    echo "📄 Mise à jour du projet..."
    cd "$PROJECT_PATH"
    git fetch origin
    git reset --hard origin/main
fi

sudo chown -R $USER:$USER "$PROJECT_PATH"
echo "✅ Projet configuré"
EOF

# Script 3: create-docker-configs.sh
cat > scripts/create-docker-configs.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_PATH=$1
DOMAIN_NAME=$2

echo "🐳 Création des configurations Docker..."

cd "$PROJECT_PATH"
mkdir -p docker

# Configuration Nginx avec SSL
cat > docker/nginx-ssl.conf << 'NGINXEOF'
worker_processes 1;
events { worker_connections 512; }
http {
    include /etc/nginx/mime.types;
    sendfile on;
    keepalive_timeout 15;
    client_max_body_size 20M;
    gzip on;

    server {
        listen 80;
        server_name _;
        location /.well-known/acme-challenge/ { root /var/www/certbot; }
        location / { return 301 https://$host$request_uri; }
    }

    server {
        listen 443 ssl http2;
        server_name DOMAIN_PLACEHOLDER;
        root /var/www/html/public;
        index index.php;

        ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;

        location / { try_files $uri $uri/ /index.php?$query_string; }
        location ~ \.php$ {
            fastcgi_pass app:9000;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
NGINXEOF

# Remplacer le placeholder par le vrai domaine
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" docker/nginx-ssl.conf

# Configuration Supervisord
cat > docker/supervisord.conf << 'SUPERVISOREOF'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log

[program:nginx]
command=nginx -g "daemon off;"
autorestart=false

[program:php-fpm]
command=php-fpm
autorestart=false
SUPERVISOREOF

# Configuration PHP-FPM
cat > docker/php-fpm.conf << 'PHPEOF'
[www]
user = www
group = www
listen = 9000
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
PHPEOF

# Configuration MySQL
cat > docker/mysql.cnf << 'MYSQLEOF'
[mysqld]
innodb_buffer_pool_size = 128M
max_connections = 50
query_cache_size = 16M
MYSQLEOF

echo "✅ Configurations Docker créées"
EOF

# Script 4: deploy-app.sh
cat > scripts/deploy-app.sh << 'EOF'
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
cat > .env << ENVEOF
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
ENVEOF

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
EOF

# Script 5: setup-ssl.sh
cat > scripts/setup-ssl.sh << 'EOF'
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
EOF

# Rendre tous les scripts exécutables
chmod +x scripts/*.sh

echo "✅ Tous les scripts de déploiement ont été créés dans le répertoire 'scripts/'"
echo ""
echo "📋 Scripts créés :"
echo "  - scripts/install-environment.sh"
echo "  - scripts/setup-project.sh"
echo "  - scripts/create-docker-configs.sh"
echo "  - scripts/deploy-app.sh"
echo "  - scripts/setup-ssl.sh"
echo ""
echo "🎯 Prochaines étapes :"
echo "1. Ajoutez ces scripts à votre repository Git"
echo "2. Configurez vos secrets GitHub"
echo "3. Poussez sur la branche main pour déclencher le déploiement"
