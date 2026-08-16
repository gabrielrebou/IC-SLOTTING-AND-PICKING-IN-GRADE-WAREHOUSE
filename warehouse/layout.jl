include("locations.jl")

function create_warehouse(n_aisles, n_shelves, capacity)

    locations = generate_locations(n_aisles,n_shelves, capacity)

    depot = Location(0, 0, 0, 0)

    return Warehouse(
        locations,
        depot
    )
end

function custom_manhattan(pos1::Location, pos2::Location)
    if pos1.shelf != pos2.shelf
        return abs(pos1.aisle) + abs(pos2.aisle) + abs(pos1.shelf - pos2.shelf)
    else
        return abs(pos1.aisle - pos2.aisle)
    end 
end

function compute_depot_distance(warehouse::Warehouse)
    depot = warehouse.depot
    locations = warehouse.locations
    n_locations = length(locations)

    depot_distance = Vector{Float64}(undef, n_locations)

    for i in 1:n_locations
        depot_distance[i] = custom_manhattan(depot, locations[i])
    end

    return depot_distance
end