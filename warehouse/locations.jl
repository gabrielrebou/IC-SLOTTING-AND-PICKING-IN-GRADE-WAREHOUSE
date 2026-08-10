# Para facilitar as contas, ao invés de considerar o lado do corredor ('L','R'),
# vamos considerar que L é o lado negativo e R é o lado positivo, e que a prateleira 0 é a cabeceira do corredor.

function generate_locations(n_aisles, n_shelves, capacity)

    locations = Location[]
    id = 1

    for aisle in 1:n_aisles
        for side in (-1, 1)

            for shelf in 1:(n_shelves - 1)

                push!(locations,
                    Location(id, aisle, side * shelf, 2 * capacity))

                id += 1
            end

            
            push!(locations,
            Location(id, aisle, side * n_shelves, 4 * capacity))
            id += 1
            
        end
    end

    return locations
end