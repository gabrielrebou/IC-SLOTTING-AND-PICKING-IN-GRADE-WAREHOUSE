#!/usr/bin/env bash

echo -ne "\033]0;Executando main.jl\007"

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Iniciando execucao de main.jl...${NC}"

# Entra na pasta onde o script está
cd "$(dirname "$0")"

# Executa o arquivo Julia
julia src/main.jl
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\n[ERRO] O script main.jl terminou com erro (Codigo: $EXIT_CODE).${NC}"
else
    echo -e "${GREEN}\n[SUCESSO] Script finalizado com sucesso.${NC}"
fi

echo -e "${YELLOW}\nPressione Enter para fechar esta janela...${NC}"
read -r