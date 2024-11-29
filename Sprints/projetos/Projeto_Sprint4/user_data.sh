#!/bin/bash
# Docker WordPress Stack Setup Script for Amazon Linux 2023

# Enable robust error handling
set -e

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# System Update
dnf update -y

# Install Docker and supporting tools
dnf install -y docker docker-compose-plugin git

# Install additional utilities
dnf install -y wget curl unzip

# Start and Enable Docker Service
systemctl start docker
systemctl enable docker

# Create WordPress Project Directory
mkdir -p /opt/wordpress
cd /opt/wordpress

# Create Docker Compose File
cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: wordpress-db
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword

  wordpress:
    image: wordpress:latest
    container_name: wordpress-app
    ports:
      - "80:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: wordpress-phpmyadmin
    environment:
      PMA_HOST: db
      PMA_PORT: 3306
    ports:
      - "8080:80"
    depends_on:
      - db

volumes:
  db_data:
  wordpress_data:
EOF

# Create Nginx Reverse Proxy Configuration (Optional, for SSL/Advanced routing)
mkdir -p nginx
cat << 'EOF' > nginx/wordpress.conf
server {
    listen 80;
    server_name wordpress.example.com;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Create systemd service to ensure Docker Compose starts on boot
cat << 'EOF' > /etc/systemd/system/wordpress-docker.service
[Unit]
Description=WordPress Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/wordpress
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Create Backup Script
cat << 'EOF' > /opt/wordpress/backup.sh
#!/bin/bash
BACKUP_DIR="/opt/wordpress/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Backup Docker Volumes
docker run --rm \
  -v /var/lib/docker/volumes:/source \
  -v $BACKUP_DIR:/backup \
  ubuntu tar czf /backup/wordpress-volumes-$TIMESTAMP.tar.gz \
  /source/wordpress_wordpress_data \
  /source/wordpress_db_data

# Optional: Backup Docker Compose and Configuration Files
tar czf $BACKUP_DIR/wordpress-config-$TIMESTAMP.tar.gz \
  /opt/wordpress/docker-compose.yml \
  /opt/wordpress/nginx

# Remove backups older than 7 days
find $BACKUP_DIR -type f -mtime +7 -delete
EOF

# Set permissions for backup script
chmod +x /opt/wordpress/backup.sh

# Create restore script
cat << 'EOF' > /opt/wordpress/restore.sh
#!/bin/bash
BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Please provide a backup file to restore"
    exit 1
fi

# Stop current containers
docker compose down

# Restore volumes
docker run --rm \
  -v /var/lib/docker/volumes:/target \
  -v $(dirname "$BACKUP_FILE"):/backup \
  ubuntu tar xzf /backup/$(basename "$BACKUP_FILE") -C /target

# Restart containers
docker compose up -d

echo "Restoration complete."
EOF
chmod +x /opt/wordpress/restore.sh

# Configure daily backup via crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/wordpress/backup.sh") | crontab -

# Enable and start the WordPress Docker service
systemctl daemon-reload
systemctl enable wordpress-docker
systemctl start wordpress-docker

# Configure firewall
dnf install -y firewalld
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=80/tcp   # HTTP
firewall-cmd --permanent --add-port=443/tcp  # HTTPS
firewall-cmd --permanent --add-port=8080/tcp # PHPMyAdmin
firewall-cmd --reload

# Output completion message
echo "Docker-based WordPress stack setup completed successfully!"
echo "Access WordPress at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"
echo "Access PHPMyAdmin at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):8080"
