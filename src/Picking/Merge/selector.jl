# src/Picking/Merge/selector.jl
#
# Espelha Route/selector.jl: centraliza a escolha entre as
# heuristicas de merge, para merge_main nao precisar saber qual esta
# em uso nem lidar com a diferenca de assinatura entre elas (savings
# precisa de warehouse para calcular centroides; greedy nao).
function merge_selector(
    heuristic::MergeHeuristic,
    pickers::Vector{Pickers},
    distance_matrix::Matrix{Float64},
    sku_volume::Vector{Float64},
    picker_capacity::Float64,
    depot_distance::Vector{Float64},
    depot_id::Int,
    warehouse::Warehouse
)
    if heuristic == CLARKE_WRIGHT_HEURISTIC
        return clarke_wright_savings(
            pickers, distance_matrix, sku_volume,
            picker_capacity, depot_distance, depot_id, warehouse
        )
    elseif heuristic == CLARKE_WRIGHT
        return clarke_wright_greedy(
            pickers, distance_matrix, sku_volume,
            picker_capacity, depot_distance, depot_id
        )
    else
        error("Heuristica de merge desconhecida: $heuristic")
    end
end
