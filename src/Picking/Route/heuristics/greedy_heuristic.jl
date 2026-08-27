# src/Picking/Route/heuristics/greedy_heuristic.jl

# Escolhe a proxima prateleira de forma gulosa pura (sem lookahead):
# so olha a distancia ate cada candidato, ignora o que vem depois.
function nearest_next_shelf(
    current::Int,
    candidates::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)
    isempty(candidates) && return nothing

    validate_index_bounds(current, size(distance_matrix, 1), "current")

    best_node = nothing
    best_g = Inf

    for node in candidates
        g = distance_matrix[current, node]

        if g < best_g
            best_g = g
            best_node = node
        end
    end

    return best_node
end
