# Semente de aleatoriedade
const seed::Int = 239480

# Configurações do Armazém
const n_aisles::Int = 5
const n_shelves::Int = 10
const capacity::Int = 10
const volumetricModule::Float64 = 0.01
const warehouse_filling_rate::Float64 = 0.53

# Parâmetros do Modelo e Algoritmo
const sigma::Float64 = 0.5
const v_tipico::Float64 = 0.1
const p_frequency::Float64 = 0.8
const p_volume::Float64 = 1.2
const p_quantity::Float64 = 0.5
const candidate_fraction::Float64 = 0.4
const als_factor::Float64 = 0.1
const als_k::Int = 20
const distance_factor::Float64 = 0.1
const message_passing_factor::Float64 = 0.5
const max_variety::Int = 3
const picker_capacity::Int = 10

# (Modificáveis via terminal)
do_allocation::Bool = false
do_message_passing::Bool = false
data_id::Int = 1

# Arquivos de Dados
const data_names::Vector{String} = ["SLAPRP_Guo_small_O100_alpha0.2_v1.txt", "SLAPRP_Guo_small_O100_alpha0.2_v10.txt", "SLAPRP_Guo_small_O100_alpha0.2_v2.txt", "SLAPRP_Guo_small_O100_alpha0.2_v3.txt", "SLAPRP_Guo_small_O100_alpha0.2_v4.txt", "SLAPRP_Guo_small_O100_alpha0.2_v5.txt", "SLAPRP_Guo_small_O100_alpha0.2_v6.txt", "SLAPRP_Guo_small_O100_alpha0.2_v7.txt", "SLAPRP_Guo_small_O100_alpha0.2_v8.txt", "SLAPRP_Guo_small_O100_alpha0.2_v9.txt", "SLAPRP_Guo_small_O100_alpha0.3_v1.txt", "SLAPRP_Guo_small_O100_alpha0.3_v10.txt", "SLAPRP_Guo_small_O100_alpha0.3_v2.txt", "SLAPRP_Guo_small_O100_alpha0.3_v3.txt", "SLAPRP_Guo_small_O100_alpha0.3_v4.txt", "SLAPRP_Guo_small_O100_alpha0.3_v5.txt", "SLAPRP_Guo_small_O100_alpha0.3_v6.txt", "SLAPRP_Guo_small_O100_alpha0.3_v7.txt", "SLAPRP_Guo_small_O100_alpha0.3_v8.txt", "SLAPRP_Guo_small_O100_alpha0.3_v9.txt", "SLAPRP_Guo_small_O100_alpha0.4_v1.txt", "SLAPRP_Guo_small_O100_alpha0.4_v10.txt", "SLAPRP_Guo_small_O100_alpha0.4_v2.txt", "SLAPRP_Guo_small_O100_alpha0.4_v3.txt", "SLAPRP_Guo_small_O100_alpha0.4_v4.txt", "SLAPRP_Guo_small_O100_alpha0.4_v5.txt", "SLAPRP_Guo_small_O100_alpha0.4_v6.txt", "SLAPRP_Guo_small_O100_alpha0.4_v7.txt", "SLAPRP_Guo_small_O100_alpha0.4_v8.txt", "SLAPRP_Guo_small_O100_alpha0.4_v9.txt", "SLAPRP_Guo_small_O200_alpha0.2_v1.txt", "SLAPRP_Guo_small_O200_alpha0.2_v10.txt", "SLAPRP_Guo_small_O200_alpha0.2_v2.txt", "SLAPRP_Guo_small_O200_alpha0.2_v3.txt", "SLAPRP_Guo_small_O200_alpha0.2_v4.txt", "SLAPRP_Guo_small_O200_alpha0.2_v5.txt", "SLAPRP_Guo_small_O200_alpha0.2_v6.txt", "SLAPRP_Guo_small_O200_alpha0.2_v7.txt", "SLAPRP_Guo_small_O200_alpha0.2_v8.txt", "SLAPRP_Guo_small_O200_alpha0.2_v9.txt", "SLAPRP_Guo_small_O200_alpha0.3_v1.txt", "SLAPRP_Guo_small_O200_alpha0.3_v10.txt", "SLAPRP_Guo_small_O200_alpha0.3_v2.txt", "SLAPRP_Guo_small_O200_alpha0.3_v3.txt", "SLAPRP_Guo_small_O200_alpha0.3_v4.txt", "SLAPRP_Guo_small_O200_alpha0.3_v5.txt", "SLAPRP_Guo_small_O200_alpha0.3_v6.txt", "SLAPRP_Guo_small_O200_alpha0.3_v7.txt", "SLAPRP_Guo_small_O200_alpha0.3_v8.txt", "SLAPRP_Guo_small_O200_alpha0.3_v9.txt", "SLAPRP_Guo_small_O200_alpha0.4_v1.txt", "SLAPRP_Guo_small_O200_alpha0.4_v10.txt", "SLAPRP_Guo_small_O200_alpha0.4_v2.txt", "SLAPRP_Guo_small_O200_alpha0.4_v3.txt", "SLAPRP_Guo_small_O200_alpha0.4_v4.txt", "SLAPRP_Guo_small_O200_alpha0.4_v5.txt", "SLAPRP_Guo_small_O200_alpha0.4_v6.txt", "SLAPRP_Guo_small_O200_alpha0.4_v7.txt", "SLAPRP_Guo_small_O200_alpha0.4_v8.txt", "SLAPRP_Guo_small_O200_alpha0.4_v9.txt", "SLAPRP_Guo_small_O50_alpha0.2_v1.txt", "SLAPRP_Guo_small_O50_alpha0.2_v10.txt", "SLAPRP_Guo_small_O50_alpha0.2_v2.txt", "SLAPRP_Guo_small_O50_alpha0.2_v3.txt", "SLAPRP_Guo_small_O50_alpha0.2_v4.txt", "SLAPRP_Guo_small_O50_alpha0.2_v5.txt", "SLAPRP_Guo_small_O50_alpha0.2_v6.txt", "SLAPRP_Guo_small_O50_alpha0.2_v7.txt", "SLAPRP_Guo_small_O50_alpha0.2_v8.txt", "SLAPRP_Guo_small_O50_alpha0.2_v9.txt", "SLAPRP_Guo_small_O50_alpha0.3_v1.txt", "SLAPRP_Guo_small_O50_alpha0.3_v10.txt", "SLAPRP_Guo_small_O50_alpha0.3_v2.txt", "SLAPRP_Guo_small_O50_alpha0.3_v3.txt", "SLAPRP_Guo_small_O50_alpha0.3_v4.txt", "SLAPRP_Guo_small_O50_alpha0.3_v5.txt", "SLAPRP_Guo_small_O50_alpha0.3_v6.txt", "SLAPRP_Guo_small_O50_alpha0.3_v7.txt", "SLAPRP_Guo_small_O50_alpha0.3_v8.txt", "SLAPRP_Guo_small_O50_alpha0.3_v9.txt", "SLAPRP_Guo_small_O50_alpha0.4_v1.txt", "SLAPRP_Guo_small_O50_alpha0.4_v10.txt", "SLAPRP_Guo_small_O50_alpha0.4_v2.txt", "SLAPRP_Guo_small_O50_alpha0.4_v3.txt", "SLAPRP_Guo_small_O50_alpha0.4_v4.txt", "SLAPRP_Guo_small_O50_alpha0.4_v5.txt", "SLAPRP_Guo_small_O50_alpha0.4_v6.txt", "SLAPRP_Guo_small_O50_alpha0.4_v7.txt", "SLAPRP_Guo_small_O50_alpha0.4_v8.txt", "SLAPRP_Guo_small_O50_alpha0.4_v9.txt"]

const warehouse_capacity = n_aisles * n_shelves * capacity

