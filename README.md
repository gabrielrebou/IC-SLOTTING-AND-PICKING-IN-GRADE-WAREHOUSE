# Warehouse Slotting and Picking

Projeto para experimentação de métodos de *slotting* (alocação de SKUs) e *picking* (roteamento e agrupamento de pickers) em armazéns.

## Sumário

- [Instalação](#instalação)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Variáveis de configuração](#variáveis-de-configuração)
- [Estratégias](#estratégias)
  - [Slotting](#slotting)
  - [Picking](#picking)
- [Formato de entrada e saída de cada etapa](#Formato-de-entrada-e-saída-de-cada-etapa)
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

## Formato de entrada e saída de cada etapa

Esta seção descreve o contrato de dados entre as etapas do pipeline
(`Slotting -> Routing -> Merge`), para facilitar a substituição de
qualquer uma delas por um novo método.

```text
ExperimentConfig + Params
        │
        ▼
  allocation_main()   (Slotting)
        │  -> NamedTuple com .allocations, .warehouse, .skus, .distance_matrix, ...
        ▼
    route_main()       (Picking / Routing)
        │  -> NamedTuple com .pickers, .distance, .sum_pickers
        ▼
    merge_main()        (Picking / Merge)   [se merge_strategy != NO_HEURISTIC]
        │  -> NamedTuple com .pickers, .distance, .sum_pickers
        ▼
  save_files / print_pickers / archive_results
```

### `ExperimentConfig` (`General_functions/types.jl`)

| Campo               | Tipo               | Valores possíveis                             |
| -------------------- | ------------------- | ------------------------------------------------ |
| `data_id`             | `Int`                | índice em `params.data_names`                    |
| `allocation_method`   | `AllocationMethod`   | `ALS`, `ABC`, `ABC_HEURISTIC`, `MESSAGE_PASSING`  |
| `routing_heuristic`   | `RoutingHeuristic`   | `ASTAR_HEURISTIC`, `GREEDY`                        |
| `merge_strategy`      | `MergeHeuristic`     | `CLARKE_WRIGHT`, `CLARKE_WRIGHT_HEURISTIC`, `NO_HEURISTIC` |

> Apenas `data_id` + `allocation_method` determinam o cache de alocação
> (`allocation_cache_path`); `routing_heuristic` e `merge_strategy` não
> afetam essa etapa.

### `Params` (`General_functions/types.jl` / `config.jl`)

| Campo               | Tipo                   | Consumido em                          |
| -------------------- | ------------------------ | ---------------------------------------- |
| `warehouse_config`    | `WarehouseConfig`        | `allocation_main` (`create_warehouse`)   |
| `sku_generation`      | `SKUGenerationParams`    | `allocation_main` (`generate_skus`, seed do ALS) |
| `allocation`          | `AllocationParams`       | `allocation_main`                        |
| `picking`             | `PickingParams`          | `route_main`, `merge_main` (`picker_capacity`) |
| `data_names`          | `Vector{String}`         | `allocation_main` (leitura da instância via `data_id`) |

---

### 1. Slotting — `allocation_main(cfg::ExperimentConfig, params::Params)`
`src/Slotting/allocation_main.jl`

**Entrada**
- `cfg` — usa `data_id`, `allocation_method`
- `params` — usa `warehouse_config`, `sku_generation`, `allocation`, `data_names[cfg.data_id]`

**Saída** — `NamedTuple`:

| Campo             | Tipo                       | Sempre preenchido? |
| ------------------ | ---------------------------- | ---------------------- |
| `instance`          | `Instance`                    | sim |
| `warehouse`         | `Warehouse`                   | sim |
| `depot_distance`     | (retorno de `compute_depot_distance`) | sim |
| `depot_id`           | `Int`                          | sim |
| `cooc`               | `CooccurrenceMatrix`          | sim |
| `skus`               | `Vector{SKU}`                 | sim |
| `distance_matrix`     | `Matrix`                       | sim |
| `sparse_matrix`, `U`, `V`, `S_hat`, `W`, `P`, `S_hat_hat` | `Matrix{Float64}` | só preenchidos para `ALS`/`MESSAGE_PASSING`; caso contrário ficam como `Matrix{Float64}(undef, 0, 0)` |
| `allocations`        | coleção de alocações           | pode vir **vazia** — nesse caso o pipeline encerra o experimento cedo (`run_experiment_with_allocation`) |

**Despacho por `allocation_method`:**

| Método               | Função chamada                                          |
| ---------------------- | ----------------------------------------------------------- |
| `ABC`                   | `abc_skus` + `abc_allocation`                                |
| `ABC_HEURISTIC`         | `abc_skus` + `abc_allocation_heuristic` (usa `cooc`, `distance_matrix`) |
| `ALS`                   | `build_sparse_matrix` + `als` + `als_allocate` sobre `S_hat` |
| `MESSAGE_PASSING`       | igual ao `ALS`, mas combina `S_hat` com `W` (correlação de distância) e `P` (coocorrência normalizada) para formar `S_hat_hat`, e aloca sobre `S_hat_hat` |

**Para adicionar um novo método:** implementar uma função `(skus, ..., warehouse, ..., max_variety) -> allocations`, adicionar um `elseif cfg.allocation_method == NOVO_METODO` e registrar `NOVO_METODO` em `@enum AllocationMethod`. Se o método usar matrizes intermediárias novas, adicione-as ao `NamedTuple` de retorno e trate em `report_allocation`/`print_allocation` se quiser visualização.

---

### 2. Routing — `route_main(cfg::ExperimentConfig, params::Params, alloc_result)`
`src/Picking/Route/route_main.jl`

**Entrada**
- `cfg` — usa `routing_heuristic` (repassado implicitamente a `route_orders` → `next_shelf_selector`)
- `params` — usa `picking.picker_capacity` (validado com `validate_positive`)
- `alloc_result` — usa `.instance`, `.allocations`, `.skus`, `.warehouse`, `.distance_matrix` (o `NamedTuple` inteiro de `allocation_main`, não só `.allocations`)

**Saída** — `NamedTuple`:

| Campo         | Tipo                      | Descrição |
| -------------- | ---------------------------- | ----------- |
| `pickers`       | `Vector` (já achatado via `reduce(vcat, pickers_by_order)`) | rotas de todos os pickers, de todos os pedidos, em uma lista só |
| `distance`       | número                       | de `calculate_picker_results(all_pickers)` |
| `sum_pickers`    | número                       | idem |
| `route_time`      | `Float64`                    | tempo medido internamente (`@timed route_orders`) |
| `route_bytes`     | `Int64`                      | alocação de memória medida internamente |

Cada picker passa por `validate_picker` antes do resultado ser montado.

**Para adicionar uma nova heurística:** implementar em `Picking/Route/heuristics/`, registrar em `Picking/Route/selector.jl` (`next_shelf_selector`) e em `@enum RoutingHeuristic`. Não é necessário mexer em `route_main` — o despacho é feito dentro de `route_orders`/`route_order!`.

---

### 3. Merge — `merge_main(cfg::ExperimentConfig, params::Params, alloc_result, route_result)`
`src/Picking/Merge/merge_main.jl`

Executado apenas se `cfg.merge_strategy != NO_HEURISTIC`.

**Entrada**
- `cfg` — usa `merge_strategy`
- `params` — usa `picking.picker_capacity`
- `alloc_result` — mesmo `NamedTuple` de `allocation_main`; usa `.skus` (para `sku_volume`), `.warehouse`, `.distance_matrix`
- `route_result` — usa `.pickers` (saída de `route_main`)

**Saída** — `NamedTuple`:

| Campo          | Tipo          | Descrição |
| --------------- | --------------- | ----------- |
| `pickers`         | `Vector`         | rotas já agrupadas, saída de `merge_selector` |
| `distance`         | número           | de `calculate_picker_results(merged_pickers)` |
| `sum_pickers`      | número           | idem |
| `merge_time`        | `Float64`        | `@timed merge_selector` |
| `merge_bytes`        | `Int64`          | idem |

**Para adicionar uma nova heurística de merge:** implementar em
`Picking/Merge/heuristics/`, registrar em `Picking/Merge/selector.jl`
(`merge_selector`) — que espera a assinatura
`(strategy, pickers, distance_matrix, sku_volume, picker_capacity, depot_distance, depot_id, warehouse)` — e em `@enum MergeHeuristic`.

---

## Roadmap

- [ ] Geração dos resultados necessários nas saídas