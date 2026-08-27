# src/Picking/Route/selector.jl

# Centraliza a escolha entre as heuristicas de roteamento, para
# route_order! nao precisar saber qual esta em uso.
function next_shelf_selector(
    heuristic::RoutingHeuristic,
    current::Int,
    candidates::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)
    if heuristic == ASTAR_HEURISTIC
        return astar_next_shelf(current, candidates, distance_matrix, depot_distance)
    elseif heuristic == GREEDY
        return nearest_next_shelf(current, candidates, distance_matrix, depot_distance)
    else
        error("Heuristica de roteamento desconhecida: $heuristic")
    end
end
