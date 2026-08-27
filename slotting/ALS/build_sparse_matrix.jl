# src/Slotting/ALS/build_sparse_matrix.jl

using SparseArrays

function build_sparse_matrix(
    skus::Vector{SKU},
    warehouse::Warehouse,
    candidate_fraction::Float64
)

    n_locations = length(warehouse.locations)
    n_skus = length(skus)

    max_freq = maximum(s.frequency for s in skus)

    distances = [
        custom_manhattan(warehouse.depot, loc)
        for loc in warehouse.locations
    ]

    max_dist = maximum(distances)

    rows = Int[]
    cols = Int[]
    vals = Float64[]

    k = max(1, round(Int, candidate_fraction*n_locations))

    order = sortperm(distances)

    for (sku_id, sku) in enumerate(skus)

        freq = sku.frequency / max_freq

        chosen = 0

        for loc_id in order

            loc = warehouse.locations[loc_id]

            if sku.volume * sku.quantity > loc.capacity
                continue
            end

            dist = distances[loc_id] / max_dist

            score = freq * (1 - dist) / (1 + sku.volume)

            push!(rows, loc_id)
            push!(cols, sku_id)
            push!(vals, score)

            chosen += 1

            chosen == k && break
        end
    end

    return sparse(rows, cols, vals, n_locations, n_skus)
end