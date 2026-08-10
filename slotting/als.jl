
# futuramente
#precomputação de Q^TQ para evitar recalcular a cada iteração
#update vetorizado | BLAS ou matrizes densas para melhorar performance

using LinearAlgebra
using SparseArrays
using Random

function als(
    S::SparseMatrixCSC;
    k::Int,
    λ::Float64,
    maxiter::Int,
    tol::Float64=1e-4,
    seed::Int
)

    Random.seed!(seed)

    m, n = size(S)

    U = 0.1 .* randn(m, k)
    V = 0.1 .* randn(n, k)

    Iλ = λ * I(k)

    rows = [Int[] for _ in 1:m]
    cols = [Int[] for _ in 1:n]

    for j in 1:n
        for p in nzrange(S, j)
            i = rowvals(S)[p]
            push!(rows[i], j)
            push!(cols[j], i)
        end
    end

    last_error = Inf

    for iter in 1:maxiter

        # Atualiza U
        for i in 1:m

            js = rows[i]

            isempty(js) && continue

            A = zeros(k, k)
            b = zeros(k)

            for j in js
                v = @view V[j, :]
                s = S[i, j]
                A .+= v * v'
                b .+= s .* v
            end

            U[i, :] = (A + Iλ) \ b
        end

        # Atualiza V
        for j in 1:n

            is = cols[j]

            isempty(is) && continue

            A = zeros(k, k)
            b = zeros(k)

            for i in is
                u = @view U[i, :]
                s = S[i, j]
                A .+= u * u'
                b .+= s .* u
            end

            V[j, :] = (A + Iλ) \ b
        end

        err = 0.0

        for j in 1:n
            for p in nzrange(S, j)
                i = rowvals(S)[p]
                r = S[i,j] - dot(U[i,:], V[j,:])
                err += r^2
            end
        end

        #println("Iteração $iter   erro = $err")

        if abs(last_error - err) < tol
            break
        end

        last_error = err
    end

    return U, V
end