#!/bin/bash

set -e

echo "🔧 Setting up production server for Laravel FrankenPHP..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install Nginx (load balancer)
sudo apt install nginx -y

# Install additional tools
sudo apt install curl wget git htop -y

# Create deploy user
sudo adduser --disabled-password --gecos "" deploy
sudo usermod -aG docker deploy
sudo usermod -aG sudo deploy

# Setup SSH for deploy user
sudo -u deploy mkdir -p /home/deploy/.ssh
echo "# Add your public key here" | sudo -u deploy tee /home/deploy/.ssh/authorized_keys
sudo -u deploy chmod 700 /home/deploy/.ssh
sudo -u deploy chmod 600 /home/deploy/.ssh/authorized_keys

# Create application directory
sudo mkdir -p /var/www/laravel-app
sudo chown deploy:deploy /var/www/laravel-app

# Create Docker volumes (production only)
docker volume create laravel_mysql_data
docker volume create laravel_redis_data
docker volume create laravel_storage_data
docker network create laravel

# Setup basic firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Setup Nginx production configuration
sudo tee /etc/nginx/sites-available/laravel << 'EOF'
upstream backend {
    server 127.0.0.1:8081;
}

server {
    listen 80;
    server_name yourdomain.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    location /health {
        access_log off;
        proxy_pass http://backend/health;
    }

    # Static files handling
    location ~* \.(css|js|gif|ico|jpeg|jpg|png|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://backend;
        proxy_cache_valid 200 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx -y

# Create environment file template
sudo -u deploy tee /var/www/laravel-app/.env << 'EOF'
# Copy your production environment variables here
DB_PASSWORD=your-secure-password
DB_ROOT_PASSWORD=your-secure-root-password
EOF

echo "✅ Production server setup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Add your SSH public key to /home/deploy/.ssh/authorized_keys"
echo "2. Copy docker-compose files to /var/www/laravel-app"
echo "3. Configure your domain in nginx config and .env file"
echo "4. Set up SSL: sudo certbot --nginx -d yourdomain.com"
echo "5. Configure your GitHub secrets:"
echo "   - PRODUCTION_HOST=yourdomain.com"
echo "   - PRODUCTION_USER=deploy"
echo "   - PRODUCTION_SSH_KEY=<your-private-key>"
echo "   - DB_PASSWORD=<your-db-password>"
echo "   - DB_ROOT_PASSWORD=<your-root-password>"
echo "6. Push to main branch to trigger deployment"
