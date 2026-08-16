#using BenchmarkTools
using Plots
using Graphs
using Serialization

include("config.jl")

include("general_functions/types.jl")
include("general_functions/reader.jl")
include("general_functions/graphs.jl")
include("general_functions/prints.jl")
include("general_functions/terminal_reader.jl")

include("warehouse/layout.jl")
include("warehouse/build_distances.jl")
include("warehouse/correlation_distances.jl")

include("clustering/cooccurrence.jl")
#include("clustering/kmeans.jl")

include("inventory_sizing/generate_skus_lognormal.jl")

include("slotting/als.jl")
include("slotting/allocation_main.jl")
include("slotting/build_sparse_matrix.jl")
include("slotting/MILP_als.jl")

include("picking/pickers_A_star.jl")
include("picking/astar_next_shelf.jl")
include("picking/heuristic.jl")
include("picking/pickers_merge.jl")

do_allocation = read_bool("Deseja realizar a alocacao?")
do_mensage_passing = false
if do_allocation
    do_mensage_passing = read_bool("Deseja realizar mensage_passing?")
end
data_id = read_int_range("Selecione o ID dos dados", length(data_names))

mark = @timed allocation_main(
    do_allocation, do_mensage_passing, data_id, data_names, n_aisles, n_shelves, 
    capacity, sigma, v_tipico, p_frequency, p_volume, p_quantity, volumetricModule, 
    warehouse_capacity, warehouse_filling_rate, seed, candidate_fraction, als_k, 
    als_factor, distance_factor, message_passing_factor, max_variety
)

instance, warehouse, depot_distance, depot_id, cooc, skus, sparse_matrix, U, V, S_hat, Distance_matrix, P, W, S_hat_hat, allocations = mark.value

allocation_time = mark.time
allocation_bytes = mark.bytes

max_route, route_time, route_bytes = @timed route_orders(
    instance,
    allocations,
    skus,
    picker_capacity,
    warehouse,
    Distance_matrix
)

all_pickers = reduce(vcat, max_route)

sku_volume = [sku.volume for sku in skus]

merged_pickers, cw_time, cw_bytes = @timed clarke_wright(
    all_pickers,
    Distance_matrix,
    sku_volume,
    Float64(picker_capacity),
    depot_distance,
    depot_id
)

print_pickers(merged_pickers, do_allocation, do_mensage_passing, data_names[data_id], data_id, allocation_time, allocation_bytes, route_time, route_bytes, cw_time, cw_bytes)
println("Pressione Enter para sair e limpar o terminal...")
readline()
print("\033[2J\033[H")