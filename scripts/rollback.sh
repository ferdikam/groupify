#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Starting rollback process...${NC}"

# Get the previous tag
PREVIOUS_TAG=${1}

if [ -z "$PREVIOUS_TAG" ]; then
    echo -e "${YELLOW}⚠️ No tag specified, getting previous git tag...${NC}"
    PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^)
fi

if [ -z "$PREVIOUS_TAG" ]; then
    echo -e "${RED}❌ Could not determine previous version${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Rolling back to: $PREVIOUS_TAG${NC}"

# Rollback using blue-green deployment script
./deploy-blue-green.sh "ghcr.io/ferdikam/groupify:$PREVIOUS_TAG"

echo -e "${GREEN}✅ Rollback completed successfully!${NC}"

# Notify about rollback
if [ ! -z "$SLACK_WEBHOOK" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🔄 Production rollback to $PREVIOUS_TAG completed\"}" \
        $SLACK_WEBHOOK || true
fi
