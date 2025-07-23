#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_TAG=${1:-latest}
DOCKER_IMAGE="ghcr.io/ferdikam/groupify:$IMAGE_TAG"
HEALTH_CHECK_TIMEOUT=180
HEALTH_CHECK_INTERVAL=10

echo -e "${BLUE}🚀 Starting Production Blue-Green deployment...${NC}"
echo -e "${BLUE}📦 Image: $DOCKER_IMAGE${NC}"

# Function to check health
check_health() {
    local port=$1
    local timeout=$2
    local interval=$3

    echo -e "${YELLOW}⏳ Checking health on port $port...${NC}"

    for i in $(seq 1 $((timeout/interval))); do
        if curl -f -s http://localhost:$port/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check passed on port $port${NC}"
            return 0
        fi
        echo -n "."
        sleep $interval
    done

    echo -e "${RED}❌ Health check failed on port $port${NC}"
    return 1
}

# Detect current environment
CURRENT=""
TARGET=""

if docker-compose -f docker-compose.blue.yml ps 2>/dev/null | grep -q "Up"; then
    CURRENT="blue"
    TARGET="green"
    TARGET_PORT="8082"
elif docker-compose -f docker-compose.green.yml ps 2>/dev/null | grep -q "Up"; then
    CURRENT="green"
    TARGET="blue"
    TARGET_PORT="8081"
else
    # First deployment
    TARGET="blue"
    TARGET_PORT="8081"
fi

echo -e "${BLUE}🎯 Deploying to: $TARGET environment${NC}"
if [ ! -z "$CURRENT" ]; then
    echo -e "${BLUE}📍 Current environment: $CURRENT${NC}"
fi

# Pull new image
echo -e "${YELLOW}📥 Pulling new image...${NC}"
docker pull $DOCKER_IMAGE

# Update docker-compose file with new image
echo -e "${YELLOW}📝 Updating docker-compose configuration...${NC}"
sed -i "s|image: ghcr.io.*|image: $DOCKER_IMAGE|g" docker-compose.$TARGET.yml

# Start target environment
echo -e "${YELLOW}🏃 Starting $TARGET environment...${NC}"
docker-compose -f docker-compose.$TARGET.yml up -d

# Wait for health check
if ! check_health $TARGET_PORT $HEALTH_CHECK_TIMEOUT $HEALTH_CHECK_INTERVAL; then
    echo -e "${RED}❌ Health check failed, cleaning up...${NC}"
    docker-compose -f docker-compose.$TARGET.yml down
    docker-compose -f docker-compose.$TARGET.yml logs
    exit 1
fi

# Run migrations on target
echo -e "${YELLOW}🗃️ Running migrations...${NC}"
docker-compose -f docker-compose.$TARGET.yml exec -T app php artisan migrate --force

# Clear and cache configurations
echo -e "${YELLOW}⚡ Optimizing application...${NC}"
docker-compose -f docker-compose.$TARGET.yml exec -T app php artisan config:cache
docker-compose -f docker-compose.$TARGET.yml exec -T app php artisan route:cache
docker-compose -f docker-compose.$TARGET.yml exec -T app php artisan view:cache

# Final health check after optimizations
if ! check_health $TARGET_PORT 60 5; then
    echo -e "${RED}❌ Final health check failed, rolling back...${NC}"
    docker-compose -f docker-compose.$TARGET.yml down
    exit 1
fi

# Switch load balancer
echo -e "${YELLOW}🔄 Switching traffic to $TARGET...${NC}"

# Update nginx configuration
if [ -f "docker/nginx/nginx.$TARGET.conf" ]; then
    sudo cp docker/nginx/nginx.$TARGET.conf /etc/nginx/sites-enabled/default
    sudo nginx -t && sudo nginx -s reload
else
    echo -e "${YELLOW}⚠️ Nginx config not found, manual switch required${NC}"
fi

# Wait for traffic to switch
sleep 5

# Stop old environment
if [ ! -z "$CURRENT" ]; then
    echo -e "${YELLOW}🛑 Stopping $CURRENT environment...${NC}"
    sleep 10  # Grace period
    docker-compose -f docker-compose.$CURRENT.yml down

    # Clean up old images (keep last 3)
    echo -e "${YELLOW}🧹 Cleaning up old Docker images...${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}" | \
    grep "ghcr.io/ferdikam/groupify" | \
    tail -n +4 | \
    awk '{print $1":"$2}' | \
    xargs -r docker rmi || true
fi

echo -e "${GREEN}✅ Production deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Application is now running on $TARGET environment${NC}"
echo -e "${GREEN}📊 Health check: http://yourdomain.com/health${NC}"

# Send deployment notification
if [ ! -z "$SLACK_WEBHOOK" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚀 Production deployment completed successfully on $TARGET environment\"}" \
        $SLACK_WEBHOOK || true
fi
