services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel_app
    restart: unless-stopped
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
      - DB_HOST=mysql
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./storage:/var/www/html/storage
      - ./bootstrap/cache:/var/www/html/bootstrap/cache
      - ./docker/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf
      - ./docker/php-fpm.conf:/usr/local/etc/php-fpm.d/www.conf
      - certbot_certs:/etc/letsencrypt
      - certbot_www:/var/www/certbot
    networks:
      - laravel_network
    mem_limit: 512m
    cpus: 0.5
    healthcheck:
      test: ["CMD", "php", "-v"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  mysql:
    image: mysql:8.0
    container_name: laravel_mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
      MYSQL_USER: ${DB_USERNAME}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql.cnf:/etc/mysql/conf.d/mysql.cnf
    networks:
      - laravel_network
    mem_limit: 256m
    cpus: 0.3
    command: --innodb-buffer-pool-size=128M --max-connections=50
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 5s
      retries: 20
      start_period: 30s

  nginx:
    image: nginx:alpine
    container_name: laravel_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./:/var/www/html
      - ./docker/nginx-ssl.conf:/etc/nginx/nginx.conf
      - certbot_certs:/etc/letsencrypt
      - certbot_www:/var/www/certbot
    depends_on:
      app:
        condition: service_healthy
    networks:
      - laravel_network
    mem_limit: 64m
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  certbot:
    image: certbot/certbot
    container_name: laravel_certbot
    volumes:
      - certbot_certs:/etc/letsencrypt
      - certbot_www:/var/www/certbot
    command: certonly --webroot --webroot-path=/var/www/certbot --email ${SSL_EMAIL} --agree-tos --no-eff-email -d ${DOMAIN_NAME}
    depends_on:
      - nginx

volumes:
  mysql_data:
  certbot_certs:
  certbot_www:

networks:
  laravel_network:
    driver: bridge
