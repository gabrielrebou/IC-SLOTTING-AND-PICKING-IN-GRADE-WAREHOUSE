
using Statistics

function print_main(warehouse::Warehouse, instance::Instance, cooc::CooccurrenceMatrix, skus::Vector{SKU}, sparse_matrix, S_hat, P, W, S_hat_hat, allocations)

    # Garante que a pasta Results existe (mesmo nível de main.jl, dentro de scr)
    results_dir = joinpath(@__DIR__, "Results")
    mkpath(results_dir)  # cria a pasta se não existir; não faz nada se já existir

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
        
        println(io, extrema(S_hat))
        println(io, extrema(S_hat * P))
        println(io, extrema(W * S_hat))
        println(io, extrema(W * S_hat * P))
        println(io, "correlacao = ", cor(vec(S_hat), vec(S_hat_hat)))
        
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