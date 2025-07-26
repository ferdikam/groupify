#!/bin/bash
set -e

PROJECT_PATH=$1
DOMAIN_NAME=$2

echo "🔒 Configuration SSL pour $DOMAIN_NAME..."

cd "$PROJECT_PATH"

# Vérifier que l'application fonctionne en HTTP
echo "🧪 Vérification que l'application fonctionne..."
if ! curl -f -s http://localhost > /dev/null; then
    echo "❌ L'application doit fonctionner en HTTP avant d'ajouter SSL"
    exit 1
fi

# Générer le certificat SSL
echo "📜 Génération du certificat SSL..."
docker-compose --profile ssl run --rm certbot

# Vérifier que le certificat a été créé
CERT_VOLUME=$(docker volume ls -q | grep certbot_certs | head -1)
if [ -z "$CERT_VOLUME" ]; then
    echo "❌ Volume certbot non trouvé"
    exit 1
fi

CERT_PATH="/var/lib/docker/volumes/${CERT_VOLUME}/_data/live/$DOMAIN_NAME"
if [ ! -d "$CERT_PATH" ]; then
    echo "❌ Certificat non généré. Vérifiez que:"
    echo "   - Le domaine $DOMAIN_NAME pointe vers ce serveur"
    echo "   - Le port 80 est accessible depuis internet"
    echo "   - Aucun firewall ne bloque les connexions"
    exit 1
fi

echo "✅ Certificat SSL créé avec succès"

# Créer la configuration Nginx avec SSL
echo "🔧 Mise à jour de la configuration Nginx..."
cat > docker/nginx-ssl.conf << EOF
worker_processes 1;
worker_rlimit_nofile 1024;

events {
    worker_connections 512;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Optimisations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 15;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Redirection HTTP vers HTTPS
    server {
        listen 80;
        server_name _;

        # Challenge Let's Encrypt
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    # Configuration HTTPS
    server {
        listen 443 ssl http2;
        server_name $DOMAIN_NAME;
        root /var/www/html/public;
        index index.php;

        # Certificats SSL
        ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

        # Configuration SSL moderne
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Headers de sécurité
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Configuration Laravel
        location / {
            try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php\$ {
            fastcgi_pass app:9000;
            fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
            include fastcgi_params;
            fastcgi_hide_header X-Powered-By;

            # Optimisations FastCGI
            fastcgi_buffer_size 128k;
            fastcgi_buffers 4 256k;
            fastcgi_busy_buffers_size 256k;
            fastcgi_read_timeout 300;
        }

        # Cache des assets statiques
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)\$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # Sécurité - bloquer l'accès aux fichiers sensibles
        location ~ /\.(?!well-known).* {
            deny all;
        }

        # Logs
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
    }
}
EOF

# Mettre à jour le docker-compose pour utiliser la nouvelle config
sed -i 's|./docker/nginx.conf:/etc/nginx/nginx.conf|./docker/nginx-ssl.conf:/etc/nginx/nginx.conf|' docker-compose.yml

# Redémarrer Nginx avec la nouvelle configuration
echo "🔄 Redémarrage de Nginx avec SSL..."
docker-compose restart nginx

# Attendre et tester
sleep 10

# Test HTTPS
echo "🧪 Test de la configuration SSL..."
if curl -f -s https://$DOMAIN_NAME > /dev/null; then
    echo "✅ SSL configuré avec succès!"
    echo "🌐 Application accessible sur: https://$DOMAIN_NAME"
else
    echo "⚠️ SSL configuré mais pas encore accessible. Vérifiez les logs:"
    docker-compose logs nginx
fi

# Configuration du renouvellement automatique
echo "🔄 Configuration du renouvellement automatique..."
cat > renew-ssl.sh << 'EOF'
#!/bin/bash
cd $(dirname $0)
docker-compose --profile ssl run --rm certbot renew
docker-compose restart nginx
EOF

chmod +x renew-ssl.sh

echo "✅ SSL configuré!"
echo "💡 Pour renouveler le certificat: ./renew-ssl.sh"
