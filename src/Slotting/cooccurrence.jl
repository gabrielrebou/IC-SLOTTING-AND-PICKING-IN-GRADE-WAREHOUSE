# src/Slotting/cooccurrence.jl

function cooccurrence_matrix(orders::Vector{Order}, n_skus::Int)

    matrix = zeros(Int, n_skus, n_skus)
    frequency = zeros(Int, n_skus)

    for order in orders

        for sku in order.skus
            frequency[sku] += 1
        end

        skus = unique(order.skus)

        for i in 1:length(skus)-1
            for j in i+1:length(skus)

                a = skus[i]
                b = skus[j]

                matrix[a, b] += 1
                matrix[b, a] += 1

            end
        end
    end
    
    return CooccurrenceMatrix(matrix, frequency)
end

function norm_cooccurrence(cooccurrence_matrix)
    mat = zeros(Float64, size(cooccurrence_matrix))
    for i in axes(mat, 1)
        linha_soma = sum(cooccurrence_matrix[i, :])
        if linha_soma > 0
            for j in axes(cooccurrence_matrix, 2)
                mat[i, j] = cooccurrence_matrix[i, j] / linha_soma
            end
        end
    end
    return mat
end