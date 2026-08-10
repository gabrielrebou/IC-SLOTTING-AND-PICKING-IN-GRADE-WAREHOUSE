
function order_locations(warehouse::Warehouse)

    return sort(warehouse.locations,
        by = l -> abs(l.aisle - warehouse.depot[1]) +
                  abs(l.shelf - warehouse.depot[2])
    )
end