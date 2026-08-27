# src/Picking/Merge/merge_routes.jl
#
# Mecanica generica de fusao de duas rotas (independente de qual
# heuristica decidiu fundi-las). Usada tanto por
# clarke_wright_greedy.jl quanto por clarke_wright_savings.jl.

function route_orientations(route::Vector{Int})
    if isempty(route)
        throw(ArgumentError("rota nao pode ser vazia"))
    end

    return (copy(route), reverse(route))
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
    validate_picker(p1)
    validate_picker(p2)
    validate_route_endpoints(route1, depot_id)
    validate_route_endpoints(route2, depot_id)

    route = vcat(route1[1:end-1], route2[2:end])

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

        append!(sku_by_shelf[shelf], skus)
    end

    new_route = Int[depot_id]
    new_sku_by_shelf = Dict{Int,Vector{Int}}()

    for shelf in route[2:end-1]

        if !haskey(new_sku_by_shelf, shelf)

            new_sku_by_shelf[shelf] = copy(sku_by_shelf[shelf])

            push!(new_route, shelf)
        end
    end

    push!(new_route, depot_id)

    merged = build_picker(new_route, new_sku_by_shelf, distance_matrix, depot_distance)

    # garante que nenhuma unidade de sku foi perdida ou duplicada
    # durante a fusao das duas rotas
    total_before = sum(length(skus) for skus in values(sku_by_shelf); init = 0)
    total_after = sum(length(skus) for skus in values(new_sku_by_shelf); init = 0)

    if total_before != total_after
        throw(ErrorException(
            "merge_routes: contagem de skus inconsistente ($total_before antes, $total_after depois)"
        ))
    end

    return merged
end
