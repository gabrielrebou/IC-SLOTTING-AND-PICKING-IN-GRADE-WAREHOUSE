# src/Picking/Merge/position_utils.jl
#
# Antes em order_position.jl. Movido para Merge/ porque so e usado
# pelo clarke_wright_savings.jl (para aproximar cada picker por um
# centroide e calcular savings classicas), nao pelo roteamento em si.

# Centroide real das prateleiras visitadas por um picker, ponderado
# pela quantidade retirada em cada uma. Ignora os placeholders do
# deposito (id == warehouse.depot.id) no inicio/fim da rota.
function picker_position(
    picker::Pickers,
    warehouse::Warehouse
)
    validate_picker(picker)

    depot_id = warehouse.depot.id

    sum_aisle = 0.0
    sum_shelf = 0.0
    total_units = 0

    for (idx, loc_id) in enumerate(picker.picker_rout)

        loc_id == depot_id && continue

        units = length(picker.sku_shelf[idx])
        units == 0 && continue

        location = warehouse.locations[loc_id]

        sum_aisle += units * location.aisle
        sum_shelf += units * location.shelf
        total_units += units
    end

    if total_units == 0
        depot = warehouse.depot
        return (Float64(depot.aisle), Float64(depot.shelf))
    end

    return (sum_aisle / total_units, sum_shelf / total_units)
end