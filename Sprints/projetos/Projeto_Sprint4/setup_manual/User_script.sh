#!/bin/bash
# esse script acompanha a utilização de variáveis durante a criação dos componentes do projeto, 
# para melhor dinamismo e facilidade no tempo de subida e descida dos serviços
sudo dnf update -y
sudo amazon-linux-extras enable docker
sudo dnf install -y docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
sudo systemctl enable docker


# Install Docker Compose externo
# Dont forget to check Binaries ;) ( pode haver error de arquivo binários)

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
# permissões de execução
sudo chmod +x /usr/local/bin/docker-compose
# Verify success
docker-compose version

# Instala EFS Utils
sudo dnf install -y amazon-efs-utils


# Monta Pasta EFS
sudo mkdir /efs

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "$EFS_ID".efs.us-east-1.amazonaws.com:/ /efs

# setup docker file
cd /efs
sudo mkdir wordpress-docker
cd wordpress-docker

# dir de arquivos do website
sudo mkdir wordpress-files



# Heredoc doyaml do dockerfile

cat <<-EOL > ./docker-compose.yml
services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
    # debug mode
      WORDPRESS_DEBUG: 1
      WORDPRESS_DB_HOST: $RDS_HOST_ADDR
      WORDPRESS_DB_USER: $DB_USERNAME
      WORDPRESS_DB_PASSWORD: $DB_PASSWORD
      WORDPRESS_DB_NAME: wordpressdb
    volumes:
      - /efs/wordpress-docker/wordpress-files:/var/www/html
EOL
# inicia o docker compose
docker-compose up -d

# Vá pra Home e Good Bye 
cd
