function abc_skus(skus::Vector{SKU};
                  a_limit::Float64 = 0.70,
                  b_limit::Float64 = 0.90)

    n = length(skus)

    order = sortperm(1:n, by = i -> skus[i].frequency, rev = true)

    classes = fill('C', n)

    total_frequency = sum(sku.frequency for sku in skus)

    if total_frequency == 0
        return classes, order
    end

    accumulated = 0

    for i in order
        percentage = accumulated / total_frequency

        if percentage < a_limit
            classes[i] = 'A'
        elseif percentage < b_limit
            classes[i] = 'B'
        else
            classes[i] = 'C'
        end

        accumulated += skus[i].frequency
    end

    return classes, order
end