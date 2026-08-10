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