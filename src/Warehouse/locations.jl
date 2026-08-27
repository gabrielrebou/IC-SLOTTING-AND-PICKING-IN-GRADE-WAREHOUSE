# src/Warehouse/locations.jl

# Para facilitar as contas, ao invés de considerar o lado do corredor ('L','R'),
# vamos considerar que L é o lado negativo e R é o lado positivo, e que a prateleira 0 é a cabeceira do corredor.
function generate_I_locations(config::WarehouseConfig)

    locations = Location[]
    id = 1
    capacity = 0

    for aisle in 1:config.n_aisles
        for side in (-1, 1)

            for shelf in 1:(config.n_shelves - 1)

                push!(locations,
                    Location(id, aisle, side * shelf, 2 * config.shelf_capacity))
                capacity = capacity + 2 * config.shelf_capacity
                id += 1
            end
            
            # duas estantes no fim de cada corredor horizontal
            push!(locations,
            Location(id, aisle, side * config.n_shelves, 4 * config.shelf_capacity))
            capacity = capacity + 4 * config.shelf_capacity
            id += 1
            
        end
    end

    return capacity, locations
end