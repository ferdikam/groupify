# scripts/create-docker-configs.sh
#!/bin/bash
set -e

PROJECT_PATH=$1
DOMAIN_NAME=$2

echo "🐳 Création des configurations Docker..."

cd "$PROJECT_PATH"
mkdir -p docker

# Configuration Nginx avec SSL
cat > docker/nginx-ssl.conf << 'EOF'
worker_processes 1;
events { worker_connections 512; }
http {
    include /etc/nginx/mime.types;
    sendfile on;
    keepalive_timeout 15;
    client_max_body_size 20M;
    gzip on;

    server {
        listen 80;
        server_name _;
        location /.well-known/acme-challenge/ { root /var/www/certbot; }
        location / { return 301 https://$host$request_uri; }
    }

    server {
        listen 443 ssl http2;
        server_name DOMAIN_PLACEHOLDER;
        root /var/www/html/public;
        index index.php;

        ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;

        location / { try_files $uri $uri/ /index.php?$query_string; }
        location ~ \.php$ {
            fastcgi_pass app:9000;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF

# Remplacer le placeholder par le vrai domaine
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" docker/nginx-ssl.conf

# Configuration Supervisord
cat > docker/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log

[program:nginx]
command=nginx -g "daemon off;"
autorestart=false

[program:php-fpm]
command=php-fpm
autorestart=false
EOF

# Configuration PHP-FPM
cat > docker/php-fpm.conf << 'EOF'
[www]
user = www
group = www
listen = 9000
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF

# Configuration MySQL
cat > docker/mysql.cnf << 'EOF'
[mysqld]
innodb_buffer_pool_size = 128M
max_connections = 50
query_cache_size = 16M
EOF

echo "✅ Configurations Docker créées"
