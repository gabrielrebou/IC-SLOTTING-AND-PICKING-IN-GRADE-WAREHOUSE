#!/usr/bin/env bash

# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if ! command -v julia &> /dev/null; then
    echo -e "${RED}[ERRO] Julia não está instalado.${NC}"
    echo -e "${YELLOW}Instale Julia antes de executar este script:${NC}"
    echo "https://julialang.org/downloads/"
    read -p "Pressione Enter para sair..."
    exit 1
fi

# 2. Verificar e Instalar Bibliotecas
echo -e "${YELLOW}[2/3] Verificando e instalando pacotes necessários...${NC}"

cat > setup_temp.jl << 'EOF'
using Pkg
packages = ["Plots", "Graphs", "HiGHS", "JuMP", "Clustering", "CSV", "DataFrames", "StatsPlots"]
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
libs = ["LinearAlgebra", "Statistics", "Plots", "Graphs", "HiGHS", "JuMP", "SparseArrays", "Random", "Clustering", "CSV", "DataFrames", "StatsPlots"]
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
    echo -e "${GREEN} [SUCESSO] TUDO INSTALADO E VERIFICADO CORRETAMENTE! ${NC}"
else
    echo -e "${RED}[ERRO] Houve problemas na validação final das bibliotecas.${NC}"
fi

read -p "Pressione Enter para fechar o programa..."