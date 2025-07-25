#!/bin/bash
# scripts/wait-for-mysql.sh

set -e

host="$1"
shift
cmd="$@"

echo "⏳ Attente de MySQL sur $host..."

# Attendre que MySQL soit accessible
for i in {1..60}; do
    if mysql -h"$host" -u"${DB_USERNAME:-laravel}" -p"${DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
        echo "✅ MySQL est prêt sur $host après ${i}s !"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Timeout MySQL après 60s sur $host"
        exit 1
    fi
    echo "🔄 MySQL pas encore prêt sur $host - tentative $i/60..."
    sleep 1
done

# Exécuter la commande si fournie
if [ $# -gt 0 ]; then
    echo "🚀 Exécution de: $cmd"
    exec $cmd
fi
