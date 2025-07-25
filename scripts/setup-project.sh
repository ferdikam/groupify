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
