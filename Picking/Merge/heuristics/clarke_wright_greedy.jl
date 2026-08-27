# src/Picking/Merge/heuristics/clarke_wright_greedy.jl
#
# Renomeado de "clarke_wright" (em pickers_merge.jl) para
# clarke_wright_greedy, para distinguir da versao classica das
# economias (clarke_wright_savings.jl).
#
# Variante gulosa: a cada iteracao recalcula a melhor fusao possivel
# entre TODOS os pares de rotas (testando as duas orientacoes de
# cada uma) e aplica so a melhor. Mais cara que a versao das
# economias, mas reage a mudanca de forma das rotas a cada merge.

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
                p1, p2, r1, r2,
                distance_matrix, depot_distance, depot_id
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


function clarke_wright_greedy(
    pickers::Vector{Pickers},
    distance_matrix::Matrix{Float64},
    sku_volume::Vector{Float64},
    picker_capacity::Float64,
    depot_distance::Vector{Float64},
    depot_id::Int
)
    validate_positive(picker_capacity, "picker_capacity")

    routes = copy(pickers)

    loads = [route_load(picker, sku_volume) for picker in routes]

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

                old_distance = sum(routes[i].distance) + sum(routes[j].distance)

                candidate = best_merge(
                    routes[i], routes[j],
                    distance_matrix, depot_distance, depot_id
                )

                candidate === nothing && continue

                new_distance = sum(candidate.distance)
                saving = old_distance - new_distance

                if saving > best_saving
                    best_saving = saving
                    best_i = i
                    best_j = j
                    best_picker = candidate
                end
            end
        end

        best_i == 0 && break

        new_load = loads[best_i] + loads[best_j]

        deleteat!(routes, best_j)
        deleteat!(loads, best_j)

        deleteat!(routes, best_i)
        deleteat!(loads, best_i)

        push!(routes, best_picker)
        push!(loads, new_load)
    end

    return routes
end
