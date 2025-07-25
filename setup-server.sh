#!/bin/bash
# setup-server.sh - Script d'installation pour VPS DigitalOcean

set -e

echo "🚀 Configuration du serveur pour Laravel Filament..."

# Variables (à personnaliser)
PROJECT_NAME="groupify"
DOMAIN_NAME="groupifyglobal.com"
GITHUB_REPO="https://github.com/ferdikam/groupify.git"

# Mise à jour du système
echo "📦 Mise à jour du système..."
apt update && apt upgrade -y

# Installation de Docker et Docker Compose
echo "🐳 Installation de Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

# Installation de Docker Compose
echo "🔧 Installation de Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Installation de Git
echo "📚 Installation de Git..."
apt install -y git curl

# Création de l'utilisateur pour le déploiement
echo "👤 Création de l'utilisateur deploy..."
useradd -m -s /bin/bash deploy
usermod -aG docker deploy

# Configuration SSH pour deploy
echo "🔑 Configuration SSH..."
mkdir -p /home/deploy/.ssh
touch /home/deploy/.ssh/authorized_keys
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh

echo "🔑 Ajoutez votre clé publique à /home/deploy/.ssh/authorized_keys"
echo "Exemple: echo 'ssh-rsa AAAA...' >> /home/deploy/.ssh/authorized_keys"

# Clonage du projet
echo "📂 Clonage du projet..."
cd /home/deploy
sudo -u deploy git clone $GITHUB_REPO $PROJECT_NAME
cd $PROJECT_NAME
chown -R deploy:deploy /home/deploy/$PROJECT_NAME

# Configuration du pare-feu
echo "🔥 Configuration du pare-feu..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Optimisation du swap pour 1Go RAM
echo "💾 Configuration du swap..."
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Configuration mémoire pour MySQL
echo "⚙️ Optimisation système..."
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
sysctl -p

# Création du fichier .env exemple
cat > /home/deploy/$PROJECT_NAME/.env.example << 'EOF'
APP_NAME="Groupify"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://groupifyglobal.com

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=

DOMAIN_NAME=votre-domaine.com
SSL_EMAIL=votre-email@example.com
EOF

chown deploy:deploy /home/deploy/$PROJECT_NAME/.env.example

echo "✅ Installation terminée!"
echo ""
echo "📋 Étapes suivantes:"
echo "1. Configurez votre DNS pour pointer vers cette IP"
echo "2. Ajoutez vos secrets dans GitHub:"
echo "   - SSH_PRIVATE_KEY: votre clé privée SSH"
echo "   - SSH_PUBLIC_KEY: votre clé publique SSH"
echo "   - SERVER_HOST: $HOSTNAME"
echo "   - SERVER_USER: deploy"
echo "   - PROJECT_PATH: /home/deploy/$PROJECT_NAME"
echo "   - DB_DATABASE: laravel"
echo "   - DB_USERNAME: laravel"
echo "   - DB_PASSWORD: [générer un mot de passe sécurisé]"
echo "   - DOMAIN_NAME: $DOMAIN_NAME"
echo "   - SSL_EMAIL: votre-email@example.com"
echo "   - APP_KEY: [générer avec 'php artisan key:generate --show']"
echo ""
echo "3. Ajoutez votre clé publique SSH:"
echo "   echo 'votre-clé-publique' >> /home/deploy/.ssh/authorized_keys"
echo ""
echo "4. Testez la connexion SSH:"
echo "   ssh deploy@$HOSTNAME"
echo ""
echo "5. Poussez votre code et déclenchez le déploiement!"
