# Warehouse Slotting and Picking

Projeto para experimentação de métodos de *slotting* (alocação de SKUs) e *picking* (roteamento e agrupamento de pickers) em armazéns.

## Sumário

- [Instalação](#instalação)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Variáveis de configuração](#variáveis-de-configuração)
- [Estratégias](#estratégias)
  - [Slotting](#slotting)
  - [Picking](#picking)
- [Roadmap](#roadmap)

## Instalação

### Linux

```bash
chmod +x packages_linux.sh
./packages_linux.sh
```

### Windows

Dê duplo clique em `packages_windows.exe`.

## Estrutura do projeto

```text
src/
├── Data/                          # Instâncias utilizadas nos experimentos
│
├── General_functions/             # Funções e tipos utilizados pelo projeto
│   ├── config.jl                  # Configurações gerais
│   ├── graphs.jl                  # Funções relacionadas a gráficos
│   ├── prints.jl                  # Impressão dos resultados
│   ├── reader.jl                  # Leitura dos dados
│   ├── save_files.jl              # Salvamento dos resultados
│   └── types.jl                   # Definição dos tipos utilizados
│
├── Inventory_sizing/               # Geração de dados de estoque
│   └── generate_skus_lognormal.jl
│
├── Picking/                        # Métodos relacionados ao picking
│   ├── Merge/                      # Métodos de agrupamento de rotas
│   │   ├── heuristics/
│   │   │   ├── clarke_wright_greedy.jl
│   │   │   └── clarke_wright_savings.jl
│   │   ├── merge_main.jl
│   │   ├── merge_routes.jl
│   │   ├── picker_core.jl
│   │   ├── position_utils.jl
│   │   └── selector.jl
│   │
│   ├── Route/                      # Métodos de roteamento
│   │   ├── heuristics/
│   │   │   ├── astar_heuristic.jl
│   │   │   └── greedy_heuristic.jl
│   │   ├── route_main.jl
│   │   ├── route_orders.jl
│   │   └── selector.jl
│   │
│   └── validation.jl               # Validação das rotas
│
├── Slotting/                       # Métodos de alocação dos SKUs
│   ├── ABC/                        # Métodos baseados em ABC
│   │   ├── abc_allocation.jl
│   │   ├── abc_classifier.jl
│   │   └── abc_heuristic_allocation.jl
│   │
│   ├── ALS/                        # Métodos baseados em ALS
│   │   ├── als.jl
│   │   ├── build_sparse_matrix.jl
│   │   ├── MILP_als.jl
│   │   └── PPMI_G-test.jl
│   │
│   ├── allocation_main.jl
│   └── cooccurrence.jl
│
├── Warehouse/                      # Representação e propriedades do armazém
│   ├── create_warehouse.jl
│   ├── distance.jl
│   └── locations.jl
│
├── compare_main.jl                 # Comparação dos métodos
├── experiment_runner.jl            # Execução dos experimentos
└── main.jl                         # Execução principal do projeto
```

## Variáveis de configuração

As principais variáveis utilizadas para configurar o problema são:

| Variável                 | Descrição                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| `seed`                   | Seed utilizada pelo `Random`                                       |
| `n_aisles`               | Número de corredores                                                |
| `n_shelves`              | Número de prateleiras por lado de corredor                          |
| `volumetricModule`       | Escala em metros cúbicos para o volume dos produtos                 |
| `capacity`               | Capacidade das prateleiras e produtos                                |
| `warehouse_filling_rate` | Taxa de ocupação do armazém                                          |
| `sigma`                  | Desvio padrão da distribuição lognormal                              |
| `v_tipico`               | Volume típico da distribuição lognormal                              |
| `p_frequency`            | Prioridade da frequência                                             |
| `p_volume`               | Penalização pelo volume                                              |
| `p_quantity`             | Penalização pelo estoque                                             |
| `candidate_fraction`     | Fração de candidatos considerados para cada SKU                      |
| `als_factor`             | Fator de regularização do ALS                                        |
| `als_k`                  | Número de fatores latentes do ALS                                    |
| `distance_factor`        | Fator de influência espacial                                         |
| `message_passing_factor` | Influência da matriz de coocorrência na matriz de similaridade       |
| `max_variety`            | Número máximo de variedades de SKUs por prateleira                   |
| `piker_capacity`         | Capacidade de cada picker                                            |

### `distance_factor`

| Valor                    | Efeito                                    |
| ------------------------- | ------------------------------------------ |
| `0`                        | Nenhuma influência espacial (`W -> I`)      |
| Pequeno                    | Apenas vizinhos imediatos influenciam       |
| Intermediário               | Influência regional                         |
| `∞`                         | Todas as posições se influenciam igualmente |

Os parâmetros do ALS podem ser testados, por exemplo, com:

```text
als_factor = 0.001, 0.01, 0.1, 1
als_k      = 5, 10, 20, 30, 50
```

O `message_passing_factor` pode ser testado com `0.1`, `0.5` e `0.9`.

## Estratégias

### Slotting

O ALS não precisa substituir um algoritmo de otimização. Ele pode gerar uma função objetivo "inteligente", aprendida a partir dos dados, enquanto o MILP ou uma heurística garantem que todas as restrições do armazém sejam respeitadas.

Para um número grande de SKUs, o MILP pode se tornar pesado. Uma estratégia é usar o ALS para reduzir o espaço de busca: para cada SKU, mantêm-se apenas as 5 ou 10 localizações com maior *score*, descartando as demais. A heurística ou o MIP passam então a trabalhar sobre um conjunto menor de possibilidades, reduzindo o tempo de solução sem perder muita qualidade.

Futuramente, métodos como PBR, palete e outros semelhantes podem ser usados para calcular a capacidade de cada prateleira.

### Picking

Inicialmente, é considerado um picker por pedido. Para cada pedido, calcula-se uma rota com A* e, a partir dela, constrói-se a rota de cada picker. A função objetivo considera a soma das distâncias e a quantidade de pickers.

Depois disso, são aplicadas as etapas de agrupamento (*merge*) e de economia das rotas.

## Roadmap

- [ ] Geração dos resultados necessários nas saídas