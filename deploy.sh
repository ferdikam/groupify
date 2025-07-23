#!/bin/bash

set -e

echo "🚀 Starting local development environment..."

# Stop existing containers
docker-compose down

# Build and start
docker-compose up -d --build

echo "⏳ Waiting for database to be ready..."
sleep 10

# Install dependencies
echo "📦 Installing dependencies..."
docker-compose exec app composer install

# Generate key if needed
if [ ! -f .env ]; then
    echo "📋 Copying environment file..."
    cp .env.example .env
    docker-compose exec app php artisan key:generate
fi

# Run migrations
echo "🗃️ Running migrations..."
docker-compose exec app php artisan migrate

# Clear caches
echo "🧹 Clearing caches..."
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear

echo "✅ Development environment is ready!"
echo "🌐 Application: http://localhost"
echo "📧 MailHog: http://localhost:8025"
echo "🗄️ MySQL: localhost:3306"
echo "🔴 Redis: localhost:6379"
