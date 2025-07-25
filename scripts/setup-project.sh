#!/bin/bash
set -e

PROJECT_PATH=$1
GITHUB_REPO=$2

echo "📂 Configuration du projet..."

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
mkdir -p "$(dirname "$PROJECT_PATH")"
git clone "https://github.com/$GITHUB_REPO.git" "$PROJECT_PATH"

# Vérifier que le clonage a réussi
if [ ! -d "$PROJECT_PATH/.git" ]; then
    echo "❌ Erreur: Le clonage Git a échoué"
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
git pull origin "$BRANCH"

# Utiliser sudo seulement si nécessaire et disponible
if [ -n "$SUDO" ]; then
    $SUDO chown -R $USER:$USER "$PROJECT_PATH"
else
    chown -R $USER:$USER "$PROJECT_PATH" 2>/dev/null || echo "⚠️ Impossible de changer les permissions - continuons"
fi

echo "✅ Projet configuré avec succès"
