# src/main.jl

print("\033[2J\033[H")
printstyled("\nPode demorar um pouco para inicializar, por favor aguarde"; color = :blue, bold = true)
println("")

include(joinpath(@__DIR__, "General_functions/types.jl"))
include(joinpath(@__DIR__, "General_functions/config.jl"))
include(joinpath(@__DIR__, "General_functions/reader.jl"))
include(joinpath(@__DIR__, "General_functions/graphs.jl"))
include(joinpath(@__DIR__, "General_functions/prints.jl"))
include(joinpath(@__DIR__, "General_functions/save_files.jl"))

include(joinpath(@__DIR__, "Warehouse/create_warehouse.jl"))
include(joinpath(@__DIR__, "Warehouse/distance.jl"))
include(joinpath(@__DIR__, "Warehouse/locations.jl"))

include(joinpath(@__DIR__, "Inventory_sizing/generate_skus_lognormal.jl"))

include(joinpath(@__DIR__, "Slotting/cooccurrence.jl"))
include(joinpath(@__DIR__, "Slotting/allocation_main.jl"))
include(joinpath(@__DIR__, "Slotting/ALS/als.jl"))
include(joinpath(@__DIR__, "Slotting/ALS/build_sparse_matrix.jl"))
include(joinpath(@__DIR__, "Slotting/ALS/MILP_als.jl"))
include(joinpath(@__DIR__, "Slotting/ALS/PPMI_G-test.jl"))
include(joinpath(@__DIR__, "Slotting/ABC/abc_classifier.jl"))
include(joinpath(@__DIR__, "Slotting/ABC/abc_allocation.jl"))
include(joinpath(@__DIR__, "Slotting/ABC/abc_heuristic_allocation.jl"))

include(joinpath(@__DIR__, "Picking/Route/heuristics/astar_heuristic.jl"))
include(joinpath(@__DIR__, "Picking/Route/heuristics/greedy_heuristic.jl"))
include(joinpath(@__DIR__, "Picking/Route/route_main.jl"))
include(joinpath(@__DIR__, "Picking/Route/route_orders.jl"))
include(joinpath(@__DIR__, "Picking/Route/selector.jl"))

include(joinpath(@__DIR__, "Picking/Merge/heuristics/clarke_wright_greedy.jl"))
include(joinpath(@__DIR__, "Picking/Merge/heuristics/clarke_wright_savings.jl"))
include(joinpath(@__DIR__, "Picking/Merge/merge_main.jl"))
include(joinpath(@__DIR__, "Picking/Merge/merge_routes.jl"))
include(joinpath(@__DIR__, "Picking/Merge/picker_core.jl"))
include(joinpath(@__DIR__, "Picking/Merge/position_utils.jl"))
include(joinpath(@__DIR__, "Picking/Merge/selector.jl"))

include(joinpath(@__DIR__, "Picking/validation.jl"))

include(joinpath(@__DIR__, "experiment_runner.jl"))

function main()
    mode = read_run_mode()

    if mode == :batch
        do_allocation = read_do_allocation()
        run_batch(params, do_allocation)
    else
        cfg = read_experiment_config(params)
        do_allocation = read_do_allocation()
        run_experiment(cfg, params, do_allocation)
    end

    write_results_csv()

    println("Execucao finalizada. Pressione Enter para sair e limpar o terminal...")
    readline()
    print("\033[2J\033[H")
end

main()