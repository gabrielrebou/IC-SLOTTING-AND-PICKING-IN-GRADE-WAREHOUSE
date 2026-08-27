# src/general_functions/types.jl

# Parâmetros de configuração
struct WarehouseConfig
    n_aisles::Int
    n_shelves::Int
    shelf_capacity::Int
    filling_rate::Float64
end

struct SKUGenerationParams
    sigma::Float64
    tipic_v::Float64
    p_frequency::Float64
    p_volume::Float64
    p_quantity::Float64
    volumetric_module::Float64
    seed::Int
end

struct AllocationParams
    candidate_fraction::Float64
    als_k::Int
    als_factor::Float64
    distance_factor::Float64
    message_passing_factor::Float64
    max_variety::Int
end

struct PickingParams
    picker_capacity::Int
end

# Agrupa tudo que é fixo entre execuções (não muda por experimento)
struct Params
    warehouse_config::WarehouseConfig
    sku_generation::SKUGenerationParams
    allocation::AllocationParams
    picking::PickingParams
    data_names::Vector{String}
end

# Armazém

struct Location
    id::Int
    aisle::Int
    shelf::Int
    capacity::Int
end

struct Warehouse
    locations::Vector{Location}
    depot::Location
    capacity::Float64
    config::WarehouseConfig
end

# Pedidos e instância

struct Order
    id::Int
    skus::Vector{Int}
end

struct Instance
    n_skus::Int
    orders::Vector{Order}
end

# SKUs

struct SKU
    id::Int
    frequency::Int
    quantity::Float64
    volume::Float64
end

# Clusterização / coocorrência

struct Cluster
    skus::Vector{Int}
    average_frequency::Float64
end

struct ClusteringResult
    clusters::Vector{Cluster}
end

struct CooccurrenceMatrix
    matrix::Matrix{Int}
    frequency::Vector{Int}
end

# Picking

struct Pickers
    picker_rout::Vector{Int}
    sku_shelf::Vector{Vector{Int}}
    distance::Vector{Float64}
end

# Configuração de experimento (o que varia entre execuções)

#@enum DistanceMethod CUSTOM_MANHATTAN
#@enum Shape I
@enum AllocationMethod ALS ABC ABC_HEURISTIC MESSAGE_PASSING
@enum RoutingHeuristic ASTAR_HEURISTIC GREEDY
@enum MergeHeuristic CLARKE_WRIGHT CLARKE_WRIGHT_HEURISTIC NO_HEURISTIC

struct ExperimentConfig
    data_id::Int
    #distance_method::DistanceMethod
    #shape::Shape
    allocation_method::AllocationMethod
    routing_heuristic::RoutingHeuristic
    merge_strategy::MergeHeuristic
end