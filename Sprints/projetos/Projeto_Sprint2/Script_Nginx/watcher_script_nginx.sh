#!/bin/bash

# Diretório de saí:
OUTPUT_DIR="./log_folder"

# Nome do serviço
SERVICE_NAME="nginx"

# Função para obter a data e hora atual
get_datetime() {
    date "+%d-%m-%Y %H:%M:%S"
}

# Verifica se o serviço Nginx está em execução
if systemctl is-active --quiet $SERVICE_NAME; then
    STATUS="ONLINE"
    MESSAGE="O serviço Nginx está funcionando normalmente."
    OUTPUT_FILE="$OUTPUT_DIR/online_logs/${SERVICE_NAME}_online.log"
else
    STATUS="OFFLINE"
    MESSAGE="O serviço Nginx está parado ou com problemas."
    OUTPUT_FILE="$OUTPUT_DIR/offline_logs/${SERVICE_NAME}_offline.log"
fi

# Cria a mensagem de saída
OUTPUT="
Data_hora: $(get_datetime)
Servi�o: $SERVICE_NAME
Status_servi�o: $STATUS
Mensagem_output: $MESSAGE"

# Escreve a saída no arquivo apropriado
echo "$OUTPUT" >> "$OUTPUT_FILE"

# Exibe a mensagem no console (opcional)
echo "$OUTPUT"
