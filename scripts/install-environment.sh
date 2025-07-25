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
