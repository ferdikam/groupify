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
