## Métodos de Implementação

| Método de Implantação | Descrição | Link para Repositório |
|----------------------|-----------|----------------------|
| Implementação Manual | Configuração passo a passo com script de instalação e configuração manual | [/setup-manual](./setup_manual) |




# Implantação de WordPress LAMP STACK Visando Melhores Práticas da AWS

## Introdução

Este repositório busca documentar de forma abrangente para a implementação de uma aplicação WordPress usando arquitetura de contêineres na AWS, com foco em segurança, escalabilidade e alta disponibilidade ou seja - as Melhores Práticas de implementação Cloud por AWS. O projeto buscará implementar essas práticas recomendadas de implantação em nuvem, utilizando serviços gerenciados da AWS como EC2, RDS, EFS e Load Balancer.

## Objetivos do Projeto

O objetivo principal é criar uma infraestrutura robusta e segura para hospedagem de WordPress, eliminando pontos únicos de falha e garantindo desempenho e acessibilidade consistentes.

## Escopo da Implantação

### 1. Instalação de Docker/Containerd
Preparar instância EC2 e criar User Data script para instalação de Docker/Containerd.
- Instalar Docker ou Containerd
- Configurar serviço Docker
- Habilitar inicialização automática do Docker

### 2. Implantação da Aplicação WordPress
Fase de preparação do contêiner e configuração do banco de dados:
- Escolher abordagem com Dockerfile ou Docker Compose
- Configurar contêiner WordPress
- Criar instância MySQL RDS
- Configurar credenciais do banco de dados
- Garantir conexão segura com o banco de dados

### 3. Configuração do AWS EFS
Implementação do sistema de arquivos persistente:
- Criar sistema de arquivos EFS
- Configurar grupos de segurança para EFS
- Montar EFS no contêiner WordPress
- Armazenar arquivos estáticos e uploads do WordPress
- Garantir armazenamento persistente para arquivos de mídia

### 4. Configuração do Balanceador de Carga
Estabelecer distribuição de tráfego e alta disponibilidade:
- Criar Balanceador de Carga AWS
- Configurar definições sem exposição de IP público
- Rotear tráfego da internet através do balanceador de carga
- Configurar grupos de destino
- Implementar verificações de integridade

## Verificações Adicionais de Validação
Garantir o funcionamento correto da infraestrutura:
- Verificar tela de login do WordPress
- Testar acessibilidade da aplicação
- Confirmar ausência de exposição de IP público
- Validar armazenamento de arquivos no EFS
- Verificar funcionalidade do balanceador de carga

## Próximos Passos Recomendados
Documentação e preparação:
- Documentar todo o processo de configuração
- Criar capturas de tela da implantação
- Preparar materiais de apresentação

## Desafios Potenciais a Serem Abordados
Pontos críticos de atenção:
- Proteger credenciais do banco de dados
- Gerenciar rede de contêineres
- Garantir alta disponibilidade
- Lidar com armazenamento persistente
