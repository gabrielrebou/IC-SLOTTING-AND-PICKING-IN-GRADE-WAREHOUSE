# src/types.jl

struct Location
    id::Int
    aisle::Int
    shelf::Int
    capacity::Int
end

struct Warehouse
    locations::Vector{Location}
    depot::Location
end

struct Order
    id::Int
    skus::Vector{Int}
end

struct Instance
    n_skus::Int
    orders::Vector{Order}
end

struct SKU
    frequency::Int
    quantity::Float64
    volume::Float64
end

struct Cluster
    skus::Vector{Int}
    average_frequency::Float64
end

struct ClusteringResult
    clusters::Vector{Cluster}
end

struct CooccurrenceMatrix
    matrix::Matrix{Int}
    frequency::Vector{Int}
end

struct Pickers
    picker_rout::Vector{Int}
    sku_shelf::Vector{Vector{Int}}
    distance::Vector{Float64}
end