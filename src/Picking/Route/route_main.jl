# src/Picking/Route/route_main.jl

function route_main(cfg::ExperimentConfig, params::Params, alloc_result)

    validate_positive(params.picking.picker_capacity, "picker_capacity")

    # Nota: cfg.routing_heuristic e o enum RoutingHeuristic em si.
    # route_orders -> route_order! ja despacham para a heuristica
    # correta via next_shelf_selector (Route/selector.jl), entao nao
    # ha necessidade de resolver um "next_shelf_fn" aqui.
    mark = @timed route_orders(
        cfg,
        alloc_result.instance,
        alloc_result.allocations,
        alloc_result.skus,
        params.picking.picker_capacity,
        alloc_result.warehouse,
        alloc_result.distance_matrix
    )

    pickers_by_order = mark.value
    route_time, route_bytes = mark.time, mark.bytes

    all_pickers = reduce(vcat, pickers_by_order)

    for picker in all_pickers
        validate_picker(picker)
    end

    distance, sum_pickers = calculate_picker_results(all_pickers)

    result = (;
        pickers = all_pickers,
        distance, sum_pickers,
        route_time, route_bytes
    )

    report_route(cfg, params, result)

    return result
end

function report_route(cfg::ExperimentConfig, params::Params, result)
    data_name = params.data_names[cfg.data_id]
    print_pickers(cfg, result.pickers, data_name, result.distance, result.sum_pickers)
end
