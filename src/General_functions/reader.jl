# src/General_functions/reader.jl

function read_instance(filename)

    lines = readlines(filename)

    n_skus = parse(Int, strip(lines[3]))
    n_orders = parse(Int, strip(lines[4]))

    orders = Order[]

    for i in 1:n_orders
        skus = parse.(Int, split(strip(lines[5 + i])))
        push!(orders, Order(i, skus))
    end

    return Instance(
        n_skus,
        orders
    )

end

function read_bool(prompt::String)::Bool
    print(prompt, " (y/n): ")
    while true
        input = lowercase(strip(readline()))
        input == "" && continue
        input == "y" && return true
        input == "n" && return false
        println("Entrada invalida. Por favor, digite 'y' para sim, ou 'n' para nao.")
    end
end

function read_int_range(prompt::String, max_val::Int, min_val::Int)::Int
    print(prompt, " ($min_val a $max_val): ")
    while true
        input = strip(readline())
        val = input == "" ? nothing : tryparse(Int, input)
        if val !== nothing && min_val <= val <= max_val
            return val
        end
        println("Entrada invalida. Digite um numero inteiro entre $min_val e $max_val.")
    end
end

function read_enum_choice(prompt::String, ::Type{E}) where {E <: Enum}
    options = instances(E)

    println(prompt)
    for (i, opt) in enumerate(options)
        println("  $i) $opt")
    end

    idx = read_int_range("Escolha", length(options),1)
    return options[idx]
end

function read_data_id(params::Params)::Int
    return read_int_range("Escolha o id dos dados", length(params.data_names),1)
end

# Le os 4 campos de um ExperimentConfig, um por um.
function read_experiment_config(params::Params)::ExperimentConfig
    data_id = read_data_id(params)
    allocation_method = read_enum_choice("Metodo de alocacao:", AllocationMethod)
    println("teste",AllocationMethod)
    routing_heuristic = read_enum_choice("Heuristica de roteamento:", RoutingHeuristic)
    merge_strategy = read_enum_choice("Estrategia de merge:", MergeHeuristic)

    return ExperimentConfig(data_id, allocation_method, routing_heuristic, merge_strategy)
end

# Pergunta se vai rodar o loop completo ou um caso isolado.
function read_run_mode()::Symbol
    println("Modo de execucao:")
    println("  1) Rodar um caso isolado")
    println("  2) Rodar mais de um caso (loop)")

    choice = read_int_range("Escolha", 2, 1)
    return choice == 1 ? :single : :batch
end

# Valido tanto para o modo batch quanto para o single: se 'n', reaproveita
# o arquivo de alocacao em cache (se existir) em vez de recalcular.
function read_do_allocation()::Bool
    return read_bool("Executar a etapa de alocacao (se 'n', reaproveita o arquivo salvo, se existir)")
end