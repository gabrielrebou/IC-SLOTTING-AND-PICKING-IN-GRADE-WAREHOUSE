function route_order!(
    order::Vector{Int},
    stock::Matrix{Int},
    skus::Vector{SKU},
    warehouse::Warehouse,
    picker_capacity::Int,
    distance_matrix::Matrix{Float64}
)
    depot = warehouse.depot
    locations = warehouse.locations

    n_locations = length(locations)

    depot_distance = Vector{Float64}(undef, n_locations)

    for i in 1:n_locations
        depot_distance[i] = custom_manhattan(
            depot,
            locations[i]
        )
    end

    demand = Dict{Int,Int}()

    for sku in order
        demand[sku] = get(demand, sku, 0) + 1
    end

    route = [depot.id]
    sku_shelf = Vector{Vector{Int}}()
    push!(sku_shelf, [0])          # deposito no inicio, sem skus
    distance = Float64[0.0]        # nenhuma distancia percorrida ainda

    current = 1
    used_capacity = 0.0

    while !isempty(demand)

        remaining_capacity =
            picker_capacity - used_capacity

        if remaining_capacity <= 0
            break
        end

        candidates = Int[]

        for location_index in 1:n_locations

            location = locations[location_index]

            for sku in keys(demand)

                if demand[sku] <= 0
                    continue
                end

                if stock[location.id, sku] <= 0
                    continue
                end

                if skus[sku].volume > remaining_capacity
                    continue
                end

                push!(candidates, location_index)
                break
            end
        end

        if isempty(candidates)
            println(
                "Aviso: estoque insuficiente para atender o pedido."
            )
            break
        end

        next = astar_next_shelf(
            current,
            candidates,
            distance_matrix,
            depot_distance
        )

        if next === nothing
            break
        end

        location = locations[next]

        capacity_left = remaining_capacity
        collected = false

        candidate_skus = Int[]

        for sku in keys(demand)

            if demand[sku] > 0 &&
               stock[location.id, sku] > 0 &&
               skus[sku].volume <= capacity_left

                push!(candidate_skus, sku)
            end
        end

        sort!(
            candidate_skus,
            by = sku -> skus[sku].volume
        )

        picked_skus = Int[]

        for sku in candidate_skus

            quantity = min(
                demand[sku],
                stock[location.id, sku],
                floor(Int, capacity_left / skus[sku].volume)
            )

            if quantity > 0

                collected = true

                stock[location.id, sku] -= quantity
                demand[sku] -= quantity

                used_capacity +=
                    quantity * skus[sku].volume

                capacity_left -=
                    quantity * skus[sku].volume

                # registra cada unidade retirada dessa prateleira
                append!(picked_skus, fill(sku, quantity))
            end
        end

        if !collected
            filter!(x -> x != next, candidates)
            continue
        end

        push!(distance, distance_matrix[current, next])
        push!(route, location.id)
        push!(sku_shelf, picked_skus)

        current = next

        for sku in collect(keys(demand))
            if demand[sku] <= 0
                delete!(demand, sku)
            end
        end
    end

    if current != 1 || length(route) > 1

        push!(distance, depot_distance[current])
        push!(route, depot.id)
        push!(sku_shelf, [0])
    end

    remaining_order = Int[]

    for (sku, quantity) in demand

        for _ in 1:quantity
            push!(remaining_order, sku)
        end
    end

    picker = Pickers(
        route,
        sku_shelf,
        distance
    )

    return picker, remaining_order
end


function route_orders(
    instances::Instance,
    allocations::Matrix{Int},
    skus::Vector{SKU},
    picker_capacity::Int,
    warehouse::Warehouse,
    distance_matrix::Matrix{Float64}
)

    remaining_stock = copy(allocations)

    # cada pedido pode precisar de varios pickers, entao guardamos
    # um Vector{Pickers} por pedido
    results = Vector{Vector{Pickers}}(
        undef,
        length(instances.orders)
    )

    # TODO: atualmente os pedidos sao processados
    # sequencialmente. Rever outras estrategias de
    # distribuicao do estoque entre pedidos depois.

    for (i, order) in enumerate(instances.orders)

        total_volume =
            sum(skus[sku].volume for sku in order.skus)

        max_pickers =
            ceil(Int, total_volume / picker_capacity)

        remaining_order = copy(order.skus)

        pickers_for_order = Pickers[]

        for j in 1:max_pickers

            if isempty(remaining_order)
                break
            end

            picker, remaining_order = route_order!(
                remaining_order,
                remaining_stock,
                skus,
                warehouse,
                picker_capacity,
                distance_matrix
            )

            if length(picker.picker_rout) <= 1

                println(
                    "Aviso: nao foi possivel atender completamente o pedido."
                )

                break
            end

            push!(
                pickers_for_order,
                picker
            )
        end

        if !isempty(remaining_order)

            println(
                "Aviso: pedido $i nao foi completamente atendido."
            )
        end

        results[i] = pickers_for_order
    end

    return results
end