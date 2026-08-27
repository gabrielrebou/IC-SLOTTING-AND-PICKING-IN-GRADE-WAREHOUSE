# src/Slotting/allocation_main.jl

function allocation_main(cfg::ExperimentConfig, params::Params)

    instance = read_instance(joinpath(@__DIR__, "..", "..", "Data", params.data_names[cfg.data_id]))
    warehouse = create_warehouse(cfg,params.warehouse_config)
    depot_distance = compute_depot_distance(cfg,warehouse)
    depot_id = warehouse.depot.id

    cooc = cooccurrence_matrix(instance.orders, instance.n_skus)
    skus = generate_skus(params, instance, warehouse)

    distance_matrix = build_distance_matrix(cfg,warehouse.locations)

    empty_matrix = Matrix{Float64}(undef, 0, 0)
    sparse_matrix = U = V = S_hat = W = P = S_hat_hat = empty_matrix

    if cfg.allocation_method == ABC

        classes = abc_skus(skus)
        allocations = abc_allocation(skus, classes, warehouse, depot_distance, params.allocation.max_variety)

    elseif cfg.allocation_method == ABC_HEURISTIC

        classes = abc_skus(skus)
        allocations = abc_allocation_heuristic(
            skus, classes, cooc, warehouse, distance_matrix, depot_distance, params.allocation.max_variety
        )

    elseif cfg.allocation_method == ALS

        sparse_matrix = build_sparse_matrix(skus, warehouse, params.allocation.candidate_fraction)
        U, V = als(
            sparse_matrix;
            k = params.allocation.als_k,
            λ = params.allocation.als_factor,
            maxiter = 100,
            tol = 1e-4,
            seed = params.sku_generation.seed
        )
        S_hat = U * V'
        allocations = als_allocate(S_hat, skus, warehouse, params.allocation.max_variety)

    elseif cfg.allocation_method == MESSAGE_PASSING

        sparse_matrix = build_sparse_matrix(skus, warehouse, params.allocation.candidate_fraction)
        U, V = als(
            sparse_matrix;
            k = params.allocation.als_k,
            λ = params.allocation.als_factor,
            maxiter = 100,
            tol = 1e-4,
            seed = params.sku_generation.seed
        )
        S_hat = U * V'

        W = correlation_distances(distance_matrix, params.allocation.distance_factor)
        P = norm_cooccurrence(cooc.matrix)
        S_hat_hat = (1 - params.allocation.message_passing_factor) * S_hat +
                    params.allocation.message_passing_factor * W * S_hat * P

        allocations = als_allocate(S_hat_hat, skus, warehouse, params.allocation.max_variety)

    else
        error("Metodo de alocacao desconhecido: $(cfg.allocation_method)")
    end

    result = (;
        instance, warehouse, depot_distance, depot_id, cooc, skus,
        sparse_matrix, U, V, S_hat, distance_matrix, W, P, S_hat_hat,
        allocations
    )

    if !isempty(allocations)
        report_allocation(cfg, result)
    end

    return result
end

# Efeitos colaterais (prints, heatmaps, gráficos) isolados numa função
# separada, para não misturar cálculo com relatório — e para não gerar
# nenhum gráfico quando o resultado vier direto do cache.
function report_allocation(cfg::ExperimentConfig, result)

    do_message_passing = cfg.allocation_method == MESSAGE_PASSING

    print_allocation(
        result.warehouse, result.instance, result.cooc, result.skus,
        result.sparse_matrix, result.S_hat, result.P, result.W, result.S_hat_hat,
        result.allocations, do_message_passing
    )

    warehouse_graph(result.warehouse)
    heatmap_main(result.cooc.matrix, "Matriz de Coocorrência")
    heatmap_main(result.distance_matrix, "Matriz de Distância")
    plot_allocation(result.allocations, result.warehouse)

    if cfg.allocation_method in (ALS, MESSAGE_PASSING)
        heatmap_main(result.S_hat, "Matriz S_hat do ALS")
    end

    if do_message_passing
        heatmap_main(result.P, "Matriz de Coocorrência Normalizada")
        heatmap_main(result.W, "Matriz de Correlação de Distância")
        heatmap_main(result.S_hat_hat, "Matriz S_hat_hat do Message Passing")
    end
end