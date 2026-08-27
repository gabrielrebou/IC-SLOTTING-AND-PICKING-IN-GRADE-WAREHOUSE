# src/Picking/validation.jl


# Funcoes de validacao reutilizaveis por Route/ e Merge/. Cada uma
# lanca ArgumentError (ou ErrorException, quando a inconsistencia so
# pode ser detectada apos calcular um resultado) com uma mensagem
# especifica, para que os modulos que as usam continuem
# independentes: nao precisam saber a razao da falha, so que ela
# ocorreu.

function validate_positive(value::Real, name::AbstractString)
    if value <= 0
        throw(ArgumentError("$name deve ser positivo, recebido: $value"))
    end
end

function validate_non_negative(value::Real, name::AbstractString)
    if value < 0
        throw(ArgumentError("$name nao pode ser negativo, recebido: $value"))
    end
end

function validate_same_length(a, b, name_a::AbstractString, name_b::AbstractString)
    if length(a) != length(b)
        throw(ArgumentError(
            "$name_a (tamanho $(length(a))) e $name_b (tamanho $(length(b))) devem ter o mesmo tamanho"
        ))
    end
end

function validate_route_endpoints(route::Vector{Int}, depot_id::Int)
    if isempty(route)
        throw(ArgumentError("rota nao pode ser vazia"))
    end

    if route[1] != depot_id || route[end] != depot_id
        throw(ArgumentError(
            "rota deve comecar e terminar no deposito (id=$depot_id), recebido: $(route[1])..$(route[end])"
        ))
    end
end

# Checa consistencia estrutural de um Pickers: os tres vetores
# (rota, skus por prateleira, distancia) precisam ter o mesmo
# tamanho, e nenhuma distancia pode ser negativa.
function validate_picker(picker::Pickers)
    validate_same_length(picker.picker_rout, picker.sku_shelf, "picker_rout", "sku_shelf")
    validate_same_length(picker.picker_rout, picker.distance, "picker_rout", "distance")

    for d in picker.distance
        validate_non_negative(d, "distance")
    end
end

function validate_capacity(load::Real, capacity::Real; context::AbstractString = "")
    if load > capacity
        label = isempty(context) ? "" : " ($context)"
        throw(ArgumentError("carga $load excede a capacidade $capacity$label"))
    end
end

function validate_index_bounds(index::Int, limit::Int, name::AbstractString)
    if index < 1 || index > limit
        throw(ArgumentError("$name fora dos limites: $index (esperado entre 1 e $limit)"))
    end
end
