
Para instalar no Linux use esses dois comandos
chmod +x packages_linux.sh
./packages_linux.sh

Para rodar em Linux use esses dois comandos
chmod +x start_linux.sh
./start_linux.sh

#__________________________________________________________________________________________________________________
# observaçôes:
o ALS não precisa substituir um algoritmo de otimização.
Ele pode gerar uma função objetivo "inteligente",
aprendida a partir dos dados, enquanto o MILP ou uma
heurística garantem que todas as restrições do armazém sejam respeitadas.

Uma observação importante é que, se o número de SKUs for grande (milhares),
um MILP pode ficar pesado. Nesse caso, uma estratégia muito usada é usar o
ALS para reduzir o espaço de busca: para cada SKU, manter apenas as
5 ou 10 localizações com maior score e descartar o restante.
A heurística ou o MIP passam a trabalhar sobre um conjunto muito
menor de possibilidades, o que reduz bastante o tempo de solução sem perder muita qualidade.

#futuramente podemos usar coisas como o PBR palete e coisas parecidas para calcular a capacidade de cada prateleira


#__________________________________________________________________________________________________________________
# Variáveis para configuração do problema
seed                          # seed para Random
n_aisles                      # numero de corredores
n_shelves                     # numero de prateleiras por lado de corredor
volumetricModule              # escala em metros cúbicos para o volume dos produtos
capacity                      # estamos considerando prateleiras e produtos cubicos 
warehouse_filling_rate        # taxa de ocupação do armazém
sigma                         # desvio padrão da distribuição lognormal
v_tipico                      # volume típico da distribuição lognormal
p_frequency                   # prioridade frequência
p_volume                      # penalização volume
p_quantity = 0.5              # penalização estoque
candidate_fraction            # fração de candidatos a serem considerados para cada SKU entre (0, 1]
als_factor                    # fator de regularização para o ALS (teste com 0.001, 0.01, 0.1, 1)
als_k                         # número de fatores latentes para o ALS (teste com 5, 10, 20, 30, 50)
distance_factor         
    #distance_factor lim → 0 → nenhuma influência espacial (W -> I);
    #distance_factor pequeno → apenas vizinhos imediatos influenciam;
    #distance_factor intermediário → influência regional;
    #distance_factor lim → ∞ → todas as posições se influenciam igualmente.
message_passing_factor        # fator de influência da matriz de coocorrência na matriz de similaridade final (teste com 0.1, 0.5, 0.9)
max_variety                   # número máximo de variedades de SKUs por prateleira
piker_capacity                # capacideda de cada piker (Obs: capacidade = volume*quantidade)
#k = 4 # Número de clusters para o K-means
#__________________________________________________________________________________________________________________

rodar primeiro tem um piker para cada pedido
para cada pedido rodar tsp, montar a rota de cada pikerfunção objt vai ser a soma das distancias e quantidade de pikers
depois iniciar as economias


src/
│
├── ABC/                       # Análise e classificação de SKUs
│   ├── cluster_abc.jl         # Agrupamento baseado na curva ABC
│   └── sku_abc.jl             # Classificação de produtos (SKUs)
│
├── clustering/                # Algoritmos de agrupamento de dados
│   ├── cooccurrence.jl        # Análise de coocorrência de itens
│   └── kmeans.jl              # Implementação/configuração do algoritmo K-Means
│
├── data/                      # Instâncias e dados de entrada do problema
│   ├── readme.txt             # Documentação específica das instâncias
│   └── SLAPRP_Guo_small_*.txt # Instâncias do problema (O50, O100, O200) com variações de alpha
│
├── general_functions/         # Funções utilitárias e ferramentas compartilhadas
│
├── inventory_sizing/          # Módulos para dimensionamento de inventário
│
├── picking/                   # Algoritmos e regras para o processo de coleta (Picking)
│
├── Results/                   # [Ignorado] Saídas brutas, logs e resultados gerados
│
├── Results_compare/           # [Ignorado] Relatórios e scripts de comparação de resultados
│
├── slotting/                  # Estratégias de alocação de produtos em gôndolas (Slotting)
│
├── warehouse/                 # Modelagem e parametrização do layout do armazém
│
├── .gitignore                 # Filtros de arquivos e pastas para o Git
├── config.jl                  # Arquivo central de configuração do projeto
├── main.jl                    # Ponto de entrada (script principal de execução)
│
├── packages_linux.sh          # Instalação de dependências no Linux
├── packages_windows.exe       # Instalador automatizado para Windows
├── start_linux.sh             # Script de inicialização rápida no Linux
├── start_windows.exe          # Executável de inicialização no Windows
└── readme.txt                 # Este arquivo de documentação