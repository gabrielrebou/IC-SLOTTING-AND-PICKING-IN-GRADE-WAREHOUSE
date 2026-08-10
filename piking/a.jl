"""
Pipeline: sourcing de estantes por SKU + Clarke-Wright (savings) para CVRP
com duas restricoes por funcionario (capacidade e variedade de SKUs).

Organizacao: cada etapa (distancia, sourcing, savings, criterio de merge)
e uma FUNCAO COM DISPATCH sobre um tipo de "estrategia". Pra trocar de
metodo no futuro, basta criar um novo subtype e um novo metodo -- o resto
do pipeline nao muda.
"""
module PickingCVRP

using LinearAlgebra: norm

export Estoque, Coordenadas, Pedido, PedidoInfo,
       DistanciaEuclidiana, SourcingGuloso,
       montar_info_pedidos, clarke_wright, sequencia_estantes_rota

# ---------------------------------------------------------------------------
# Tipos basicos
# ---------------------------------------------------------------------------
const Coord      = Tuple{Float64,Float64}
const Estoque     = Dict{String,Dict{Int,Int}}   # estante_id => (sku => qtd)
const Coordenadas = Dict{String,Coord}
const Pedido      = Vector{Tuple{Int,Int}}       # (sku, qtd)

struct PedidoInfo
    id::Int
    demanda_total::Int
    skus::Set{Int}
    centro::Coord
    estantes::Vector{Tuple{String,Dict{Int,Int}}}
end

# ---------------------------------------------------------------------------
# Estrategia de distancia -- troque/adicione subtypes aqui
# ---------------------------------------------------------------------------
abstract type FuncaoDistancia end

struct DistanciaEuclidiana <: FuncaoDistancia end
distancia(::DistanciaEuclidiana, p1::Coord, p2::Coord) = norm(collect(p1) .- collect(p2))

# Exemplo de outra estrategia que voce pode plugar sem tocar no resto:
# struct DistanciaGrafoCorredores <: FuncaoDistancia
#     grafo::MeuGrafo
# end
# distancia(d::DistanciaGrafoCorredores, p1, p2) = dijkstra(d.grafo, p1, p2)

# ---------------------------------------------------------------------------
# Estrategia de sourcing -- troque/adicione subtypes aqui
# ---------------------------------------------------------------------------
abstract type EstrategiaSourcing end

"""Guloso: prioriza cobrir mais SKUs pendentes por estante (minimiza fluxo),
desempate pela menor distancia (minimiza deslocamento)."""
struct SourcingGuloso <: EstrategiaSourcing end

function escolher_estantes(::SourcingGuloso, pedido::Pedido, estoque::Estoque,
                            coords::Coordenadas, deposito::Coord, dist::FuncaoDistancia)
    pendente = Dict(pedido)
    escolhidas = Tuple{String,Dict{Int,Int}}[]
    estoque_restante = Dict(e => copy(skus) for (e, skus) in estoque)

    while !isempty(pendente)
        melhor = nothing
        melhor_score = nothing

        for (estante_id, skus_estante) in estoque_restante
            cobertura = Dict{Int,Int}()
            for (sku, qtd_pend) in pendente
                disp = get(skus_estante, sku, 0)
                if disp > 0
                    cobertura[sku] = min(qtd_pend, disp)
                end
            end
            isempty(cobertura) && continue

            n_cobertos = length(cobertura)
            d = if !isempty(escolhidas)
                minimum(distancia(dist, coords[estante_id], coords[e]) for (e, _) in escolhidas)
            else
                distancia(dist, coords[estante_id], deposito)
            end

            score = (-n_cobertos, d)
            if melhor_score === nothing || score < melhor_score
                melhor_score = score
                melhor = (estante_id, cobertura)
            end
        end

        melhor === nothing && error("Estoque insuficiente para atender o pedido: falta $pendente")

        estante_id, cobertura = melhor
        push!(escolhidas, (estante_id, cobertura))
        for (sku, qtd) in cobertura
            pendente[sku] -= qtd
            pendente[sku] <= 0 && delete!(pendente, sku)
            estoque_restante[estante_id][sku] -= qtd
        end
    end

    return escolhidas
end

# ---------------------------------------------------------------------------
# Monta info consolidada de cada pedido (centroide, demanda, skus)
# ---------------------------------------------------------------------------
function montar_info_pedidos(pedidos::Vector{Pedido}, estoque::Estoque, coords::Coordenadas,
                              deposito::Coord, dist::FuncaoDistancia;
                              sourcing::EstrategiaSourcing = SourcingGuloso())
    infos = PedidoInfo[]
    for (idx, pedido) in enumerate(pedidos)
        escolhidas = escolher_estantes(sourcing, pedido, estoque, coords, deposito, dist)

        total_qtd = sum(sum(values(c)) for (_, c) in escolhidas)
        cx = sum(coords[e][1] * sum(values(c)) for (e, c) in escolhidas) / total_qtd
        cy = sum(coords[e][2] * sum(values(c)) for (e, c) in escolhidas) / total_qtd

        push!(infos, PedidoInfo(
            idx,
            total_qtd,
            Set(sku for (sku, _) in pedido),
            (cx, cy),
            escolhidas,
        ))
    end
    return infos
end

# ---------------------------------------------------------------------------
# Criterio de viabilidade de merge -- troque/adicione subtypes aqui
# ---------------------------------------------------------------------------
abstract type CriterioMerge end

struct CapacidadeEVariedade <: CriterioMerge
    capacidade::Int
    variedade::Int
end

function viavel(c::CapacidadeEVariedade, demanda_a::Int, skus_a::Set{Int},
                 demanda_b::Int, skus_b::Set{Int})
    nova_demanda   = demanda_a + demanda_b
    nova_variedade = union(skus_a, skus_b)
    return nova_demanda <= c.capacidade && length(nova_variedade) <= c.variedade
end

# ---------------------------------------------------------------------------
# Clarke-Wright (savings)
# ---------------------------------------------------------------------------
function clarke_wright(infos::Vector{PedidoInfo}, deposito::Coord,
                        dist::FuncaoDistancia, criterio::CriterioMerge)
    n = length(infos)
    d0 = [distancia(dist, deposito, p.centro) for p in infos]

    savings = Tuple{Float64,Int,Int}[]
    for i in 1:n, j in (i+1):n
        dij = distancia(dist, infos[i].centro, infos[j].centro)
        push!(savings, (d0[i] + d0[j] - dij, i, j))
    end
    sort!(savings, by = x -> x[1], rev = true)

    rotas       = Dict(i => [i] for i in 1:n)
    rota_de     = Dict(i => i for i in 1:n)
    demanda_rota = Dict(i => infos[i].demanda_total for i in 1:n)
    skus_rota    = Dict(i => copy(infos[i].skus) for i in 1:n)

    eh_extremidade(rota_id, pedido) = pedido == first(rotas[rota_id]) || pedido == last(rotas[rota_id])

    for (s, i, j) in savings
        s <= 0 && break  # merges com saving negativo nunca compensam

        ri, rj = rota_de[i], rota_de[j]
        ri == rj && continue
        (eh_extremidade(ri, i) && eh_extremidade(rj, j)) || continue

        if !viavel(criterio, demanda_rota[ri], skus_rota[ri], demanda_rota[rj], skus_rota[rj])
            continue
        end

        rota_i = copy(rotas[ri]); rota_j = copy(rotas[rj])
        last(rota_i) != i && reverse!(rota_i)
        first(rota_j) != j && reverse!(rota_j)

        nova_rota = vcat(rota_i, rota_j)
        rotas[ri] = nova_rota
        delete!(rotas, rj)
        for p in nova_rota
            rota_de[p] = ri
        end
        demanda_rota[ri] += demanda_rota[rj]
        skus_rota[ri] = union(skus_rota[ri], skus_rota[rj])
        delete!(demanda_rota, rj)
        delete!(skus_rota, rj)
    end

    return collect(values(rotas))  # cada elemento = lista de indices de pedidos p/ 1 funcionario
end

# ---------------------------------------------------------------------------
# (Opcional) sequencia real de estantes dentro de uma rota -- nearest neighbor
# ---------------------------------------------------------------------------
function sequencia_estantes_rota(rota::Vector{Int}, infos::Vector{PedidoInfo},
                                  coords::Coordenadas, deposito::Coord, dist::FuncaoDistancia)
    estantes_rota = String[]
    vistas = Set{String}()
    for pedido_idx in rota
        for (estante_id, _) in infos[pedido_idx].estantes
            if !(estante_id in vistas)
                push!(vistas, estante_id)
                push!(estantes_rota, estante_id)
            end
        end
    end

    restantes = Set(estantes_rota)
    atual = deposito
    caminho = String[]
    while !isempty(restantes)
        prox = argmin(e -> distancia(dist, atual, coords[e]), collect(restantes))
        push!(caminho, prox)
        delete!(restantes, prox)
        atual = coords[prox]
    end
    return caminho
end

end # module

# ---------------------------------------------------------------------------
# Exemplo de uso
# ---------------------------------------------------------------------------
using .PickingCVRP

estoque = Dict(
    "E1" => Dict(101 => 5, 102 => 3),
    "E2" => Dict(101 => 4, 103 => 10),
    "E3" => Dict(102 => 8, 104 => 6),
    "E4" => Dict(103 => 5, 104 => 2),
)
coords = Dict(
    "E1" => (0.0, 5.0), "E2" => (2.0, 5.0), "E3" => (0.0, 10.0), "E4" => (2.0, 10.0),
)
deposito = (0.0, 0.0)

pedidos = Pedido[
    [(101, 3), (102, 2)],
    [(103, 4)],
    [(104, 2), (101, 1)],
    [(102, 1), (103, 3)],
]

dist = DistanciaEuclidiana()
criterio = CapacidadeEVariedade(10, 3)

infos = montar_info_pedidos(pedidos, estoque, coords, deposito, dist)
rotas = clarke_wright(infos, deposito, dist, criterio)

for (k, rota) in enumerate(rotas)
    seq = sequencia_estantes_rota(rota, infos, coords, deposito, dist)
    println("Funcionario $k: pedidos $rota | estantes na ordem: $seq")
end