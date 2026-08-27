# src/Inventory_sizing/generate_skus_lognormal.jl

using Random
using Statistics
# Fazer esse código foi pura estatística
function generate_lognormal(tipic_v::Float64, sigma::Float64, n::Int, seed::Int)

    values = Vector{Float64}(undef, n)

    mu = log(tipic_v)
    Random.seed!(seed)
    for i in 1:n
        z = randn()
        values[i] = exp(mu + sigma * z)
    end

    return values
end

function generate_skus(params::Params, instance::Instance, warehouse::Warehouse)

    n_skus = instance.n_skus

    # Frequência dos SKUs
    frequency = zeros(Int, n_skus)
    for order in instance.orders
        for sku in order.skus
            frequency[sku] += 1
        end
    end

    # Volume Lognormal dos SKUs
    Random.seed!(params.sku_generation.seed)
    raw_volume = Vector{Float64}(undef, n_skus)
    raw_volume = generate_lognormal(params.sku_generation.tipic_v, params.sku_generation.sigma, n_skus, params.sku_generation.seed)
    for i in eachindex(raw_volume)

        raw_volume[i] =
            clamp(
                raw_volume[i],
                params.sku_generation.volumetric_module,
                params.warehouse_config.shelf_capacity
            )

        raw_volume[i] =
            round(raw_volume[i] / params.sku_generation.volumetric_module) *
            params.sku_generation.volumetric_module

    end


    volumes = raw_volume

    # garante atender pedidos
    quantity = max.(frequency, 1)

    max_volume = warehouse.capacity * params.warehouse_config.filling_rate
    current_volume = sum(quantity .* volumes)
    if current_volume > warehouse.capacity
        error("Capacidade insuficiente para atender demanda mínima")
    end

    for _ in 1:1000000

        free_space = max_volume - current_volume

        free_space <= 0 && break


        candidates = [
            i for i in 1:n_skus
            if volumes[i] <= free_space
        ]


        isempty(candidates) && break


        weights = Vector{Float64}(undef, length(candidates))


        for j in eachindex(candidates)

            i = candidates[j]

            demand_factor =
                (frequency[i] + 1)^params.sku_generation.p_frequency


            volume_factor =
                volumes[i]^(-params.sku_generation.p_volume)


            stock_penalty =
                (quantity[i] + 1)^(-params.sku_generation.p_quantity)


            weights[j] =
                demand_factor *
                volume_factor *
                stock_penalty

        end


        total_weight = sum(weights)

        r = rand() * total_weight

        accumulated = 0.0

        selected = candidates[end]


        for j in eachindex(weights)

            accumulated += weights[j]

            if accumulated >= r

                selected = candidates[j]
                break

            end

        end


        quantity[selected] += 1
        current_volume += volumes[selected]

    end

    # Resultado
    result = Vector{SKU}(undef, n_skus)

    for i in 1:n_skus

        result[i] = SKU(
            i,
            frequency[i],
            quantity[i],
            volumes[i]
        )

    end


    return result
end