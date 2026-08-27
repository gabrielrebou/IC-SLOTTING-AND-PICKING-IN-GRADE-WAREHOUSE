# src/General_functions/prints.jl

using Statistics

function print_allocation(warehouse::Warehouse, instance::Instance, cooc::CooccurrenceMatrix, skus::Vector{SKU}, sparse_matrix, S_hat::Matrix, P::Matrix, W::Matrix, S_hat_hat::Matrix, allocations::Matrix, do_message_passing::Bool)
    # Garante que a pasta Results existe (mesmo nível de main.jl, dentro de scr)
    results_dir = joinpath(@__DIR__, "..", "..", "Results_cache", "allocation")
    mkpath(results_dir)

    results_path = joinpath(results_dir, "Results.txt")
    # "w" sobrescreve o arquivo se já existir, ou cria um novo
    open(results_path, "w") do io

        println(io, "SKUs: ", instance.n_skus)
        println(io, "Pedidos: ", length(instance.orders))
        
        println(io, "\nPrimeiro pedido:")
        println(io, instance.orders[1])
        
        println(io, "\nUltimo pedido:")
        println(io, instance.orders[end])
        println(io, "")
        
        # Exibir as localizações do armazém
        for i in 1:warehouse.locations[end].id
            println(io, warehouse.locations[i])
        end
        
        # Exibir a matriz de coocorrencia
        println(io, "\nFrequencias: ", cooc.frequency)
        println(io, "\nMatriz de coocorrencia: ")
        show(io, "text/plain", cooc.matrix)
        println(io, "")
        
        # exibir os SKUs gerados
        for sku in skus
            println(io, sku)
        end
        
        println(io, "")
        if do_message_passing
            println(io, "extremidades das matrizes:")
            println(io, "S_hat: ", extrema(S_hat))
            println(io, "S_hat * P: ", extrema(S_hat * P))
            println(io, "W * S_hat: ", extrema(W * S_hat))
            println(io, "W * S_hat * P: ", extrema(W * S_hat * P))
            println(io, "correlacao{S_hat, S_hat_hat} = ", cor(vec(S_hat), vec(S_hat_hat)))
            println(io, "")
        end

        for loc in warehouse.locations
            if sum(allocations[loc.id, :]) > 0
                println(io, "Posicao $(loc.id) (Corredor $(loc.aisle), Prateleira $(loc.shelf))")
                
                for sku in axes(allocations, 2)
                    if allocations[loc.id, sku] > 0
                        println(io, "   SKU $sku -> $(allocations[loc.id, sku])")
                    end
                end
                
                println(io)
            end
        end
        
    end
    
    println("Resultados salvos em: ", results_path)
end

function print_pickers(
    cfg::ExperimentConfig,
    pickers_route::Vector{Pickers},
    data_name::String,
    distance::Float64,
    sum_pickers::Int
)
    folder_name = "$(cfg.data_id)-$(cfg.allocation_method)-$(cfg.routing_heuristic)-$(cfg.merge_strategy)"
    results_dir = joinpath(@__DIR__, "..", "..", "Results_cache", folder_name, "picker")
    mkpath(results_dir)
    results_path = joinpath(results_dir, "Results.txt")

    open(results_path, "w") do io
        for (i, picker) in enumerate(pickers_route)
            println(io, "Rota do Picker ", i, ": ", picker.picker_rout)
        end
        println(io, "")
        println(io, "Caso de teste: ", data_name)
        println(io, "")
        println(io, "Distancia Total: ", distance)
        println(io, "Quantidade de Pickers: ", sum_pickers)
    end
end