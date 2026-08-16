#!/usr/bin/env bash

# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}   VERIFICADOR E INSTALADOR DE AMBIENTE JULIA     ${NC}"
echo -e "${CYAN}==================================================${NC}"

# 1. Verificar Julia (via juliaup)
echo -e "${YELLOW}[1/3] Verificando se o Julia está instalado...${NC}"

if ! command -v juliaup &> /dev/null; then
    echo -e "${YELLOW}juliaup não encontrado. Instalando...${NC}"
    curl -fsSL https://install.julialang.org | sh -s -- --yes

    # Carrega o juliaup/julia no PATH da sessão atual sem precisar reabrir o terminal
    if [ -f "$HOME/.juliaup/bin/env" ]; then
        source "$HOME/.juliaup/bin/env"
    fi
    export PATH="$HOME/.juliaup/bin:$PATH"

    if ! command -v juliaup &> /dev/null; then
        echo -e "${RED}[ERRO] A instalação do juliaup falhou.${NC}"
        read -p "Pressione Enter para sair..."
        exit 1
    fi
    echo -e "${GREEN}juliaup instalado com sucesso!${NC}"
else
    echo -e "${GREEN}juliaup já está instalado!${NC}"
fi

if ! command -v julia &> /dev/null; then
    echo -e "${YELLOW}Julia não encontrado. Instalando versão release via juliaup...${NC}"
    juliaup add release
    juliaup default release
else
    echo -e "${GREEN}Julia já está instalado!${NC}"
fi

# 2. Verificar e Instalar Bibliotecas
echo -e "${YELLOW}[2/3] Verificando e instalando pacotes necessários...${NC}"

cat > setup_temp.jl << 'EOF'
using Pkg
packages = ["Plots", "Graphs", "HiGHS", "JuMP", "Clustering", "CSV"]
to_install = String[]

for pkg in packages
    if Base.find_package(pkg) === nothing
        println("  [!] $pkg não encontrado. Adicionando à fila...")
        push!(to_install, pkg)
    else
        println("  [OK] $pkg já instalado.")
    end
end

if !isempty(to_install)
    println("  Instalando pacotes pendentes...")
    Pkg.add(to_install)
else
    println("  Todos os pacotes externos já estão instalados.")
end
EOF

julia setup_temp.jl
SETUP_EXIT_CODE=$?
rm -f setup_temp.jl

if [ $SETUP_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}[ERRO] Falha ao instalar os pacotes.${NC}"
    read -p "Pressione Enter para sair..."
    exit 1
fi

# 3. Validação Final
echo -e "${YELLOW}[3/3] Validação final de importação...${NC}"

cat > val_temp.jl << 'EOF'
libs = ["LinearAlgebra", "Statistics", "Plots", "Graphs", "HiGHS", "JuMP", "SparseArrays", "Random", "Clustering", "CSV"]
all_ok = true
for lib in libs
    try
        eval(Meta.parse("using $lib"))
        println("  [SUCESSO] $lib carregado.")
    catch e
        println("  [ERRO] $lib falhou: $e")
        global all_ok = false
    end
end
exit(all_ok ? 0 : 1)
EOF

julia val_temp.jl
VAL_EXIT_CODE=$?
rm -f val_temp.jl

if [ $VAL_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN} [SUCESSO] TUDO INSTALADO E VERIFICADO CORRETAMENTE! ${NC}"
    echo -e "${GREEN}==================================================${NC}"
else
    echo -e "${RED}[ERRO] Houve problemas na validação final das bibliotecas.${NC}"
fi

read -p "Pressione Enter para fechar o programa..."