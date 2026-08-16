function astar_next_shelf(
    current::Int,
    candidates::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)

    isempty(candidates) && return nothing

    best_node = nothing
    best_f = Inf

    for node in candidates

        g = distance_matrix[current, node]

        remaining = Int[]

        for other in candidates
            if other != node
                push!(remaining, other)
            end
        end

        h = heuristic(
            node,
            remaining,
            distance_matrix,
            depot_distance
        )

        f = g + h

        if f < best_f
            best_f = f
            best_node = node
        end
    end

    return best_node
end