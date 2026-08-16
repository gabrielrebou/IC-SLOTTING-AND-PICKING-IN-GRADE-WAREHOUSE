
using LinearAlgebra

function build_distances(locations::Vector{Location})

    n = length(locations)
    W = Matrix{Float64}(undef, n, n)

    for i in 1:n
        for j in 1:n
            W[i, j] = custom_manhattan(locations[i], locations[j])
        end
    end

    return W
end