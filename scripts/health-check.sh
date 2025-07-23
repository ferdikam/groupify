#!/bin/bash

# Simple health check script
URL=${1:-"http://localhost/health"}
TIMEOUT=${2:-30}

echo "🔍 Checking health at: $URL"

for i in $(seq 1 $TIMEOUT); do
    if curl -f -s $URL > /dev/null 2>&1; then
        echo "✅ Health check passed"
        exit 0
    fi
    echo -n "."
    sleep 1
done

echo "❌ Health check failed after $TIMEOUT seconds"
exit 1
