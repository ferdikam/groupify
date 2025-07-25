#!/bin/bash

set -e

host="$1"
shift
cmd="$@"

echo "⏳ Attente de MySQL sur $host..."

until mysql -h"$host" -u"${DB_USERNAME:-laravel}" -p"${DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "🔄 MySQL n'est pas encore prêt sur $host - attente..."
    sleep 2
done

echo "✅ MySQL est prêt sur $host !"
exec $cmd
