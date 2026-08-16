function heuristic(
    current::Int,
    candidates::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)

    if isempty(candidates)
        return depot_distance[current]
    end

    min_distance = Inf

    for node in candidates
        min_distance = min(
            min_distance,
            distance_matrix[current, node]
        )
    end

    return min_distance +
           minimum(depot_distance[node] for node in candidates)
end