# scripts/install-environment.sh
#!/bin/bash
set -e

echo "🚀 Installation de l'environnement de production..."

# Vérifier si nous sommes root ou si nous avons sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "❌ Ce script nécessite des privilèges root ou sudo sans mot de passe"
    echo "📋 Exécutez l'une de ces commandes sur votre serveur :"
    echo "   sudo echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy"
    echo "   OU exécutez ce script en tant que root"
    exit 1
fi

# Préfixe pour les commandes privilégiées
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# Mise à jour du système
$SUDO apt update

# Installation de Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    $SUDO sh get-docker.sh
    $SUDO systemctl enable docker
    $SUDO systemctl start docker
    $SUDO usermod -aG docker $USER
    rm get-docker.sh
else
    echo "✅ Docker déjà installé"
fi

# Installation de Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installation de Docker Compose..."
    $SUDO curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $SUDO chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker Compose déjà installé"
fi

# Installation des outils
$SUDO apt install -y git curl

# Configuration du swap
if ! swapon --show | grep -q swapfile; then
    echo "💾 Configuration du swap..."
    $SUDO fallocate -l 1G /swapfile
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile
    $SUDO swapon /swapfile
    echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab
    echo 'vm.swappiness=10' | $SUDO tee -a /etc/sysctl.conf
    $SUDO sysctl -p
fi

# Configuration du pare-feu
$SUDO ufw allow OpenSSH
$SUDO ufw allow 80/tcp
$SUDO ufw allow 443/tcp
$SUDO ufw --force enable

echo "✅ Environnement installé avec succès"

# ---

# scripts/setup-project.sh
#!/bin/bash
set -e

PROJECT_PATH=$1
GITHUB_REPO=$2
GITHUB_TOKEN=$3

echo "📂 Configuration du projet..."
echo "🔍 Debug - Arguments reçus:"
echo "   PROJECT_PATH: '$PROJECT_PATH'"
echo "   GITHUB_REPO: '$GITHUB_REPO'"
echo "   GITHUB_TOKEN: $([ -n "$GITHUB_TOKEN" ] && echo '[SET]' || echo '[NOT SET]')"

# Vérifier que les arguments obligatoires sont fournis
if [ -z "$PROJECT_PATH" ]; then
    echo "❌ Erreur: PROJECT_PATH est vide ou non défini"
    echo "💡 Vérifiez que le secret PROJECT_PATH est configuré dans GitHub"
    exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
    echo "❌ Erreur: GITHUB_REPO est vide ou non défini"
    exit 1
fi

# Préfixe pour les commandes privilégiées
SUDO=""
if [ "$EUID" -ne 0 ] && command -v sudo &> /dev/null; then
    SUDO="sudo"
fi

# Nettoyer et recréer le répertoire si nécessaire
if [ -d "$PROJECT_PATH" ]; then
    echo "📄 Répertoire existant détecté, nettoyage..."
    rm -rf "$PROJECT_PATH"
fi

echo "📥 Clonage du repository..."
echo "🎯 Création du répertoire parent: $(dirname "$PROJECT_PATH")"
mkdir -p "$(dirname "$PROJECT_PATH")"

# Construire l'URL avec token si fourni
if [ -n "$GITHUB_TOKEN" ]; then
    CLONE_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
    echo "🔐 Utilisation du token GitHub pour le clonage..."
else
    CLONE_URL="https://github.com/${GITHUB_REPO}.git"
    echo "🌐 Clonage public du repository..."
fi

echo "📂 Clonage vers: $PROJECT_PATH"
echo "🔗 URL de clonage: https://github.com/${GITHUB_REPO}.git"

# Cloner le repository
git clone "$CLONE_URL" "$PROJECT_PATH"

# Vérifier que le clonage a réussi
if [ ! -d "$PROJECT_PATH/.git" ]; then
    echo "❌ Erreur: Le clonage Git a échoué"
    echo "💡 Vérifiez que:"
    echo "   - Le repository existe: https://github.com/$GITHUB_REPO"
    echo "   - Le repository est public OU vous avez fourni un token valide"
    echo "   - Votre serveur peut accéder à GitHub"
    exit 1
fi

echo "📋 Repository cloné avec succès"
cd "$PROJECT_PATH"

# Vérifier la branche main/master
if git show-ref --verify --quiet refs/heads/main; then
    BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
    BRANCH="master"
else
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "📌 Utilisation de la branche: $BRANCH"

# S'assurer qu'on est sur la bonne branche
git checkout "$BRANCH"

# Nettoyer les credentials Git pour la sécurité
if [ -n "$GITHUB_TOKEN" ]; then
    git remote set-url origin "https://github.com/${GITHUB_REPO}.git"
fi

# Utiliser sudo seulement si nécessaire et disponible
if [ -n "$SUDO" ]; then
    $SUDO chown -R $USER:$USER "$PROJECT_PATH"
else
    chown -R $USER:$USER "$PROJECT_PATH" 2>/dev/null || echo "⚠️ Impossible de changer les permissions - continuons"
fi

echo "✅ Projet configuré avec succès dans: $PROJECT_PATH"

# ---

# scripts/create-docker-configs.sh
#!/bin/bash
set -e

PROJECT_PATH=$1
DOMAIN_NAME=$2

echo "🐳 Création des configurations Docker..."

cd "$PROJECT_PATH"
mkdir -p docker

# Configuration Nginx avec SSL
cat > docker/nginx-ssl.conf << 'EOF'
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
EOF

# Remplacer le placeholder par le vrai domaine
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" docker/nginx-ssl.conf

# Configuration Supervisord
cat > docker/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log

[program:nginx]
command=nginx -g "daemon off;"
autorestart=false

[program:php-fpm]
command=php-fpm
autorestart=false
EOF

# Configuration PHP-FPM
cat > docker/php-fpm.conf << 'EOF'
[www]
user = www
group = www
listen = 9000
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF

# Configuration MySQL
cat > docker/mysql.cnf << 'EOF'
[mysqld]
innodb_buffer_pool_size = 128M
max_connections = 50
query_cache_size = 16M
EOF

echo "✅ Configurations Docker créées"

# ---

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

# ---

# scripts/setup-ssl.sh
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
