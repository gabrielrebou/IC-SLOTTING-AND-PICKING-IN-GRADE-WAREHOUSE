# src/General_function/save_files

# Resultados: acumula em memória e escreve o CSV uma única vez no final
const results_rows = NamedTuple[]

function save_files(
    cfg::ExperimentConfig, data_name::String,
    allocation_time, allocation_bytes, route_time, route_bytes,
    merge_time, merge_bytes, distance, sum_pickers
)
    push!(results_rows, (;
        data_id = cfg.data_id,
        data_name = data_name,
        #distance_method = cfg.distance_method,
        #shape_method = cfg.allocation_method,
        allocation_method = cfg.allocation_method,
        routing_heuristic = cfg.routing_heuristic,
        merge_strategy = cfg.merge_strategy,
        allocation_time, allocation_bytes,
        route_time, route_bytes,
        merge_time, merge_bytes,
        distance, sum_pickers
    ))
end

function write_results_csv()
    compare_dir = joinpath(@__DIR__, "..", "..")
    mkpath(compare_dir)
    CSV.write(joinpath(compare_dir, "compare.csv"), DataFrame(results_rows))
end