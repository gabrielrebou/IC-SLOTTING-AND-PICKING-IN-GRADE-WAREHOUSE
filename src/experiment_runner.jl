# src/experiment_runner.jl

using CSV
using DataFrames
using Serialization

# allocation_cache_path: só data_id + allocation_method importam aqui
function allocation_cache_path(cfg::ExperimentConfig; base_dir="Results_cache")
    folder_name = "$(cfg.data_id)-$(cfg.allocation_method)"  # sem heuristic/merge

    dir = joinpath(@__DIR__, "..", base_dir, folder_name, "Allocation_cache")
    mkpath(dir)

    return joinpath(dir, "allocation_id$(cfg.data_id)_$(cfg.allocation_method).txt")
end

# Garante um resultado de alocação para (data_id, método):
#   do_allocation = true  -> roda allocation_main e substitui o cache existente
#   do_allocation = false -> reaproveita o cache; se não existir, cai para
#       o cálculo mesmo assim (com aviso), para nunca travar a execução
function ensure_allocation(cfg::ExperimentConfig, params::Params, do_allocation::Bool)

    if !do_allocation
        cache_file = allocation_cache_path(cfg; base_dir="Results")

        if isfile(cache_file)
            return deserialize(cache_file)
        end

        @warn "Alocacao nao encontrada para id=$(cfg.data_id), metodo=$(cfg.allocation_method); calculando mesmo assim."
    end

    result = allocation_main(cfg, params)

    if !isempty(result.allocations)
        cache_file = allocation_cache_path(cfg; base_dir="Results_cache")
        serialize(cache_file, result)
    end

    return result
end

# Execução de um experimento (compartilhada entre modo batch e single)
function run_experiment(cfg::ExperimentConfig, params::Params, do_allocation::Bool)
    mark = @timed ensure_allocation(cfg, params, do_allocation)
    run_experiment_with_allocation(cfg, params, mark.value, mark.time, mark.bytes)
end

# Recebe um resultado de alocação já pronto (usado pelo batch, que aloca
# uma vez só por (data_id, método) e reaproveita para todas as combinações
# de heurística/merge daquele par).
function run_experiment_with_allocation(
    cfg::ExperimentConfig,
    params::Params,
    alloc_result::NamedTuple,
    allocation_time::Float64,
    allocation_bytes::Int64
)

    if isempty(alloc_result.allocations)
        save_files(cfg, params.data_names[cfg.data_id], allocation_time, allocation_bytes,0,0,0,0,0,0)
        return nothing
    end
    
    max_route, route_time, route_bytes = @timed route_main(cfg,params,alloc_result)

    if cfg.merge_strategy == NO_HEURISTIC
        report_allocation(cfg,alloc_result)
        print_pickers(cfg, max_route.pickers, params.data_names[cfg.data_id], max_route.distance, max_route.sum_pickers)
        save_files(cfg, params.data_names[cfg.data_id], allocation_time, allocation_bytes, route_time, route_bytes, 0, 0, max_route.distance, max_route.sum_pickers)

    else
        merged_pickers, merge_time, merge_bytes = @timed merge_main(cfg,params,alloc_result,max_route)

        report_allocation(cfg,alloc_result)
        print_pickers(cfg, merged_pickers.pickers, params.data_names[cfg.data_id], merged_pickers.distance, merged_pickers.sum_pickers)
        save_files(cfg, params.data_names[cfg.data_id], allocation_time, allocation_bytes, route_time, route_bytes, merge_time, merge_bytes, merged_pickers.distance, merged_pickers.sum_pickers)
    end

    archive_results(cfg)

    return nothing
end

function archive_results(cfg::ExperimentConfig)
    results_cache_dir = joinpath(@__DIR__, "..", "Results_cache")
    results_dir = joinpath(@__DIR__, "..", "Results")
    mkpath(results_dir)

    # pasta do experimento completo (heuristica + merge) -> Results/
    exp_folder = "$(cfg.data_id)-$(cfg.allocation_method)-$(cfg.routing_heuristic)-$(cfg.merge_strategy)"
    cache_experiment_dir = joinpath(results_cache_dir, exp_folder)
    results_experiment_dir = joinpath(results_dir, exp_folder)

    if isdir(cache_experiment_dir)
        isdir(results_experiment_dir) && rm(results_experiment_dir; recursive=true, force=true)
        mkpath(results_experiment_dir)
        for item in readdir(cache_experiment_dir)
            cp(joinpath(cache_experiment_dir, item), joinpath(results_experiment_dir, item); force=true)
        end
        rm(cache_experiment_dir; recursive=true, force=true)  # só a pasta deste experimento
    end

    # pasta da alocação (só data_id + method) -> preservada entre combinações
    alloc_folder = "$(cfg.data_id)-$(cfg.allocation_method)"
    cache_alloc_dir = joinpath(results_cache_dir, alloc_folder)
    results_alloc_dir = joinpath(results_dir, alloc_folder)

    if isdir(cache_alloc_dir)
        mkpath(results_alloc_dir)
        for item in readdir(cache_alloc_dir)
            cp(joinpath(cache_alloc_dir, item), joinpath(results_alloc_dir, item); force=true)
        end
        rm(cache_alloc_dir; recursive=true, force=true)
    end
end

# Modo batch: aloca uma vez por (data_id, método), reaproveita para
# todas as combinações de heurística/merge daquele par
function run_batch(params::Params, do_allocation::Bool)
    min_val = read_int_range("escola o id de início: ",length(params.data_names),1)
    max_val = read_int_range("escolha o id de fim: ",length(params.data_names),min_val)
    for data_id in min_val:max_val
        for method in instances(AllocationMethod)

            # heuristica/merge nao importam para a alocacao em si; um
            # ExperimentConfig "provisorio" so para acessar o cache certo
            alloc_cfg = ExperimentConfig(data_id, method, ASTAR_HEURISTIC, NO_HEURISTIC)

            mark = @timed ensure_allocation(alloc_cfg, params, do_allocation)
            alloc_result = mark.value.allocations
            allocation_time, allocation_bytes = mark.time, mark.bytes

            for heuristic in instances(RoutingHeuristic), merge in instances(MergeHeuristic)

                cfg = ExperimentConfig(data_id, method, heuristic, merge)

                println(
                    "id: ", data_id,
                    "\nmetodo: ", method,
                    "\nheuristica: ", heuristic,
                    "\nmerge: ", merge
                )

                run_experiment_with_allocation(cfg, params, mark.value, allocation_time, allocation_bytes)

                print("\033[2J\033[H")
            end
        end
    end
end