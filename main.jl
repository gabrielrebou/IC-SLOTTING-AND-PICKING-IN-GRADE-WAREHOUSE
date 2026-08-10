#using BenchmarkTools
using Plots
using Graphs

if !haskey(ENV, "DISPLAY") && Sys.islinux()
    ENV["GKSwstype"] = "100"  # renderiza sem tentar abrir janela
end

# Limpa a pasta Results (apaga se existir e recria vazia)
results_dir = joinpath(@__DIR__, "Results")
rm(results_dir, recursive=true, force=true)
mkpath(results_dir)

include("types.jl")
include("reader.jl")
include("graphs.jl")
include("prints.jl")
include("warehouse/layout.jl")
include("clustering/cooccurrence.jl")
include("clustering/kmeans.jl")
include("inventory_sizing/generate_skus_lognormal.jl")
include("slotting/build_sparse_matrix.jl")
include("slotting/als.jl")
include("slotting/build_w.jl")
include("slotting/MILP_als.jl")

# Variáveis de configuração
seed = 239480
n_aisles = 5
n_shelves = 10
volumetricModule = 0.01       
capacity = 10                 
warehouse_filling_rate = 0.53 
sigma = 0.5                   
v_tipico = 0.1               
p_frequency = 0.8             
p_volume = 1.2               
p_quantity = 0.5              
candidate_fraction = 0.4      
als_factor = 0.1              
als_k = 20                    
distance_factor = 0.1         
message_passing_factor = 0.5      
max_variety = 3                    

warehouse_capacity = n_aisles * n_shelves * capacity

instance = read_instance(joinpath(@__DIR__, "data", "SLAPRP_Guo_small_O200_alpha0.4_v9.txt"))
warehouse = create_warehouse(n_aisles, n_shelves, capacity)

cooc = cooccurrence_matrix(instance.orders, instance.n_skus)

skus = generate_skus(
    sigma, v_tipico, p_frequency, p_volume, p_quantity, 
    volumetricModule, capacity, warehouse_capacity, 
    warehouse_filling_rate, instance, seed
)

sparse_matrix = build_sparse_matrix(skus, warehouse, candidate_fraction)
U, V = als(sparse_matrix; k=als_k, λ=als_factor, maxiter=100, tol=1e-4, seed=seed)
S_hat = U * V'
W = build_W(warehouse.locations, distance_factor)
P = norm_cooccurrence(cooc.matrix)
S_hat_hat = (1-message_passing_factor) * S_hat + message_passing_factor * W * S_hat * P
# depois tentar S_hat_hat = α * S_hat + β * S_hat * P + γ * W * S_hat + δ * W * S_hat * P
# com α+β+γ+δ=1.
allocations = allocate(S_hat_hat, skus, warehouse, max_variety)

print_main(warehouse, instance, cooc, skus, sparse_matrix, S_hat, P, W, S_hat_hat, allocations)
warehouse_graph(warehouse)
heatmap_main(cooc.matrix, "Matriz de Coocorrência")
heatmap_main(P, "Matriz de Coocorrência Normalizada")
heatmap_main(W, "Matriz de Distância")
heatmap_main(S_hat, "Matriz S_hat do ALS")
heatmap_main(S_hat_hat, "Matriz S_hat_hat do Message Passing")
plot_allocation(allocations, warehouse)

println("Pressione Enter para sair...")
readline()