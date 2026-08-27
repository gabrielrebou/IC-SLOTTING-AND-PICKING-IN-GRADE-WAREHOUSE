# src/Slotting/ALS/MILP_als.jl

using JuMP
using HiGHS

function als_allocate(S_hat_hat, skus, warehouse, max_variety)

    n_locations = length(warehouse.locations)
    n_skus = length(skus)

    model = Model(HiGHS.Optimizer)
    set_time_limit_sec(model, 300.0)

    @variable(model, x[1:n_locations,1:n_skus] >= 0, Int)
    @variable(model, y[1:n_locations,1:n_skus], Bin)

    @objective(model, Max,
        sum(
            S_hat_hat[i,j] * x[i,j]
            for i in 1:n_locations, j in 1:n_skus
        )
    )

    # Todo SKU deve ser completamente alocado
    @constraint(model,
        [j in 1:n_skus],
        sum(x[i,j] for i in 1:n_locations) == skus[j].quantity
    )

    # Capacidade das posições
    @constraint(model,
        [i in 1:n_locations],
        sum(
            skus[j].volume * x[i,j]
            for j in 1:n_skus
        ) <= warehouse.locations[i].capacity
    )

    @constraint(model,
        [i=1:n_locations, j=1:n_skus],
        x[i,j] <= skus[j].quantity * y[i,j]
    )

    @constraint(model,
        [i=1:n_locations],
        sum(y[i,j] for j in 1:n_skus) <= max_variety
    )

    optimize!(model)

    status = termination_status(model)

    if status == TIME_LIMIT
        if primal_status(model) == FEASIBLE_POINT
            return Int.(round.(value.(x)))
        else
            return Matrix{Int}(undef, 0, 0)
        end
    elseif status != OPTIMAL
        return Matrix{Int}(undef, 0, 0)
    end
    return Int.(round.(value.(x)))
end