# src/Picking/Merge/heuristics/clarke_wright_savings.jl
#
# Renomeado de clarke_wright_raw (arquivo clarke_wright_raw.jl) para
# clarke_wright_savings, para nomear a funcao pelo que ela e -- o
# algoritmo classico "das economias" -- em vez de por oposicao a
# outra implementacao.
#
# Fiel ao metodo original:
# - savings calculadas UMA vez (c_ij = distancia entre centroides
#   dos pedidos)
# - ordenadas de forma decrescente
# - uma unica passada, mesclando apenas pontas livres, sem
#   recomputar "melhor par" a cada iteracao e sem testar orientacoes
#   em busca da menor distancia (a orientacao e definida apenas pela
#   topologia exigida para conectar as pontas corretas).
function clarke_wright_savings(
    pickers::Vector{Pickers},
    distance_matrix::Matrix{Float64},
    sku_volume::Vector{Float64},
    picker_capacity::Float64,
    depot_distance::Vector{Float64},
    depot_id::Int,
    warehouse::Warehouse
)
    validate_positive(picker_capacity, "picker_capacity")

    n = length(pickers)

    # --- posicoes e distancias ate o deposito (aproximacao por centroide) ---
    positions = [picker_position(p, warehouse) for p in pickers]
    depot_pos = (Float64(warehouse.depot.aisle), Float64(warehouse.depot.shelf))
    c0 = [custom_manhattan(depot_pos, positions[k]) for k in 1:n]

    # --- lista de savings, calculada uma unica vez ---
    savings = Tuple{Float64,Int,Int}[]

    for i in 1:n-1
        for j in i+1:n
            cij = custom_manhattan(positions[i], positions[j])
            push!(savings, (c0[i] + c0[j] - cij, i, j))
        end
    end

    sort!(savings, by = x -> x[1], rev = true)

    # --- bookkeeping das cadeias (rotas) ativas ---
    chain_of  = collect(1:n)                          # no original -> id da cadeia atual
    head_of   = Dict(k => k for k in 1:n)              # id da cadeia -> no original na ponta inicial
    tail_of   = Dict(k => k for k in 1:n)              # id da cadeia -> no original na ponta final
    picker_of = Dict(k => pickers[k] for k in 1:n)     # id da cadeia -> Pickers atual
    load_of   = Dict(k => route_load(pickers[k], sku_volume) for k in 1:n)

    next_chain_id = n + 1

    is_endpoint(k) = (k == head_of[chain_of[k]]) || (k == tail_of[chain_of[k]])

    for (s, i, j) in savings

        s <= 0 && break   # economia nao positiva nao compensa; lista ja esta ordenada

        ci, cj = chain_of[i], chain_of[j]

        ci == cj && continue          # ja na mesma rota (evita subtour)
        !is_endpoint(i) && continue   # i nao esta mais numa ponta livre
        !is_endpoint(j) && continue   # j nao esta mais numa ponta livre

        if load_of[ci] + load_of[cj] > picker_capacity
            continue
        end

        pi, pj = picker_of[ci], picker_of[cj]

        # orienta a rota de i para que ele termine nela
        route_i = (i == tail_of[ci]) ? pi.picker_rout : reverse(pi.picker_rout)
        # orienta a rota de j para que ele comece nela
        route_j = (j == head_of[cj]) ? pj.picker_rout : reverse(pj.picker_rout)

        merged = merge_routes(
            pi, pj, route_i, route_j,
            distance_matrix, depot_distance, depot_id
        )

        new_head = (i == tail_of[ci]) ? head_of[ci] : tail_of[ci]
        new_tail = (j == head_of[cj]) ? tail_of[cj] : head_of[cj]

        new_id = next_chain_id
        next_chain_id += 1

        picker_of[new_id] = merged
        load_of[new_id]   = load_of[ci] + load_of[cj]
        head_of[new_id]   = new_head
        tail_of[new_id]   = new_tail

        for k in 1:n
            if chain_of[k] == ci || chain_of[k] == cj
                chain_of[k] = new_id
            end
        end

        delete!(picker_of, ci); delete!(load_of, ci)
        delete!(picker_of, cj); delete!(load_of, cj)
    end

    return collect(values(picker_of))
end
