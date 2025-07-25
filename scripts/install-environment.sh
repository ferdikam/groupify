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
