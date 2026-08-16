function allocation_main(do_allocation, do_mensage_passing, data_id, data_names, n_aisles, n_shelves, capacity, sigma, v_tipico, p_frequency, p_volume, p_quantity, volumetricModule, warehouse_capacity, warehouse_filling_rate, seed, candidate_fraction, als_k, als_factor, distance_factor, message_passing_factor, max_variety)
    
    results_dir = joinpath(@__DIR__, "..","Results")
    allocation_file = joinpath(results_dir, "allocation.txt")
    
    if do_allocation || do_mensage_passing
        
        # Limpa a pasta Results/allocation (apaga se existir e recria vazia)
        rm(results_dir, recursive=true, force=true)
        mkpath(results_dir)

        instance = read_instance(joinpath(@__DIR__, "..", "data", data_names[data_id]))
        warehouse = create_warehouse(n_aisles, n_shelves, capacity) 
        #return warehouse{locations, depot}
        #locations{id, aisle, shelf, capacity}, depot{id, aisle, shelf, capacity}

        depot_distance = compute_depot_distance(warehouse)
        depot_id = warehouse.depot.id

        cooc = cooccurrence_matrix(instance.orders, instance.n_skus)
        #return cooc{matrix[Int], frequency[Int]}
        skus = generate_skus(
            sigma, v_tipico, p_frequency, p_volume, p_quantity, 
            volumetricModule, capacity, warehouse_capacity, 
            warehouse_filling_rate, instance, seed
        )
        #return skus[SKU{frequency, quantity, volume}]

        sparse_matrix = build_sparse_matrix(skus, warehouse, candidate_fraction)
        #return sparse_matrix{matrix[Float64], row_indices[Int], col_indices[Int]}
        U, V = als(sparse_matrix; k=als_k, λ=als_factor, maxiter=100, tol=1e-4, seed=seed)
        #return U[rows, cols], V[rows, cols]
        S_hat = U * V'
        Distance_matrix = build_distances(warehouse.locations)
        #return Distance_matrix{matrix[Float64], row_indices[Int], col_indices[Int]}
        if do_mensage_passing
            W = correlation_distances(Distance_matrix, distance_factor)
            #return W{matrix[Float64], row_indices[Int], col_indices[Int]}
            P = norm_cooccurrence(cooc.matrix)
            #return P{matrix[Float64], row_indices[Int], col_indices[Int]}
            S_hat_hat = (1-message_passing_factor) * S_hat + message_passing_factor * W * S_hat * P
            # depois tentar S_hat_hat = α * S_hat + β * S_hat * P + γ * W * S_hat + δ * W * S_hat * P
            # com α+β+γ+δ=1.
            allocations = allocate(S_hat_hat, skus, warehouse, max_variety)
            #return allocations{matrix[Int], row_indices[Int], col_indices[Int]}
            serialize(allocation_file, (instance, warehouse, depot_distance, depot_id, cooc, skus, sparse_matrix, U, V, S_hat, Distance_matrix, W, P, S_hat_hat, allocations))
            print_allocation(warehouse, instance, cooc, skus, sparse_matrix, S_hat, P, W, S_hat_hat, allocations, do_mensage_passing)
            heatmap_main(P, "Matriz de Coocorrência Normalizada")
            heatmap_main(W, "Matriz de Correlação de Distância")
            heatmap_main(S_hat_hat, "Matriz S_hat_hat do Message Passing")
        else
            allocations = allocate(S_hat, skus, warehouse, max_variety)
            #return allocations{matrix[Int], row_indices[Int], col_indices[Int]}
            serialize(allocation_file, (instance, warehouse, depot_distance, depot_id, cooc, skus, sparse_matrix, U, V, S_hat, Distance_matrix, [0 0], [0 0], [0 0], allocations))
            print_allocation(warehouse, instance, cooc, skus, sparse_matrix, S_hat, [0 0], [0 0], [0 0], allocations, do_mensage_passing)
        end
        

        warehouse_graph(warehouse)
        heatmap_main(cooc.matrix, "Matriz de Coocorrência")
        heatmap_main(Distance_matrix, "Matriz de Distância")
        heatmap_main(S_hat, "Matriz S_hat do ALS")
        plot_allocation(allocations, warehouse)
    end
    if isfile(allocation_file)
        return deserialize(allocation_file)
    else
        @warn "Arquivo de alocacao nao encontrado: $allocation_file"
        return nothing
    end
end