# src/general_functions/config.jl

const params = Params(
    WarehouseConfig(
        5,      # n_aisles
        10,     # n_shelves
        10,     # shelf_capacity
        0.53    # filling_rate
    ),
    SKUGenerationParams(
        0.5,    # sigma
        0.1,    # tipic_v
        0.8,    # p_frequency
        1.2,    # p_volume
        0.5,    # p_quantity
        0.01,   # volumetric_module
        239480  # seed
    ),
    AllocationParams(
        0.4,    # candidate_fraction
        20,     # als_k
        0.1,    # als_factor
        0.1,    # distance_factor
        0.5,    # message_passing_factor
        3       # max_variety
    ),
    PickingParams(
        10      # picker_capacity
    ),
    [
        "SLAPRP_Guo_small_O100_alpha0.2_v1.txt", "SLAPRP_Guo_small_O100_alpha0.2_v10.txt",
        "SLAPRP_Guo_small_O100_alpha0.2_v2.txt", "SLAPRP_Guo_small_O100_alpha0.2_v3.txt",
        "SLAPRP_Guo_small_O100_alpha0.2_v4.txt", "SLAPRP_Guo_small_O100_alpha0.2_v5.txt",
        "SLAPRP_Guo_small_O100_alpha0.2_v6.txt", "SLAPRP_Guo_small_O100_alpha0.2_v7.txt",
        "SLAPRP_Guo_small_O100_alpha0.2_v8.txt", "SLAPRP_Guo_small_O100_alpha0.2_v9.txt",
        "SLAPRP_Guo_small_O100_alpha0.3_v1.txt", "SLAPRP_Guo_small_O100_alpha0.3_v10.txt",
        "SLAPRP_Guo_small_O100_alpha0.3_v2.txt", "SLAPRP_Guo_small_O100_alpha0.3_v3.txt",
        "SLAPRP_Guo_small_O100_alpha0.3_v4.txt", "SLAPRP_Guo_small_O100_alpha0.3_v5.txt",
        "SLAPRP_Guo_small_O100_alpha0.3_v6.txt", "SLAPRP_Guo_small_O100_alpha0.3_v7.txt",
        "SLAPRP_Guo_small_O100_alpha0.3_v8.txt", "SLAPRP_Guo_small_O100_alpha0.3_v9.txt",
        "SLAPRP_Guo_small_O100_alpha0.4_v1.txt", "SLAPRP_Guo_small_O100_alpha0.4_v10.txt",
        "SLAPRP_Guo_small_O100_alpha0.4_v2.txt", "SLAPRP_Guo_small_O100_alpha0.4_v3.txt",
        "SLAPRP_Guo_small_O100_alpha0.4_v4.txt", "SLAPRP_Guo_small_O100_alpha0.4_v5.txt",
        "SLAPRP_Guo_small_O100_alpha0.4_v6.txt", "SLAPRP_Guo_small_O100_alpha0.4_v7.txt",
        "SLAPRP_Guo_small_O100_alpha0.4_v8.txt", "SLAPRP_Guo_small_O100_alpha0.4_v9.txt",
        "SLAPRP_Guo_small_O200_alpha0.2_v1.txt", "SLAPRP_Guo_small_O200_alpha0.2_v10.txt",
        "SLAPRP_Guo_small_O200_alpha0.2_v2.txt", "SLAPRP_Guo_small_O200_alpha0.2_v3.txt",
        "SLAPRP_Guo_small_O200_alpha0.2_v4.txt", "SLAPRP_Guo_small_O200_alpha0.2_v5.txt",
        "SLAPRP_Guo_small_O200_alpha0.2_v6.txt", "SLAPRP_Guo_small_O200_alpha0.2_v7.txt",
        "SLAPRP_Guo_small_O200_alpha0.2_v8.txt", "SLAPRP_Guo_small_O200_alpha0.2_v9.txt",
        "SLAPRP_Guo_small_O200_alpha0.3_v1.txt", "SLAPRP_Guo_small_O200_alpha0.3_v10.txt",
        "SLAPRP_Guo_small_O200_alpha0.3_v2.txt", "SLAPRP_Guo_small_O200_alpha0.3_v3.txt",
        "SLAPRP_Guo_small_O200_alpha0.3_v4.txt", "SLAPRP_Guo_small_O200_alpha0.3_v5.txt",
        "SLAPRP_Guo_small_O200_alpha0.3_v6.txt", "SLAPRP_Guo_small_O200_alpha0.3_v7.txt",
        "SLAPRP_Guo_small_O200_alpha0.3_v8.txt", "SLAPRP_Guo_small_O200_alpha0.3_v9.txt",
        "SLAPRP_Guo_small_O200_alpha0.4_v1.txt", "SLAPRP_Guo_small_O200_alpha0.4_v10.txt",
        "SLAPRP_Guo_small_O200_alpha0.4_v2.txt", "SLAPRP_Guo_small_O200_alpha0.4_v3.txt",
        "SLAPRP_Guo_small_O200_alpha0.4_v4.txt", "SLAPRP_Guo_small_O200_alpha0.4_v5.txt",
        "SLAPRP_Guo_small_O200_alpha0.4_v6.txt", "SLAPRP_Guo_small_O200_alpha0.4_v7.txt",
        "SLAPRP_Guo_small_O200_alpha0.4_v8.txt", "SLAPRP_Guo_small_O200_alpha0.4_v9.txt",
        "SLAPRP_Guo_small_O50_alpha0.2_v1.txt", "SLAPRP_Guo_small_O50_alpha0.2_v10.txt",
        "SLAPRP_Guo_small_O50_alpha0.2_v2.txt", "SLAPRP_Guo_small_O50_alpha0.2_v3.txt",
        "SLAPRP_Guo_small_O50_alpha0.2_v4.txt", "SLAPRP_Guo_small_O50_alpha0.2_v5.txt",
        "SLAPRP_Guo_small_O50_alpha0.2_v6.txt", "SLAPRP_Guo_small_O50_alpha0.2_v7.txt",
        "SLAPRP_Guo_small_O50_alpha0.2_v8.txt", "SLAPRP_Guo_small_O50_alpha0.2_v9.txt",
        "SLAPRP_Guo_small_O50_alpha0.3_v1.txt", "SLAPRP_Guo_small_O50_alpha0.3_v10.txt",
        "SLAPRP_Guo_small_O50_alpha0.3_v2.txt", "SLAPRP_Guo_small_O50_alpha0.3_v3.txt",
        "SLAPRP_Guo_small_O50_alpha0.3_v4.txt", "SLAPRP_Guo_small_O50_alpha0.3_v5.txt",
        "SLAPRP_Guo_small_O50_alpha0.3_v6.txt", "SLAPRP_Guo_small_O50_alpha0.3_v7.txt",
        "SLAPRP_Guo_small_O50_alpha0.3_v8.txt", "SLAPRP_Guo_small_O50_alpha0.3_v9.txt",
        "SLAPRP_Guo_small_O50_alpha0.4_v1.txt", "SLAPRP_Guo_small_O50_alpha0.4_v10.txt",
        "SLAPRP_Guo_small_O50_alpha0.4_v2.txt", "SLAPRP_Guo_small_O50_alpha0.4_v3.txt",
        "SLAPRP_Guo_small_O50_alpha0.4_v4.txt", "SLAPRP_Guo_small_O50_alpha0.4_v5.txt",
        "SLAPRP_Guo_small_O50_alpha0.4_v6.txt", "SLAPRP_Guo_small_O50_alpha0.4_v7.txt",
        "SLAPRP_Guo_small_O50_alpha0.4_v8.txt", "SLAPRP_Guo_small_O50_alpha0.4_v9.txt"
    ]
)