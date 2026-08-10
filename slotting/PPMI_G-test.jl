

function g_test(
    cooc::Real,
    freq_i::Real,
    freq_j::Real,
    total::Real
)

    a = cooc
    b = freq_i - cooc
    c = freq_j - cooc
    d = total - freq_i - freq_j + cooc

    observed = [
        a b
        c d
    ]

    row_totals = sum(observed, dims=2)
    col_totals = sum(observed, dims=1)

    expected = row_totals * col_totals / total

    G = 0.0

    for i in 1:2
        for j in 1:2
            O = observed[i,j]
            E = expected[i,j]

            if O > 0
                G += 2 * O * log(O / E)
            end
        end
    end

    return G
end