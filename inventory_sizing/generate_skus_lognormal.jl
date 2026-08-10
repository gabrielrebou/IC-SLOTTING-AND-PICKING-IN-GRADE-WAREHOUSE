using Random
using Statistics
# Fazer esse código foi pura estatística
function generate_lognormal(v_tipico::Float64, sigma::Float64, n::Int, seed::Int)

    values = Vector{Float64}(undef, n)

    mu = log(v_tipico)
    Random.seed!(seed)
    for i in 1:n
        z = randn()
        values[i] = exp(mu + sigma * z)
    end

    return values
end

function generate_skus(
    sigma::Float64,
    v_tipico::Float64,
    p_frequency::Float64,
    p_volume::Float64,
    p_quantity::Float64,
    volumetric_module::Float64,
    capacity::Int,
    warehouse_capacity::Int,
    warehouse_filling_rate::Float64,
    instance::Instance,
    seed::Int
)

    n_skus = instance.n_skus

    # Frequência dos SKUs
    frequency = zeros(Int, n_skus)
    for order in instance.orders
        for sku in order.skus
            frequency[sku] += 1
        end
    end

    # Volume Lognormal dos SKUs
    Random.seed!(seed)
    raw_volume = Vector{Float64}(undef, n_skus)
    raw_volume = generate_lognormal(v_tipico, sigma, n_skus, seed)
    for i in eachindex(raw_volume)

        raw_volume[i] =
            clamp(
                raw_volume[i],
                volumetric_module,
                capacity
            )

        raw_volume[i] =
            round(raw_volume[i] / volumetric_module) *
            volumetric_module

    end


    volumes = raw_volume

    # garante atender pedidos
    quantity = max.(frequency, 1)

    max_volume = warehouse_capacity * warehouse_filling_rate
    current_volume = sum(quantity .* volumes)
    if current_volume > warehouse_capacity
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
                (frequency[i] + 1)^p_frequency


            volume_factor =
                volumes[i]^(-p_volume)


            stock_penalty =
                (quantity[i] + 1)^(-p_quantity)


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
            frequency[i],
            quantity[i],
            volumes[i]
        )

    end


    return result
end