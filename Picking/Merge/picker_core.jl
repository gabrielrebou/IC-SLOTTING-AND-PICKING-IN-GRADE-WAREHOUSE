# src/Picking/Merge/picker_core.jl
#
# Operacoes basicas sobre Pickers, usadas por ambas as heuristicas de
# merge (savings e greedy): calcular carga/distancia, converter
# rota+skus em Pickers, e o inverso (Pickers -> Dict por prateleira).

function route_load(
    picker::Pickers,
    sku_volume::Vector{Float64}
)
    validate_picker(picker)

    load = 0.0

    for skus in picker.sku_shelf
        for sku in skus

            # pula os placeholders do deposito ([0] no inicio/fim)
            if sku == 0
                continue
            end

            validate_index_bounds(sku, length(sku_volume), "sku")

            # cada entrada em sku_shelf representa 1 unidade
            # retirada (route_order! repete o id da sku por
            # quantidade), entao basta somar o volume por ocorrencia
            load += sku_volume[sku]
        end
    end

    return load
end


function route_distance(
    route::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)
    if length(route) <= 2
        return 0.0
    end

    for id in route
        validate_index_bounds(id, length(depot_distance), "route id")
    end

    distance = 0.0

    distance += depot_distance[route[2]]

    for i in 2:length(route)-2
        distance += distance_matrix[route[i], route[i + 1]]
    end

    distance += depot_distance[route[end - 1]]

    return distance
end


# sku_shelf e distance sao construidos com o MESMO tamanho de route,
# incluindo os placeholders do deposito no inicio ([0], 0.0) e no fim,
# no mesmo padrao gerado por route_order!
function build_picker(
    route::Vector{Int},
    sku_by_shelf::Dict{Int,Vector{Int}},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64}
)
    if isempty(route)
        throw(ArgumentError("rota nao pode ser vazia"))
    end

    if length(route) <= 2
        return Pickers(route, [[0], [0]], [0.0, 0.0])
    end

    sku_shelf = Vector{Vector{Int}}()
    push!(sku_shelf, [0])

    for shelf in route[2:end-1]
        push!(sku_shelf, get(sku_by_shelf, shelf, Int[]))
    end

    push!(sku_shelf, [0])

    distance = Float64[0.0]

    push!(distance, depot_distance[route[2]])

    for i in 2:length(route)-2
        push!(distance, distance_matrix[route[i], route[i + 1]])
    end

    push!(distance, depot_distance[route[end - 1]])

    picker = Pickers(route, sku_shelf, distance)

    validate_picker(picker)

    return picker
end


# assume o padrao de route_order!: sku_shelf[i] corresponde
# diretamente a picker_rout[i] (mesmo indice, com [0] nas pontas)
function picker_to_dict(
    picker::Pickers
)
    validate_picker(picker)

    result = Dict{Int,Vector{Int}}()

    for i in 2:length(picker.picker_rout)-1
        shelf = picker.picker_rout[i]

        if !haskey(result, shelf)
            result[shelf] = Int[]
        end

        append!(result[shelf], picker.sku_shelf[i])
    end

    return result
end


function calculate_picker_results(pickers_route::Vector{Pickers})
    for picker in pickers_route
        validate_picker(picker)
    end

    distance = sum(sum(picker.distance) for picker in pickers_route; init = 0.0)
    sum_pickers = length(pickers_route)

    return distance, sum_pickers
end
