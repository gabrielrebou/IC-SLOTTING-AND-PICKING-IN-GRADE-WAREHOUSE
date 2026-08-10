#!/usr/bin/env bash

# Define o título da janela do terminal (funciona na maioria dos emuladores de terminal)
echo -ne "\033]0;Executando main.jl\007"

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}Iniciando execucao de main.jl...${NC}"
echo -e "${CYAN}Caso trave em algum processo, pressione Enter para continuar...${NC}"

# Entra na pasta onde o script está, para garantir que main.jl seja encontrado
cd "$(dirname "$0")"

# Executa o arquivo Julia
julia main.jl
EXIT_CODE=$?

# Verifica se houve erro na execução
if [ $EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\n[ERRO] O script main.jl terminou com erro (Código: $EXIT_CODE).${NC}"
else
    echo -e "${GREEN}\n[SUCESSO] Script finalizado com sucesso.${NC}"
fi

# Mantém o terminal aberto
echo -e "${YELLOW}\nPressione Enter para fechar esta janela...${NC}"
read -r