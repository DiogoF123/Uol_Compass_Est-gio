#!/bin/bash

sudo dnf update -y
sudo amazon-linux-extras enable docker
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker


# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

mkdir -p /var/www/html
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-03c9b3354880b36a6.efs.us-east-1.amazonaws.com:/ /var/www/html


git clone <your-repository-url>
cd wordpress-docker

chmod 600 .env

docker-compose up -d
