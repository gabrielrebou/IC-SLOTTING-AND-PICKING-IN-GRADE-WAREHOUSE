# src/Warehouse/distance.jl

using LinearAlgebra
function custom_manhattan(pos1::Location, pos2::Location)
    if pos1.shelf != pos2.shelf
        return abs(pos1.aisle) + abs(pos2.aisle) +
               abs(pos1.shelf - pos2.shelf)
    else
        return abs(pos1.aisle - pos2.aisle)
    end
end

function custom_manhattan(pos1::Tuple{<:Real,<:Real}, pos2::Tuple{<:Real,<:Real})
    if pos1[2] != pos2[2]
        return abs(pos1[1]) + abs(pos2[1]) +
               abs(pos1[2] - pos2[2])
    else
        return abs(pos1[1] - pos2[1])
    end
end

function compute_distance(cfg::ExperimentConfig, pos1::Location, pos2::Location)
    #if cfg.distance_method == CUSTOM_MANHATTAN fazer mais configs depois
    return custom_manhattan(pos1,pos2)
end

function compute_depot_distance(cfg::ExperimentConfig,warehouse::Warehouse)
    depot = warehouse.depot
    locations = warehouse.locations
    n_locations = length(locations)

    depot_distance = Vector{Float64}(undef, n_locations)

    
    for i in 1:n_locations
        depot_distance[i] = compute_distance(cfg, depot, locations[i])
    end

    return depot_distance
end

# matriz de difusão de distancia para o message passing
function correlation_distances(Distances::Matrix{Float64}, distance_factor::Float64)
    n = size(Distances, 1)
    W = Matrix{Float64}(undef, n, n)
    for i in 1:n
        for j in 1:n
            W[i, j] = distance_factor/(Distances[i, j] + distance_factor)
            if abs(W[i, j]) <= 0.001   #avaliar isso depois, pode afetar
                W[i, j] = 0
            end
        end
    end
    return W
end

function build_distance_matrix(cfg::ExperimentConfig,locations::Vector{Location})
    
    n = length(locations)
    W = Matrix{Float64}(undef, n, n)
    
    for i in 1:n
        for j in 1:n
            W[i, j] = compute_distance(cfg, locations[i], locations[j])
        end
    end

    return W
end