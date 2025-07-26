#!/bin/bash

# deploy.sh
set -e

echo "Starting deployment..."

# Variables
REPO_URL="git@github.com:ferdikam/groupify.git"
PROJECT_ROOT="/var/www/groupifyglobal.com"
RELEASE_DIR="$PROJECT_ROOT/releases/$(date +%Y%m%d_%H%M%S)"
CURRENT_DIR="$PROJECT_ROOT/current"

# Create release directory
mkdir -p $RELEASE_DIR

# Clone repository
git clone $REPO_URL $RELEASE_DIR
cd $RELEASE_DIR

# Install Composer dependencies
composer install --no-dev --optimize-autoloader

# Install NPM dependencies and build assets
npm ci
npm run build

# Copy environment file
cp $PROJECT_ROOT/.env $RELEASE_DIR/.env

# Create SQLite database if it doesn't exist
touch $RELEASE_DIR/database/database.sqlite

# Set permissions
chown -R deployer:www-data $RELEASE_DIR
chmod -R 755 $RELEASE_DIR
chmod -R 775 $RELEASE_DIR/storage
chmod -R 775 $RELEASE_DIR/bootstrap/cache

# Laravel optimization
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan migrate --force
php artisan storage:link

# Update symlink
ln -sfn $RELEASE_DIR $CURRENT_DIR

# Restart services
sudo systemctl reload php8.3-fpm  # ou php8.4-fpm selon votre version
sudo systemctl reload nginx

echo "Deployment completed successfully!"

# Clean old releases (keep last 5)
cd $PROJECT_ROOT/releases
ls -t | tail -n +6 | xargs -d '\n' rm -rf --

echo "Old releases cleaned up."
