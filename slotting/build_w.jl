
using LinearAlgebra

function build_W(locations::Vector{Location}, a::Float64)

    n = length(locations)
    W = Matrix{Float64}(undef, n, n)

    for i in 1:n
        s = 0.0

        for j in 1:n
            d = custom_manhattan(locations[i], locations[j])
            W[i, j] = a / (d + a)
            s += W[i, j]
        end

        W[i, :] ./= s
    end

    return W
end