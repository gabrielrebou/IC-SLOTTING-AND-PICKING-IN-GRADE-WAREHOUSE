function correlation_distances(Distances::Matrix{Float64}, distance_factor::Float64)
    n = size(Distances, 1)
    W = Matrix{Float64}(undef, n, n)
    for i in 1:n
        for j in 1:n
            W[i, j] = distance_factor/(Distances[i, j] + distance_factor)
        end
    end
    return W
end