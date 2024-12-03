### DETALHAMENTO DAS ETAPAS E BOAS PRÁTICAS


<details>
<summary>Fase de Preparação</summary>

### SETUP BÁSICO
- Verificar acesso e permissões da conta AWS
- Gerenciar credenciais de usuário IAM
- Proteger pares de chaves SSH
- Selecionar região AWS apropriada
- Revisar cotas de serviço e configurações de rede

### REVISÃO
- Garantir políticas compatível de usuário e roles IAM
- Documentar requisitos de rede
- Validar configurações de VPC e sub-redes
</details>

<details>
<summary>Configuração de Redes: VPC e Sub-redes</summary>

### Princípios de Design de Rede
- Alta disponibilidade
- Segmentação de segurança
- Flexibilidade de arquitetura
- Isolamento de componentes

### Topologia de Rede Recomendada
- VPC com 3 zonas de disponibilidade
- Sub-redes públicas e privadas
- Roteamento controlado
- NAT Gateways para comunicação externa

### Detalhamento das Sub-redes

#### Sub-redes Públicas
- CIDR: 10.0.1.0/24
- Hospeda:
  - Balanceador de Carga
  - Bastion Host
  - Recursos com acesso direto à internet

#### Sub-redes Privadas
- CIDR: 10.0.2.0/24 e 10.0.3.0/24
- Hospeda:
  - Instâncias EC2
  - Contêineres WordPress
  - Banco de dados RDS
  - Sem acesso direto à internet

### Configurações de Segurança de Rede

#### Grupos de Segurança
- Regras de entrada mínimas
- Princípio do menor privilégio
- Segmentação por função

#### Network ACLs
- Camada adicional de segurança
- Regras explicitas de entrada e saída
- Auditoria de tráfego de rede

### Estratégias de Roteamento
- Tabela de Roteamento Personalizada
- Internet Gateway para sub-redes públicas
- NAT Gateway para sub-redes privadas
- Controle de fluxo de tráfego

### Considerações de Alta Disponibilidade
- Distribuir recursos entre zonas
- Configurar failover automático
- Balanceamento de carga entre zonas

### Monitoramento e Otimização
- AWS VPC Flow Logs
- CloudWatch Metrics
- Análise de tráfego
- Ajuste periódico de configurações

### Custos e Performance
- Avaliar necessidade de NAT Gateways
- Dimensionar corretamente os recursos
- Usar reserved instances
- Implementar tag de gerenciamento de custos
</details>







<details>
<summary>Configuração da Instância EC2</summary>

## Visão Geral
Configurar a infraestrutura computacional primária para hospedar WordPress usando Amazon EC2, com foco na seleção do tipo de instância correto e configuração de definições de rede.

### Especificações da Instância
- AMI: Amazon Linux 2
- Tipo de Instância: t2.micro (adequado para testes/cargas pequenas)
- Configuração de Rede:
  - VPC padrão
  - Atribuição de IP público
  - Regras de grupo de segurança robustas

### Considerações de Segurança
- Implementar configurações de grupo de segurança rigorosas
- Permitir apenas portas necessárias:
  - SSH (22)
  - HTTP (80)
  - HTTPS (443)
</details>

<details>
<summary>Configuração do Banco de Dados</summary>

## Visão Geral
Estabelecer um banco de dados MySQL robusto e seguro usando Amazon RDS para armazenamento de dados da aplicação WordPress.

### Configuração do RDS
- Mecanismo de Banco de Dados: MySQL
- Segurança: 
  - SUBREDE PRIVADA
  - Grupo de segurança restrito
  - Criptografia em repouso

### Configurações Recomendadas
- Habilitar backups automatizados
- Configurar janelas de manutenção
- Configurar insights de desempenho
</details>

<details>
<summary>Configuração do WordPress e Docker</summary>

## Visão Geral
Conteinerizar WordPress usando Docker e estabelecer mecanismos de armazenamento persistente com Amazon EFS.

### Composição Docker
- Usar docker-compose para implantação simplificada
- Configurar variáveis de ambiente
- Mapear volumes para persistência de dados
- Gerenciar contêineres do WordPress e banco de dados

### Sistema de Arquivos Elástico (EFS)
- Criar sistema de arquivos dedicado
- Proteger com grupos de segurança apropriados
- Montar na instância EC2 ( exemplo com comando Mount de sistema linux )
- Armazenar mídia e conteúdo estático do WordPress

### Práticas Recomendadas
- Usar imagens oficiais do Docker para WordPress e MySQL
- Implementar builds de múltiplos estágios
- Usar arquivos .env para configuração
</details>

<details>
<summary>Balanceador de Carga e Rede</summary>

## Visão Geral
Implementar Balanceador de Carga da AWS para distribuir tráfego de entrada e aumentar a disponibilidade da aplicação.

### Configuração do Balanceador de Carga
- Portas de Listener: HTTP/HTTPS
- Configurações de Verificação de Integridade
- Grupo de Destino de Instância

### Considerações de Rede
- Sem exposição direta de IP público
- Tráfego roteado através do balanceador de carga
- Balanceamento de carga entre zonas


### Recomendações Arquiteturais
- Considerar migração para Balanceador de Carga de Aplicação
- Implementar terminação SSL/TLS ( Para proteger contra Spoofing da API )
- Configurar verificações de integridade abrangentes
</details>

<details>
<summary>Implantação do WordPress</summary>

## Visão Geral
Estágio final de implantação e verificação da aplicação WordPress na infraestrutura preparada.

### Etapas de Implantação
- Baixar imagem oficial do Docker do WordPress
- Iniciar serviços em contêineres
- Concluir configuração inicial do WordPress
- Verificar acessibilidade do site

### Procedimentos de Validação
- Testar login do WordPress
- Verificar armazenamento de arquivos estáticos
- Confirmar roteamento do balanceador de carga
- Validar configurações de segurança


### Recomendações Pós-Implantação
- Instalar plugins essenciais de segurança
- Configurar backups regulares
- Configurar monitoramento e alertas
</details>

<details>
<summary>Verificação do Sistema e Limpeza para Ambiente de Teste</summary>

## Visão Geral
Verificação geral, desfocada e com amplitude, do sistema e preparação para possível desmontagem da infraestrutura.

### Lista de Verificação
- Confirmar todos os componentes do sistema
- Testar fluxo de trabalho completo da aplicação
- Revisar regras de grupos de segurança
- Validar configurações de recursos

### Procedimento de Limpeza
- Documentar recursos implantados
- Preparar scripts de encerramento
- Identificar recursos para possível exclusão

### Gestão de Custos
- Parar serviços desnecessários
- Usar AWS Cost Explorer
- Configurar alertas de faturamento
</details>
