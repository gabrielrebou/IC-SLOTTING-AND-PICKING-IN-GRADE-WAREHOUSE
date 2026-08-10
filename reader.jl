function read_instance(filename)

    lines = readlines(filename)

    n_skus = parse(Int, strip(lines[3]))
    n_orders = parse(Int, strip(lines[4]))

    orders = Order[]

    for i in 1:n_orders
        skus = parse.(Int, split(strip(lines[5 + i])))
        push!(orders, Order(i, skus))
    end

    return Instance(
        n_skus,
        orders
    )

end