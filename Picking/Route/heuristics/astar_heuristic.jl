# src/Picking/Route/heuristics/astar_heuristic.jl

# Estimativa otimista (g + h) usada pelo A*: distancia minima ate
# qualquer candidato restante, somada ao retorno mais barato ao
# deposito a partir desse candidato. Renomeada de "heuristic" (nome
# generico demais) para deixar claro que e especifica do A*.
function astar_lookahead(
    current::Int,
    candidates::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)
    if isempty(candidates)
        validate_index_bounds(current, length(depot_distance), "current")
        return depot_distance[current]
    end

    min_distance = Inf

    for node in candidates
        min_distance = min(min_distance, distance_matrix[current, node])
    end

    return min_distance + minimum(depot_distance[node] for node in candidates)
end

# Escolhe a proxima prateleira com lookahead de 1 passo (g + h),
# comparando cada candidato com o custo de deixar os demais para depois.
function astar_next_shelf(
    current::Int,
    candidates::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)
    isempty(candidates) && return nothing

    validate_index_bounds(current, size(distance_matrix, 1), "current")

    best_node = nothing
    best_f = Inf

    for node in candidates
        g = distance_matrix[current, node]

        remaining = filter(other -> other != node, candidates)

        h = astar_lookahead(node, remaining, distance_matrix, depot_distance)

        f = g + h

        if f < best_f
            best_f = f
            best_node = node
        end
    end

    return best_node
end
