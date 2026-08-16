function route_load(
    picker::Pickers,
    sku_volume::Vector{Float64}
)
    load = 0.0

    for skus in picker.sku_shelf
        for sku in skus

            # pula os placeholders do deposito ([0] no inicio/fim)
            if sku == 0
                continue
            end

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

    distance = 0.0

    distance += depot_distance[route[2]]

    for i in 2:length(route)-2
        distance += distance_matrix[
            route[i],
            route[i + 1]
        ]
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
    if length(route) <= 2
        return Pickers(route, [[0], [0]], [0.0, 0.0])
    end

    sku_shelf = Vector{Vector{Int}}()
    push!(sku_shelf, [0])

    for shelf in route[2:end-1]
        push!(
            sku_shelf,
            get(sku_by_shelf, shelf, Int[])
        )
    end

    push!(sku_shelf, [0])

    distance = Float64[0.0]

    push!(
        distance,
        depot_distance[route[2]]
    )

    for i in 2:length(route)-2
        push!(
            distance,
            distance_matrix[
                route[i],
                route[i + 1]
            ]
        )
    end

    push!(
        distance,
        depot_distance[route[end - 1]]
    )

    return Pickers(
        route,
        sku_shelf,
        distance
    )
end


# assume o padrao de route_order!: sku_shelf[i] corresponde
# diretamente a picker_rout[i] (mesmo indice, com [0] nas pontas)
function picker_to_dict(
    picker::Pickers
)
    result = Dict{Int,Vector{Int}}()

    for i in 2:length(picker.picker_rout)-1
        shelf = picker.picker_rout[i]

        if !haskey(result, shelf)
            result[shelf] = Int[]
        end

        append!(
            result[shelf],
            picker.sku_shelf[i]
        )
    end

    return result
end


function merge_routes(
    p1::Pickers,
    p2::Pickers,
    route1::Vector{Int},
    route2::Vector{Int},
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64},
    depot_id::Int
)
    route = vcat(
        route1[1:end-1],
        route2[2:end]
    )

    dict1 = picker_to_dict(p1)
    dict2 = picker_to_dict(p2)

    sku_by_shelf = Dict{Int,Vector{Int}}()

    for (shelf, skus) in dict1
        sku_by_shelf[shelf] = copy(skus)
    end

    for (shelf, skus) in dict2

        if !haskey(sku_by_shelf, shelf)
            sku_by_shelf[shelf] = Int[]
        end

        append!(
            sku_by_shelf[shelf],
            skus
        )
    end

    new_route = Int[depot_id]
    new_sku_by_shelf = Dict{Int,Vector{Int}}()

    for shelf in route[2:end-1]

        if !haskey(new_sku_by_shelf, shelf)

            new_sku_by_shelf[shelf] =
                copy(sku_by_shelf[shelf])

            push!(
                new_route,
                shelf
            )
        end
    end

    push!(new_route, depot_id)

    return build_picker(
        new_route,
        new_sku_by_shelf,
        distance_matrix,
        depot_distance
    )
end


function route_orientations(
    route::Vector{Int}
)
    normal = copy(route)

    reversed = reverse(route)

    return (
        normal,
        reversed
    )
end


function best_merge(
    p1::Pickers,
    p2::Pickers,
    distance_matrix::Matrix{Float64},
    depot_distance::Vector{Float64},
    depot_id::Int
)
    best_picker = nothing
    best_distance = Inf

    for r1 in route_orientations(p1.picker_rout)
        for r2 in route_orientations(p2.picker_rout)

            if r1[end - 1] == r2[2]
                continue
            end

            candidate = merge_routes(
                p1,
                p2,
                r1,
                r2,
                distance_matrix,
                depot_distance,
                depot_id
            )

            d = sum(candidate.distance)

            if d < best_distance
                best_distance = d
                best_picker = candidate
            end
        end
    end

    return best_picker
end


function clarke_wright(
    pickers::Vector{Pickers},
    distance_matrix::Matrix{Float64},
    sku_volume::Vector{Float64},
    picker_capacity::Float64,
    depot_distance::Vector{Float64},
    depot_id::Int
)
    routes = copy(pickers)

    loads = [
        route_load(
            picker,
            sku_volume
        )
        for picker in routes
    ]

    while true

        best_i = 0
        best_j = 0
        best_picker = nothing
        best_saving = 0.0

        for i in 1:length(routes)-1

            for j in i+1:length(routes)

                if loads[i] + loads[j] > picker_capacity
                    continue
                end

                old_distance =
                    sum(routes[i].distance) +
                    sum(routes[j].distance)

                candidate = best_merge(
                    routes[i],
                    routes[j],
                    distance_matrix,
                    depot_distance,
                    depot_id
                )

                if candidate === nothing
                    continue
                end

                new_distance =
                    sum(candidate.distance)

                saving =
                    old_distance -
                    new_distance

                if saving > best_saving
                    best_saving = saving
                    best_i = i
                    best_j = j
                    best_picker = candidate
                end
            end
        end

        if best_i == 0
            break
        end

        new_load =
            loads[best_i] +
            loads[best_j]

        deleteat!(routes, best_j)
        deleteat!(loads, best_j)

        deleteat!(routes, best_i)
        deleteat!(loads, best_i)

        push!(
            routes,
            best_picker
        )

        push!(
            loads,
            new_load
        )
    end

    return routes
end