# src/types.jl

struct SKU
    frequency::Int
    quantity::Float64
    volume::Float64
end

struct Location
    id::Int
    aisle::Int
    shelf::Int
    capacity::Int
end

struct Cluster
    skus::Vector{Int}
    average_frequency::Float64
end

struct ClusteringResult
    clusters::Vector{Cluster}
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

struct CooccurrenceMatrix
    matrix::Matrix{Int}
    frequency::Vector{Int}
end