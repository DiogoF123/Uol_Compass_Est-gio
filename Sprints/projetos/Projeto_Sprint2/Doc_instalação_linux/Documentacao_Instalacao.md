## Documentação Projeto Sprint 1 - Grupo 5:
### I) Instalação de WSL Ubuntu no Windows
<details>
O WSL é um Subsistema do Windows que disponibiliza
um ambiente Linux compatível com o sistema da Microsoft.
Existem duas versões, o WSL 1 e o WSL 2, onde a segunda aumenta o desempenho
do sistema de arquivos e é a versão padrão atual para instalar uma distribuição Linux
no Windows.
- Clique no botão do Windows, digite Powershell e execute o programa. Você deve ver
uma interface de linha de comando.
- Primeiro vamos ver as versões disponíveis. Digite wsl --list --online e aperte enter.
Vai aparecer uma lista das distribuições Linux na loja online.
- Queremos uma versão do Ubuntu superior ao 20.04, como requisitado na atividade..
Digite e execute wsl --install Ubuntu-22.04 ou a versão desejada.
</details>
### II) Instalação de Sistema Linux: utilizando instalador de distro ubuntu
<details>
1. Preparação
   
1.1. Cheque se o sistema é Legacy BIOS ou UEFI

1.2. Faça o download da imagem ISO do Ubuntu no site oficial
(https://ubuntu.com/download/desktop).

1.3. Crie um dispositivo de instalação bootável (USB ou DVD).

1.4. Faça backup dos seus dados importantes.

2. Inicialização
   
2.1. Insira o dispositivo de instalação no computador.

2.2. Reinicie o computador e entre na BIOS para configurar a ordem de boot.

2.3. Inicie o computador a partir do dispositivo de instalação.

3. Configuração com o Instalador
   
3.1. Selecione o idioma desejado.

3.2. Escolha "Instalar Ubuntu".

3.3. Selecione o layout do teclado - alguns teclados sem ç usam US já a maioria usa ABNT2

3.4. Escolha entre instalação normal ou mínima.

3.5. Decida sobre atualizações e softwares de terceiros.

4. Particionamento
4.1 Escolha entre:
- Instalar ao lado do sistema existente (dual boot).
- Apagar o disco e usar Ubuntu.
- Particionamento manual - opção mais avançada para maior controle do sistema.

5. Configuração Básica do Sistema
   
5.1. Defina seu fuso horário. - usualmente São Paulo (UTC -3)
   
5.2. Crie uma conta de usuário e senha


6. Instalação
   
6.1. O sistema copiará os arquivos e instalará o Ubuntu.

6.1. Reinicie o computador quando solicitado.

7. Pós-instalação
   
7.1. Faça login com sua conta.

7.2. Execute atualizações do sistema - usualmente com apt update && apt upgrade com os mirrors pré-selecionados.

7.3. Instale drivers adicionais, se necessário.
7.4. Personalize seu ambiente de trabalho.
</details>
