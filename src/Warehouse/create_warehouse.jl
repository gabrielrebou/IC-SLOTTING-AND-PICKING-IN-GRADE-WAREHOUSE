# src/Warehouse/create_warehouse.jl

function create_warehouse(cfg::ExperimentConfig,warehouseconfig::WarehouseConfig)

    #if cfg.shape == I fazer mais configs depois
    capacity, locations = generate_I_locations(warehouseconfig)

    depot = Location(0, 0, 0, 0)

    return Warehouse(
        locations,
        depot,
        capacity,
        warehouseconfig
    )
end