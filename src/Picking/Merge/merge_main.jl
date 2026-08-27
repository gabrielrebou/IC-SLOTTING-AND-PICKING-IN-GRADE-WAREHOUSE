# src/Picking/Merge/merge_main.jl
#
# ATENCAO / AJUSTE NECESSARIO NO SEU PIPELINE:
# route_main so retorna (; pickers, distance, sum_pickers, route_time,
# route_bytes) -- nao carrega adiante warehouse/distance_matrix/skus.
# merge_main precisa dessas informacoes (para recalcular
# depot_distance e, no caso de CLARKE_WRIGHT_SAVINGS, os centroides),
# entao ele recebe alloc_result (mesmo argumento de route_main) alem
# de route_result. Se preferir nao repassar alloc_result, adicione
# warehouse/distance_matrix/skus ao NamedTuple retornado por
# route_main e simplifique as duas linhas abaixo que os leem de
# alloc_result.
function merge_main(cfg::ExperimentConfig, params::Params, alloc_result, route_result)

    validate_positive(params.picking.picker_capacity, "picker_capacity")

    sku_volume = [sku.volume for sku in alloc_result.skus]
    depot_distance = compute_depot_distance(cfg,alloc_result.warehouse)

    mark = @timed merge_selector(
        cfg.merge_strategy,
        route_result.pickers,
        alloc_result.distance_matrix,
        sku_volume,
        Float64(params.picking.picker_capacity),
        depot_distance,
        alloc_result.warehouse.depot.id,
        alloc_result.warehouse
    )

    merged_pickers = mark.value
    merge_time, merge_bytes = mark.time, mark.bytes

    for picker in merged_pickers
        validate_picker(picker)
    end

    distance, sum_pickers = calculate_picker_results(merged_pickers)

    result = (;
        pickers = merged_pickers,
        distance, sum_pickers,
        merge_time, merge_bytes
    )

    report_merge(cfg, params, result)

    return result
end

function report_merge(cfg::ExperimentConfig, params::Params, result)
    data_name = params.data_names[cfg.data_id]
    print_pickers(cfg, result.pickers, data_name, result.distance, result.sum_pickers)
end
