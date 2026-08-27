# scr/Solotting/ABC/abc_allocation.jl

function abc_allocation(
    skus::Vector{SKU},
    classes::Vector{Char},
    warehouse::Warehouse,
    depot_distance::Vector{Float64},
    max_variety::Int
)
    n_sku = length(skus)
    n_loc = length(warehouse.locations)

    @assert length(classes) == n_sku "classes deve ter o mesmo tamanho de skus"
    @assert max_variety >= 1 "max_variety deve ser >= 1"

    sorted_locs = sort(warehouse.locations;
                        by = loc -> depot_distance[loc.id],
                        alg = MergeSort)

    class_rank(c::Char) = c == 'A' ? 1 :
                           c == 'B' ? 2 :
                           c == 'C' ? 3 : 4

    sku_order = sort(1:n_sku;
                      by = j -> (class_rank(classes[j]), -skus[j].frequency),
                      alg = MergeSort)

    remaining_cap_vol = Float64[loc.capacity for loc in warehouse.locations]
    variety_count = zeros(Int, n_loc)

    M = zeros(Int, n_loc, n_sku)

    for j in sku_order
        remaining_qty = round(Int, skus[j].quantity)
        vol = skus[j].volume

        for loc in sorted_locs
            remaining_qty <= 0 && break

            i = loc.id
            already_present = M[i, j] > 0

            # respeita o limite de variedades por estante
            if !already_present && variety_count[i] >= max_variety
                continue
            end

            cap = remaining_cap_vol[i]
            cap <= 0 && continue

            max_amount = floor(Int, cap / vol)
            alloc = min(remaining_qty, max_amount)
            alloc <= 0 && continue

            if !already_present
                variety_count[i] += 1
            end

            M[i, j] += alloc
            remaining_cap_vol[i] -= alloc * vol
            remaining_qty -= alloc
        end

        if remaining_qty > 0
            error("Nao foi possivel alocar o SKU $j por completo " *
                  "(faltaram $remaining_qty unidades) — capacidade de volume " *
                  "ou limite de max_variety insuficientes.")
        end
    end

    return M
end