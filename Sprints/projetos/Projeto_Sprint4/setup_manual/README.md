# Atividade de Stack em Container com Docker na Cloud com AWS
## Referente a Sprint 4



# Introdução
A Atividade da Sprint 4 da Estágio da Compass UOL solicitou a criação de um stack Wordpress conteinerizada. Com as instâncias do WordPress se conectando a um serviço RDS da Amazon (MySQL), e os arquivos estáticos do WordPress sendo armazenados em um EFS montado nas instâncias EC2. Sendo necessário utilizar o Load Balancer como ponto para tráfico inbound para as redes privadas - expor-las. Ademais, Auto-Scaling, ajustando automaticamente o número de instâncias EC2 em funcionamento.

E esse projeto buscando aproveitar a proposta, tentou adotar com a utilização do AWS CLI no seu Inteiriço afim de melhor consolidar os conhecimento propostos da atividade, ademais explorando de maneira brevê a vasta gama de opções e customizações disponibilizadas pelos serviços da Amazon Web Services - AWS.


- [Introdução](#introdução)
    - [Índice](#índice)
    - [1 - Criação do VPC](#1---criação-do-vpc)
    - [1.1 - Criação do  Gateway de Internet da VPC](#11---criação-do--gateway-de-internet-da-vpc)
    - [2 - Criação das Subnets](#2---criação-das-subnets)
    - [2.1 - Opção de Liberação do IP para as Subnets Públicas](#21---opção-de-liberação-do-ip-para-as-subnets-públicas)
    - [2.2 - Adição das TAGs do Projeto e Nomes individuais das Subnets](#22---adição-das-tags-do-projeto-e-nomes-individuais-das-subnets)
    - [3 - Criação dos Gateways e Tabelas de Roteamento](#3---criação-dos-gateways-e-tabelas-de-roteamento)
    - [3.2 - Criação das Tabelas de Roteamento](#32---criação-das-tabelas-de-roteamento)
      - [3.2.1 - Nomeação das Tabelas de Roteamento](#321---nomeação-das-tabelas-de-roteamento)
    - [3.3 - Associação das Subnets das AZs pra Tabela especifica](#33---associação-das-subnets-das-azs-pra-tabela-especifica)
    - [4 Criação e Configuração dos Security Groups](#4-criação-e-configuração-dos-security-groups)
    - [4.1 Security Group do CLB ( Classic Load Balancer)](#41-security-group-do-clb--classic-load-balancer)
    - [4.2 Security Group do SSH](#42-security-group-do-ssh)
    - [4.3 Security Group do Servidor Host](#43-security-group-do-servidor-host)
    - [4.4 Security Group do Base de Dados (MySql)](#44-security-group-do-base-de-dados-mysql)
    - [4.5 Security Group do Elastic File System (EFS)](#45-security-group-do-elastic-file-system-efs)
    - [5 Criação da Instância de Dados ( RDS )](#5-criação-da-instância-de-dados--rds-)
    - [5.1 Criação da Instância de Dados ( RDS )](#51-criação-da-instância-de-dados--rds-)
    - [6 Criação da Instância de Arquivos - Elastic File System ( EFS )](#6-criação-da-instância-de-arquivos---elastic-file-system--efs-)
    - [7 Criação do User\_data.sh](#7-criação-do-user_datash)
    - [7.1 Script User\_data.sh](#71-script-user_datash)
    - [8 Instâncias de Debugging](#8-instâncias-de-debugging)
    - [8.1 Funcionamento do Wordpress](#81-funcionamento-do-wordpress)
    - [9 Criação do Load Balancer](#9-criação-do-load-balancer)
    - [9.2 Teste Manual com Instãncias Privadas para Debugging do CLB](#92-teste-manual-com-instãncias-privadas-para-debugging-do-clb)
    - [9.3 Clean-up Pré Auto-Scaling](#93-clean-up-pré-auto-scaling)
    - [10 Criação do Auto Scaling Group](#10-criação-do-auto-scaling-group)
    - [10.1 O Auto Scaling Group](#101-o-auto-scaling-group)
- [Conclusões Finais e Agradecimentos](#conclusões-finais-e-agradecimentos)



### 1 - Criação do VPC
Definindo a expectativa do escopo da rede do projeto, foi escolhido o CIDR padrão da AWS 172.31.0.0/20 com as subnets no range 172.31.0.0/24, considerando o objetivo de prática e evitar conflitos com as ranges próprios da AWS.
<details>
<summary>Comandos VPC</summary>

~~~~bash
# Criação da VPC, utilizado no início do projeto
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 172.31.0.0/20 \
    --query 'Vpc.VpcId' \
    --output text \
    --region us-east-1)

# Opção importante para termos DNS dos serviços automáticamente pela AWS
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames \
    --region us-east-1

# O create-tags é utilizado majoritariamente pela facilidade da adição das TAGs do tipo nome.
aws ec2 create-tags \
    --resources $VPC_ID \
    --tags 'Name:CL_wordpress_stack', 'Projeto:WPSTACK' \
    --region us-east-1
~~~~
</details>

<details>
<summary>Comandos IGW</summary>

### 1.1 - Criação do  Gateway de Internet da VPC
~~~~bash
# necessário para acesso à Internet nas Instâncias.
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text \
    --region us-east-1)

aws ec2 create-tags \
    --resources $IGW_ID \
    --tags Key=Name,Value=CL_wordpress_stack \
    --region us-east-1

# Ele precisa ser anexado ao VPC, atenção que o custo do IGW é por tráfico saindo para internet, e não é taxado pela criação ou deleção 
aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID \
    --region us-east-1
~~~~ 
</details>


### 2 - Criação das Subnets 
|AZ         | Subnets Públicas                     |         Subnets Privadas dos Servidores Host      |Subnets Privadas das Instâncias de Dados ( RDS )  |
|----------------|-------------------------------|-----------------------------|-----------------------------|
|us-east-1a           |172.31.0.0/24 == 172.31.0.x                    |172.31.2.0/24 == 172.31.2.x                         |172.31.4.0/24 == 172.31.4.x                    |
|us-east-1b      |172.31.1.0/24 == 172.31.1.x                    |172.31.3.0/24 == 172.31.3.x                         |172.31.5.0/24 == 172.31.5.x                    |

<details>
<summary>Comandos Criação Subnets</summary>

~~~bash
# Criação das Subnets Públicas
SUBNET_ID_1=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.31.0.0/24 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' \
    --output text \
    --region us-east-1)

SUBNET_ID_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.31.1.0/24 \
    --availability-zone us-east-1b \
    --query 'Subnet.SubnetId' \
    --output text \
    --region us-east-1)

# Criação das Subnets Privadas dos Servidores Host
SUBNET_ID_3=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.31.2.0/24 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' \
    --output text \
    --region us-east-1)
  
SUBNET_ID_4=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.31.3.0/24 \
    --availability-zone us-east-1b \
    --query 'Subnet.SubnetId' \
    --output text \
    --region us-east-1)

# Private subnets  data server
SUBNET_ID_5=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.31.4.0/24 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' \
    --output text \
    --region us-east-1)

SUBNET_ID_6=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.31.5.0/24 \
    --availability-zone us-east-1b \
    --query 'Subnet.SubnetId' \
    --output text \
    --region us-east-1)
~~~

</details>

		

### 2.1 - Opção de Liberação do IP para as Subnets Públicas
Liberando um IP público para acesso pela internet, diferenciando-se ao possuir uma definição dinâmica, diferente da estática dos IPs Elásticos da AWS. Valendo atentar que esses IPs públicos acarretam custos no momento que instâncias são levantadas dentro das subnets com essas opções.

~~~bash
aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_ID_1  \
    --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_ID_2  \
    --map-public-ip-on-launch
~~~~

### 2.2 - Adição das TAGs do Projeto e Nomes individuais das Subnets 
<details>
<summary>Nomes Das Subnets</summary>

~~~bash
# Subnets Públicas
aws ec2 create-tags \
    --resources $SUBNET_ID_1 \
    --tags Key=Name,Value=public_subnet_AZ1 \
    --region us-east-1
    
aws ec2 create-tags \
    --resources $SUBNET_ID_2 \
    --tags Key=Name,Value=public_subnet_AZ2 \
    --region us-east-1

# Subnets dos Host Privados
aws ec2 create-tags \
    --resources $SUBNET_ID_3 \
    --tags Key=Name,Value=private_server_AZ1 \
    --region us-east-1	

aws ec2 create-tags \
    --resources $SUBNET_ID_4 \
    --tags Key=Name,Value=private_server_AZ2 \
    --region us-east-1

# Subnets Privadas das Instâncias de Dados
aws ec2 create-tags \
    --resources $SUBNET_ID_5 \
    --tags Key=Name,Value=private_data_AZ1 \
    --region us-east-1

aws ec2 create-tags \
    --resources $SUBNET_ID_6 \
    --tags Key=Name,Value=private_data_AZ2 \
    --region us-east-1
~~~

</details>

<details>
<summary>Tags para Identificação das Subnets do Projeto</summary>

~~~bash
aws ec2 create-tags \
    --resources $SUBNET_ID_1 \
    --tags Key=Projeto,Value=WPSTACK \
    --region us-east-1

aws ec2 create-tags \
    --resources $SUBNET_ID_2 \
    --tags Key=Projeto,Value=WPSTACK \
    --region us-east-1

aws ec2 create-tags \
    --resources $SUBNET_ID_3 \
    --tags Key=Projeto,Value=WPSTACK \
    --region us-east-1

aws ec2 create-tags \
    --resources $SUBNET_ID_4 \
    --tags Key=Projeto,Value=WPSTACK \
    --region us-east-1
aws ec2 create-tags \
    --resources $SUBNET_ID_5 \
    --tags Key=Projeto,Value=WPSTACK \
    --region us-east-1

aws ec2 create-tags \
    --resources $SUBNET_ID_6 \
    --tags Key=Projeto,Value=WPSTACK \
    --region us-east-1
~~~

</details>


### 3 - Criação dos Gateways e Tabelas de Roteamento
Os Gateways NAT serão utilizados nas subnets públicas para garantir o acesso das instâncias privada para produção do outbound traffic - nas subnets privadas sem IP público ou acesso a Internet. Sendo importante Apontar que os NATs Gateways utilizam IPs Elásticos, e esse tipo de IP estático da AWS possui custeamento específico desde o tempo de alocação, sendo importante liberá-los assim que possível.

Junto a isso, serão necessárias as tabelas de roteamento que irão indicar de forma organizada e sem conflitos as rotas por onde o nosso tráfego poderá estar levando e trazendo os pacotes de dados, melhor isolando nossas instâncias juntamente ao definido pelos Security Groups.

~~~~ bash
# Criação e Separação dos IPs elásticos dos Gateways
# Cuidado para não criar um IP elástico Orfão
NAT_EIP1=$(aws ec2 allocate-address \
    --query 'AllocationId' \
    --output text )

NAT_EIP2=$(aws ec2 allocate-address \
    --query 'AllocationId' \
    --output text )

# Create NAT Gateway in a public subnet
# Cuidado para não criar mais de 1 Gateway para o mesmo IP elástico

NAT_GATEWAY_ID1=$(aws ec2 create-nat-gateway \
    --subnet-id $SUBNET_ID_1 \
    --allocation-id $NAT_EIP1 \
    --query "NatGateway.NatGatewayId" \
    --output text )

NAT_GATEWAY_ID2=$(aws ec2 create-nat-gateway \
    --subnet-id $SUBNET_ID_2 \
    --allocation-id $NAT_EIP2 \
    --query "NatGateway.NatGatewayId" \
    --output text )

# Nomeação por TAGs para organização

aws ec2 create-tags \
    --resources $NAT_GATEWAY_ID1 \
    --tags Key=Name,Value=NATG_public_AZ1 

aws ec2 create-tags \
    --resources $NAT_GATEWAY_ID2 \
    --tags Key=Name,Value=NATG_public_AZ2 

# importante apontar que option do "create-nat-gateway"	--connectivity-type possui valor padrão como "Public"
# Essas calls (Allocate IP e Create NAT) demandam tempo para produzir o resultado esperado e dessa maneira os comandos não podem ser encadeados diretamente com o restante do setup.
~~~~


		
--------

### 3.2 - Criação das Tabelas de Roteamento

<details>
<summary>Comando Tabelas de Roteamento</summary>
~~~~ bash
# Tabela de Roteamento das Subnets Públicas e o Internet Gateway
ROUTE_TABLE1=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId \
    --output text)

# Tabela de Roteamento das Subnets Privadas e os NATs das respectivas AZs
PRV_ROUTE_TABLE1=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId \
    --output text)

PRV_ROUTE_TABLE2=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId \
    --output text)

# Rota da Tabela Pública para a o Internet Gateway
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE1 \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

# Rota individual das Tabelas Privadas para o Nats Gateways da AZ respectiva
aws ec2 create-route --route-table-id $PRV_ROUTE_TABLE1 \
    --destination-cidr-block 0.0.0.0/0\
    --nat-gateway-id $NAT_GATEWAY_ID1\
    --region us-east-1

aws ec2 create-route --route-table-id $PRV_ROUTE_TABLE2 \
    --destination-cidr-block 0.0.0.0/0\
    --nat-gateway-id $NAT_GATEWAY_ID2\
    --region us-east-1
# importante !!! sempre que os Gateways IGW ou NAT são apagados, essas rotas precisam ser refeitas por conta do uso dos IDENTIFIERS únicos (--nat-gateway-id e --gateway-id)
~~~~

#### 3.2.1 - Nomeação das Tabelas de Roteamento
<details>
<summary>Nomes Das Tabelas</summary>

~~~~ bash
aws ec2 create-tags \
    --resources $ROUTE_TABLE1 \
    --tags Key=Name,Value=Public_route_table1 \
    --region us-east-1

aws ec2 create-tags \
    --resources $PRV_ROUTE_TABLE1 \
    --tags Key=Name,Value=Private_route_tableAZ1 \
    --region us-east-1

aws ec2 create-tags \
    --resources $PRV_ROUTE_TABLE2 \
    --tags Key=Name,Value=Private_route_tableAZ2 \
    --region us-east-1
~~~~ 

</details>

### 3.3 - Associação das Subnets das AZs pra Tabela especifica
Essa associação estará apontando a conexão para nossas subnets com seus Gateways 0.0.0.0/0 respectivos, NAT ou IGW dependendo do acesso da subnet.
~~~~ bash
# Associação das Subnets Públicas a Tabela de Roteamento Pública 
aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID_1 \
    --route-table-id $ROUTE_TABLE1

aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID_2 \
    --route-table-id $ROUTE_TABLE1

# Associação das Subnets Privadas AZ1 a Tabela de Roteamento Privada N° 1
aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID_3 \
    --route-table-id $PRV_ROUTE_TABLE1

aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID_5 \
    --route-table-id $PRV_ROUTE_TABLE1

# Associação das Subnets Privadas AZ2 a Tabela de Roteamento Privada N° 2
aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID_4 \
    --route-table-id $PRV_ROUTE_TABLE2

aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID_6 \
    --route-table-id $PRV_ROUTE_TABLE2
~~~~

### 4 Criação e Configuração dos Security Groups
Enquanto as Tabelas de Roteamento irão indicar as rotas de conexão entre subnets, os grupos de segurança irão definir as permmissões, portas e protocolos que irão ocorrer entre as subnets.

### 4.1 Security Group do CLB ( Classic Load Balancer)
Irá precisar de receber tráfico inbound do IGW pelas portas HTTP 80 e a porta HTTPS 443, servirá para receber o tráfico inbound da internet para os servidores HOST pelo load balancer.
~~~~ bash
CLB_SG_ID=$(aws ec2 create-security-group --group-name CLB-Security-Group --description "Load Balancer Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text )
aws ec2 authorize-security-group-ingress --group-id $CLB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $CLB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
~~~~

### 4.2 Security Group do SSH
Servirá para autorizar as conexões das Instâncias EC2, Bastion Host e facilitar o debugging do projeto.
~~~~ bash
SSH_SG_ID=$(aws ec2 create-security-group --group-name SSH-Security-Group --description "SSH Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text )

# idealmente utilizando apenas o IP público pessoal ou 0.0.0.0/0 no pior dos casos com menos segurança
MYIP=`curl -s <insira aqui seu site para query de IP>`

aws ec2 authorize-security-group-ingress --group-id $SSH_SG_ID --protocol tcp --port 22 --cidr $MYIP/32
~~~~


### 4.3 Security Group do Servidor Host
Irá precisar de receber tráfico HTTP e HTTPS inbound do load balancer para poder receber os requests externos da aplicação Wordpress. Ademais as conexões SSH para debugging.
~~~~ bash
WEBSERVER_SG_ID=$(aws ec2 create-security-group --group-name Webserver-Security-Group --description "Webserver Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text )

aws ec2 authorize-security-group-ingress --group-id $WEBSERVER_SG_ID --protocol tcp --port 80 --source-group $CLB_SG_ID

aws ec2 authorize-security-group-ingress --group-id $WEBSERVER_SG_ID --protocol tcp --port 22 --source-group $SSH_SG_ID
~~~~



### 4.4 Security Group do Base de Dados (MySql)
Irá precisar de receber pacotes do Servidor Host para guardar os dados da aplicação Wordpress. Pelo Port 3306, port padrão de databases do MySql
~~~~ bash
DB_SG_ID=$(aws ec2 create-security-group --group-name Database-Security-Group --description "Database Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $WEBSERVER_SG_ID
~~~~

### 4.5 Security Group do Elastic File System (EFS)
Irá precisar de receber os arquivos das instâncias EC2 e manter-se atualizado entre os pontos de montagem. 
~~~~ bash
EFS_SG_ID=$(aws ec2 create-security-group --group-name EFS-Security-Group --description "EFS Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text )
aws ec2 authorize-security-group-ingress --group-id $EFS_SG_ID --protocol tcp --port 2049 --source-group $WEBSERVER_SG_ID
aws ec2 authorize-security-group-ingress --group-id $EFS_SG_ID --protocol tcp --port 22 --source-group $SSH_SG_ID
~~~~



<details>
<summary>Tags dos Security Groups</summary>

~~~~~~ bash
aws ec2 create-tags --resources $CLB_SG_ID --tags Key=Name,Value=CLB-Security-Group Key=Projeto,Value=WPSTACK 

aws ec2 create-tags --resources $DB_SG_ID --tags Key=Name,Value=Database-Security-Group Key=Projeto,Value=WPSTACK

aws ec2 create-tags --resources $SSH_SG_ID --tags Key=Name,Value=SSH-Security-Group Key=Projeto,Value=WPSTACK 

aws ec2 create-tags --resources $WEBSERVER_SG_ID --tags Key=Name,Value=Webserver-Security-Group Key=Projeto,Value=WPSTACK 

aws ec2 create-tags --resources $EFS_SG_ID --tags Key=Name,Value=EFS-Security-Group Key=Projeto,Value=WPSTACK 
~~~~~~
</details>


### 5 Criação da Instância de Dados ( RDS )
A instância RDS estará servindo como base de dados da aplicação wordpress, para que isso aconteça ela precisará estar configurada em acordo com a aplicação wordpress - nesse caso sendo utilizada o banco MySQL. Dentro desse projeto, não foi necessária a criação de um banco de dados em standby para aumentar a disponibilidade, assim, foi utilizado a configuração de instância única ao invez da MultiAZ.
Primeiramente, é necessário definir um Subnet Group pro RDS, onde serão definidas as subnets ( usualmente privadas ) onde funcionará as instãncias RDS, cluster ou única.

~~~~ bash
# O identifier do RDS Subnet Group é o próprio nome e pode ser definido da seguinte maneira:
RDS_SUBNET_GROUP_NAME="rds_cl_wpstack"

# Definição das Subnets privadas especificas para os Bancos
RDS_SUBNET_GID=$(aws rds create-db-subnet-group \
    --db-subnet-group-name $RDS_SUBNET_GROUP_NAME \
    --db-subnet-group-description "Subnet group para RDS em duas AZs" \
    --subnet-ids $SUBNET_ID_5 $SUBNET_ID_6)
RDS_SUBNET_GROUP_NAME="rds_cl_wpstack"

#Variáveis Genêricas para o projeto 
DB_IDENTIFIER="dbwpstack"
DB_USERNAME="bob23"
DB_PASSWORD="abcd1234"
~~~~ 


### 5.1 Criação da Instância de Dados ( RDS )
Foram definidas as opções especificas de acordo a imagem docker utilizada do wordpress de maneira a evitar conflitos no versionamento. Foi buscado também utilizar as configurações mais simples e baixo custo para criação do banco. 

~~~ bash
RDS_INSTANCE_ID=$(aws rds create-db-instance \
    --db-instance-identifier $DB_IDENTIFIER \
    --engine mysql \
    --engine-version 8.0.39 \
    --db-instance-class db.t3.micro \
	--allocated-storage 20 \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --db-subnet-group-name $RDS_SUBNET_GROUP_NAME \
    --vpc-security-group-ids $DB_SG_ID \
    --db-name wordpressdb \
    --no-publicly-accessible \
    --tags Key=Name,Value="Nome Compass" Key=CostCenter,Value="Definido Compass" Key=Project,Value="Definido Compass" \
    --query 'DBInstances[0].DBInstanceIdentifier' \
    --output text)

# Além da SUbnet privada a Opção no-publicly-accessible também foi utilizada para garantir o isolamento do banco
# --multi-az option para cluster de RDS
# Desativa Backups
aws rds modify-db-instance --db-instance-identifier $RDS_INSTANCE_ID --backup-retention-period 0 
# Como buscou-se inicialmente um setup limpo e de menos custo, os backups foram desligados
~~~




### 6 Criação da Instância de Arquivos - Elastic File System ( EFS )
Vamos estar criando uma instância de arquivos EFS e montando ela em duas Subnets Privadas para aumentar a disponibilidade.
~~~ bash
# Criação do EFS com componentes básicos
aws efs create-file-system \
    --creation-token "efs-wpstack" \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --no-encrypted \
    --tags Key=Name,Value="efs-wpstack"

# Query Separada para receber o Identifier do EFS
EFS_ID=$(aws efs describe-file-systems --query "FileSystems[?Name=='efs-wpstack'].FileSystemId" --output text)
echo "EFS ID: $EFS_ID"

# Mount Target na Subnet da Base de Dados AZ1
aws efs create-mount-target \
        --file-system-id $EFS_ID \
        --subnet-id $SUBNET_ID_5 \
        --security-groups $EFS_SG_ID 

# Mount Target na Subnet da Base de Dados AZ2
aws efs create-mount-target \
        --file-system-id $EFS_ID \
        --subnet-id $SUBNET_ID_6 \
        --security-groups $EFS_SG_ID 

~~~

### 7 Criação do User_data.sh
Nessa etapa as variáveis necessárias já foram criadas para criar uma instância inicial para debugging ou avançar a criação da Stack do projeto

Considerando a dinâmica de valores e automações, foi feito um comando gerativo do User_data.sh utilizando heredoc padrão do shell Bash. Mais a frente o user_data.sh será usado para criação do launch_template do Auto Scaling group (ASG) com Classic Load Balancer (CLB).

### 7.1 Script User_data.sh
A Rotina do script user_data inicia-se ao atualizar os pacotes e repo cache do Amazon Linux 2023 da instância, após isso é instalado o programa docker para utilização da imagem para conteiner do Wordpress e as respectivas permissões de usuário docker. Após isso, é instalado o docker-compose do reposítório github para utilização do dockerfile pré-configurado.

Junto a isso, o sistema de arquivos da instância EFS é montado a pasta /EFS onde serão colocados a pasta wordpress-docker com o dockerfile e a pasta de arquivos wordpress-files onde será armazenada os arquivos estáticos utilizados para o funcionamento do container. Ao final, o comando "docker-compose up -d" é rodado para dar início ao funcionamento do Wordpress.

<details>
<summary>Comando para Geração do User_data.sh</summary>

~~~ bash
# Queries para garantir que as nossas variáveis foram salvas durante o processo inicial
RDS_HOST_ADDR=$(aws rds describe-db-instances \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --query "DBInstances[*].Endpoint.Address" \
    --output text)

EFS_ID=$(aws efs describe-file-systems \
    --query "FileSystems[?Name=='efs-wpstack'].FileSystemId" \
    --output text)
# Variáveis estáticas da Database
DB_IDENTIFIER="dbwpstack"
DB_USERNAME="bob23"
DB_PASSWORD="abcd1234"
# DB_NAME = wordpressdb (Não esquecer de utilizar a opção adicional para já incluir uma database no RDS)

# Comando Heredoc
cat <<-EOF > ./user_data.sh
#!/bin/bash

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

EOF
~~~

</details>


### 8 Instâncias de Debugging
Foi criada uma instância na Subnet Pública AZ1 para setup inicial dos arquivos da aplicação Wordpress e debug das configurações das instâncias. Ademais, foi utilizado query sobre a resposta json da AWS para definir a variável EC2_INSTANCE_PAZ1_ID que será utilizada para o encerramento e "clean-up" após o termino do propósito do projeto.

Essa instância foi utilizada com a imagem mais recente do Amazon Linux 2023, Security Groups do Load Balancer (tráfico HTTP e HTTPs), SSH (conexão remota) e Web Server ( Porta 80 HTTP). O Script user_data foi feito parse direto da maquina local sem codificação com base64, haja vista que o próprio AWS CLI faz essa conversão.

~~~ bash
# Instância da Subnet Pública na AZ1, utilizada para testar  a infraestrutura em primeiro momento, ademais acessar as instâncias privadas como um Bastion Host.
EC2_INSTANCE_PAZ1_ID=$(aws ec2 run-instances \
    --image-id ami-0453ec754f44f9a4a \
    --instance-type t2.micro \
    --key-name chave-sp2 \
    --security-group-ids $CLB_SG_ID $SSH_SG_ID $WEBSERVER_SG_ID \
    --subnet-id $SUBNET_ID_1 \
    --count 1 \
    --user-data file://user_data.sh \
	--region us-east-1 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name, Value=Compasso}, {Key=CostCenter, Value=Compasso}, {Key=Project, Value=Compasso}]' 'ResourceType=volume,Tags=[{Key=Name, Value=Compasso},{Key=CostCenter, Value=Compasso}, 	{Key=Project, Value=Compasso}]' \
    --query "Instances[0].InstanceId" \
    --output text)
~~~

### 8.1 Funcionamento do Wordpress
Após a confirmação da serviço do wordpress, foi feita a configuração do usuário admin e senha, e confirmação do funcionamento do site, ademais a configuração do DNS automãtico do load balancer como URL do site Wordpress. Haja vista que isso será utilizado para confirmação do funcionamento do load balancer (CLB) junto às instâncias privadas ou com o Auto Scaling.


### 9 Criação do Load Balancer
Confirmados os funcionamentos da configuração do Wordpress e a rede da infraestrutura, a integração do banco de dados e a instância. O próximo passo é a configuração do load balancer, no proposta o clássico CLB:

~~~ bash
# Cria-se uma variável estática Load balancer name, pois o nome já serve como Identifier do serviço. 
LOAD_BALANCER_NAME1=lb-classico1

# Trabalhando por enquanto com HTTP, ele se encontrando conectado às subnets públicas estará recebendo do IGW atráves da porta 80 e balanceando para as Subnets Privadas AZ1 e AZ2 
aws elb create-load-balancer \
    --load-balancer-name $LOAD_BALANCER_NAME1 \
    --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 \
    --security-groups $CLB_SG_ID \
    --subnets $SUBNET_ID_1 $SUBNET_ID_2 \
    --output text

# Checkagem do Backend do nosso Host, é adicionado separadamente como opção do CLB
aws elb configure-health-check \
  --load-balancer-name $LOAD_BALANCER_NAME1 \
  --health-check "Target=HTTP:80/,Interval=30,Timeout=5,UnhealthyThreshold=2,HealthyThreshold=5"
~~~

### 9.2 Teste Manual com Instãncias Privadas para Debugging do CLB
São Subidas duas instâncias Privadas sem IP público nas Subnets Privadas
para testar o funcionamento do load balancer associado as Subnets Privadas. Essas instâncias utilizam o mesmo leque de options da primeira instância ademais user_data contudo utilizando o option "--placement" para garantir que essas instâncias manuais estejam em suas devidas subnets. 

<details>
<summary>Criação Manual das Instâncias Privadas</summary>

~~~ bash
# Essas instâncias também foram feitas com definição de variável já para facilitar a limpeza e destruição dessas instãncias para minimizar o custo do projeto
EC2_INSTANCE_PRIV1_ID=$(aws ec2 run-instances \
    --image-id ami-0453ec754f44f9a4a \
    --instance-type t2.micro \
    --key-name chave-sp2 \
    --security-group-ids $SSH_SG_ID $WEBSERVER_SG_ID \
    --subnet-id $SUBNET_ID_3 \
    --placement "AvailabilityZone=us-east-1a" \
    --count 1 \
    --user-data file://user_data.sh \
	--region us-east-1 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name, Value=Compasso}, {Key=CostCenter, Value=Compasso}, {Key=Project, Value=Compasso}]' 'ResourceType=volume,Tags=[{Key=Name, Value=Compasso},{Key=CostCenter, Value=Compasso}, 	{Key=Project, Value=Compasso}]' \
    --query "Instances[0].InstanceId" \
    --output text)

EC2_INSTANCE_PRIV2_ID=$(aws ec2 run-instances \
    --image-id ami-0453ec754f44f9a4a \
    --instance-type t2.micro \
    --key-name chave-sp2 \
    --security-group-ids $SSH_SG_ID $WEBSERVER_SG_ID \
    --subnet-id $SUBNET_ID_4 \
    --placement "AvailabilityZone=us-east-1b" \
    --count 1 \
    --user-data file://user_data.sh \
	--region us-east-1 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name, Value=Compasso}, {Key=CostCenter, Value=Compasso}, {Key=Project, Value=Compasso}]' 'ResourceType=volume,Tags=[{Key=Name, Value=Compasso},{Key=CostCenter, Value=Compasso}, 	{Key=Project, Value=Compasso}]' \
    --query "Instances[0].InstanceId" \
    --output text)
~~~ 
</details>

~~~ bash
# Comando Para Associar o Load Balancer CLB às Instâncias Privadas Manualmente
aws elb register-instances-with-load-balancer \
    --load-balancer-name $LOAD_BALANCER_NAME1 \
    --instances $EC2_INSTANCE_PRIV1_ID $EC2_INSTANCE_PRIV2_ID
~~~

### 9.3 Clean-up Pré Auto-Scaling
Após confirmação do funcionamento do Load Balancer CLB, já podemos fechar as instâncias de teste e prosseguir para criação do Auto Scaling Template e Auto Scaling Group
~~~ bash
## Após Confirmação do Load Balancer Encessar Instancias teste
aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_PAZ1_ID
aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_PRIV1_ID
aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_PRIV2_ID
~~~



### 10 Criação do Auto Scaling Group
O Auto Scaling Group é uma das soluções que servem para manutenir a quantidade e bom funcionamento do serviço provido pelas Instãncias do AWS. Cobrindo o escalamento horizontal de serviços na núvem. Valendo apontar como  é possível definir o número minímo de maquinas na núvem, o que será feito em caso de low-traffic e ou alta utilização do recursos como CPU da maquina.

Para implementação desse serviço é criado um Auto Scaling Template que aponta como ficarão configuradas as maquinas EC2, havendo um cuidado com a formatação e manutenção das opções trabalhadas no perfil de maquina alvo.

<details>
<summary>Criação do Auto Scaling Template das EC2 com User_data</summary>

~~~ bash
# Vale apontar que o Identificador do Load Balancer CLB é apenas o seu nome, aproveitando assim para definir uma variável estática do projeto
LOAD_BALANCER_ID=lb-classico1

# Caso o Projeto ocorra novamente, esse template será apagado e refeito com os Parámetros novos de EFS e RDS IDs
aws ec2 delete-launch-template --launch-template-name WP_LAUNCH_TEMPLATE1

# Aqui foi utilizado o formato json diretamente pela linha de comando e com codificação base64 do arquivo user data, que nesse caso não ocorre a codificação pelo AWS CLI
aws ec2 create-launch-template \
--launch-template-name WP_LAUNCH_TEMPLATE1 \
--version-description v1 \
--launch-template-data '{
    "InstanceType": "t2.micro",
    "ImageId": "ami-0453ec754f44f9a4a",
    "KeyName": "chave-sp2",
    "SecurityGroupIds": ["'$SSH_SG_ID'", "'$WEBSERVER_SG_ID'"],
    "UserData": "'$(base64 -w 0 user_data.sh)'",
    "TagSpecifications": [
      {
        "ResourceType": "instance",
        "Tags": [
            {"Key": "Name", "Value": "compasso"},
            {"Key": "CostCenter", "Value": "compasso"},
            {"Key": "Project", "Value": "compasso"}
        ]
      },
      {
        "ResourceType": "volume",
        "Tags": [
            {"Key": "Name", "Value": "compasso"},
            {"Key": "CostCenter", "Value": "compasso"},
            {"Key": "Project", "Value": "compasso"}
        ]
      }
    ]
}'
# Não sendo essa a única forma de estar fazendo o request.
# Valendo lembrar que as Tags inclusas possuem valores separados exigidos para acompanhar o funcionamento das instâncias do tipo EC2
~~~

</details>



### 10.1 O Auto Scaling Group
Aqui serão definidos os Health Checks, parâmetros de escalamento, template e subnets. Todos já previamente definidos e testados para funcionamento com as maquinas privadas nas SUbnets escolhidas

O Auto Scaling do projeto, ficou definido com minimamente duas maquinas, escalamento após 50% de uso do CPU da maquina e os health checks padrões. Mantidos também os Grace Periods.

E por fim são associados o Load Balancer com o Auto Scaling Group Separadamente, concluindo a stack wordpress com 3 tier aws architecture e fechando o projeto até o momento da limpeza dos recursos.

~~~ bash
# Como o Identifier é um nome fixo para o projeto já fica definida mais uma variável estática.
Auto_scaling_NAME1=lb-classico1

# Auto Scaling para criar as Maquinas com nome HOST_SERVER_WP
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name WP_ALG1 \
    --launch-template "LaunchTemplateName=WP_LAUNCH_TEMPLATE1,Version=1" \
    --min-size 2 \
    --max-size 4 \
    --desired-capacity 2 \
    --vpc-zone-identifier "$SUBNET_ID_3,$SUBNET_ID_4" \
    --health-check-type EC2 \
    --health-check-grace-period 300 \
    --availability-zones us-east-1a us-east-1b \
    --tags Key=Name,Value=HOST_SERVER_WP,PropagateAtLaunch=true

# Ativação de Métricas básicas separadas
aws autoscaling enable-metrics-collection \
  --auto-scaling-group-name WP_ALG1 \
  --granularity "1Minute" \
  --metrics "GroupMinSize" "GroupMaxSize" "GroupDesiredCapacity" "GroupInServiceInstances" "GroupPendingInstances" "GroupStandbyInstances" "GroupTerminatingInstances"

# Política de expansão baseada na utilização do CPU
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name WP_ALG1 \
    --policy-name cpu-utilization-scaling-policy \
    --scaling-adjustment 1 \
    --adjustment-type ChangeInCapacity \
    --cooldown 300 \
    --metric-aggregation-type Average \
    --target-tracking-configuration '{
        "TargetValue": 50.0,
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ASGAverageCPUUtilization"
        },
        "EstimatedInstanceWarmup": 300
    }'

# Adição e conclusão da Stack com o Load Balancer associando ao Auto Scaling Group
aws autoscaling attach-load-balancers --auto-scaling-group-name WP_ALG1 --load-balancer-names lb-classico1
# Health check da conexão periodica das instâncias pelo CLB
aws autoscaling update-auto-scaling-group   --auto-scaling-group-name WP_ALG1   --health-check-type ELB   --health-check-grace-period 300
~~~


# Conclusões Finais e Agradecimentos

