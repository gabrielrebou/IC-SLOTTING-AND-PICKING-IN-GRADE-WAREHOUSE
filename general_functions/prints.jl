
using Statistics

function print_allocation(warehouse::Warehouse, instance::Instance, cooc::CooccurrenceMatrix, skus::Vector{SKU}, sparse_matrix, S_hat::Matrix, P::Matrix, W::Matrix, S_hat_hat::Matrix, allocations::Matrix, do_mensage_passing::Bool)
    # Garante que a pasta Results existe (mesmo nível de main.jl, dentro de scr)
    results_dir = joinpath(@__DIR__, "..", "Results", "allocation")
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
        if do_mensage_passing
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
    
    #matriz esparsa
    #println("\nMatriz esparsa: ")
    #display(sparse_matrix)
    #println("")
    
    #ALS
    #println("\nMatriz S_hat do ALS: ")
    #display(S_hat)
    #println("\nMatriz S_hat_hat do message passing: ")
    #display(S_hat_hat)
    
    # Exibir os clusters e suas características
    #println("\nNúmero de clusters: ", length(kmeans_result.clusters))
    #for (i, cluster) in enumerate(kmeans_result.clusters)
    
    #    println("Cluster ", i)
    #    println("Quantidade de SKUs: ", length(cluster.skus))
    #    println("Frequencia media: ", round(cluster.average_frequency, digits=2))
    #    println("SKUs: ", cluster.skus)
    #    println("Coocorrência interna: ", internal_cooccurrence(cluster, cooc))
    #end
    
    println("Resultados salvos em: ", results_path)
end

function print_pickers(pickers_route::Vector{Pickers}, do_allocation::Bool, do_mensage_passing::Bool, data_name::String, data_id::Int, allocation_time, allocation_bytes,route_time, route_bytes, cw_time, cw_bytes)

    results_dir = joinpath(@__DIR__, "..", "Results", "picker")
    mkpath(results_dir)

    results_path = joinpath(results_dir, "Results.txt")

    distance = 0.0
    sum_pickers = 0

    # "w" sobrescreve o arquivo se já existir, ou cria um novo
    open(results_path, "w") do io
            for picker in pickers_route
                sum_pickers += 1
                println(io, "Rota do Picker ",sum_pickers,": ", picker.picker_rout)
                
                distance += sum(picker.distance)
            end

        println(io, "")
        println(io, "Caso de teste: ", data_name)
        println(io, "")
        println(io, "allocation: ", do_allocation)
        println(io, "message passage: ", do_mensage_passing)
        println(io, "")
        println(io, "Distancia Total: ", distance)
        println(io, "Quantidade de Pickers: ", sum_pickers)
    end

    dir_path = joinpath(@__DIR__, "..", "Results_compare") 
    file_path = joinpath(dir_path, "compare.csv")

    if !isdir(dir_path)
        mkpath(dir_path)
    end

    open(file_path, "a") do io
        println(io, data_id,",",data_name,",",do_allocation,",",do_mensage_passing,",",allocation_time,",",allocation_bytes,",",route_time,",",route_bytes,",",cw_time,",",cw_bytes,",",distance,",",sum_pickers)
    end
end