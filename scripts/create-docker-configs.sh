#!/bin/bash
set -e

PROJECT_PATH=$1
DOMAIN_NAME=$2

echo "🐳 Création des configurations Docker..."

cd "$PROJECT_PATH"
mkdir -p docker

# Configuration Nginx HTTP (pas SSL au début)
cat > docker/nginx.conf << 'EOF'
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

    # Configuration HTTP simple
    server {
        listen 80;
        server_name _;
        root /var/www/html/public;
        index index.php;

        # Headers de sécurité basiques
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Configuration Laravel
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            fastcgi_pass app:9000;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
            fastcgi_hide_header X-Powered-By;

            # Optimisations FastCGI
            fastcgi_buffer_size 128k;
            fastcgi_buffers 4 256k;
            fastcgi_busy_buffers_size 256k;
            fastcgi_read_timeout 300;
        }

        # Cache des assets statiques
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # Sécurité - bloquer l'accès aux fichiers sensibles
        location ~ /\.(?!well-known).* {
            deny all;
        }

        # Logs pour debug
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
    }
}
EOF

# Configuration Supervisord
cat > docker/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autorestart=false
startretries=0

[program:php-fpm]
command=php-fpm
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autorestart=false
startretries=0
EOF

# Configuration PHP-FPM
cat > docker/php-fpm.conf << 'EOF'
[www]
user = www
group = www
listen = 9000
listen.owner = www
listen.group = www
pm = dynamic
pm.max_children = 8
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
EOF

echo "✅ Configurations Docker créées"
