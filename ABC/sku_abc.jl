function abc_allocation(
    skus::Vector{SKU},
    classes::Vector{Char},
    cooccurrence::CooccurrenceMatrix,
    warehouse::Warehouse,
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)

    n_skus = length(skus)
    n_shelves = length(warehouse.locations)

    allocation = zeros(Int, n_shelves, n_skus)

    used_volume = zeros(Float64, n_shelves)

    shelf_capacity = Float64[
        warehouse.locations[i].capacity
        for i in 1:n_shelves
    ]

    order = sortperm(
        1:n_skus,
        by = i -> (
            classes[i] == 'A' ? 1 :
            classes[i] == 'B' ? 2 : 3,
            -skus[i].frequency
        )
    )

    class_weight = Dict(
        'A' => 1.0,
        'B' => 0.5,
        'C' => 0.2
    )

    max_cooccurrence = maximum(cooccurrence.matrix)

    if max_cooccurrence == 0
        max_cooccurrence = 1
    end

    for sku_id in order

        remaining = skus[sku_id].quantity

        while remaining > 0

            best_shelf = 0
            best_cost = Inf
            best_amount = 0

            for shelf in 1:n_shelves

                available_volume =
                    shelf_capacity[shelf] -
                    used_volume[shelf]

                if available_volume <= 0
                    continue
                end

                max_amount = floor(
                    available_volume /
                    skus[sku_id].volume
                )

                amount = min(
                    remaining,
                    max_amount
                )

                if amount <= 0
                    continue
                end

                volume_ratio =
                    used_volume[shelf] /
                    shelf_capacity[shelf]

                volume_penalty =
                    volume_ratio^2

                depot_cost =
                    class_weight[classes[sku_id]] *
                    depot_distance[shelf]

                proximity_cost = 0.0

                for other_sku in 1:n_skus

                    cooc =
                        cooccurrence.matrix[
                            sku_id,
                            other_sku
                        ]

                    if cooc == 0
                        continue
                    end

                    normalized_cooc =
                        cooc / max_cooccurrence

                    for other_shelf in 1:n_shelves

                        if allocation[
                            other_shelf,
                            other_sku
                        ] == 0
                            continue
                        end

                        proximity_cost +=
                            normalized_cooc *
                            skus[other_sku].frequency *
                            distance_matrix[
                                shelf,
                                other_shelf
                            ]
                    end
                end

                cost =
                    depot_cost +
                    proximity_cost +
                    volume_penalty

                if cost < best_cost
                    best_cost = cost
                    best_shelf = shelf
                    best_amount = amount
                end
            end

            if best_shelf == 0
                error(
                    "Nao ha capacidade suficiente para alocar o SKU $sku_id"
                )
            end

            allocation[
                best_shelf,
                sku_id
            ] += best_amount

            used_volume[best_shelf] +=
                best_amount *
                skus[sku_id].volume

            remaining -= best_amount
        end
    end

    return allocation
end