# src/General_functions/graphs.jl

using Graphs
using Plots

function warehouse_graph(warehouse::Warehouse)
    # Criar o grafo baseado no número de localizações + depósito
    n_nos = length(warehouse.locations) + 1
    g = SimpleGraph(n_nos)

    # Mapear coordenadas (shelf = X, aisle = Y)
    # Ignoramos o 'id' conforme solicitado, usando a ordem do vetor
    x = Float64[]
    y = Float64[]
    labels = String[]

    # Adiciona o depósito primeiro (ex: índice 1)
    push!(x, warehouse.depot.shelf)
    push!(y, warehouse.depot.aisle)
    push!(labels, "Depósito")
    
    # Adiciona as localizações
    for (i, loc) in enumerate(warehouse.locations)
        push!(x, loc.shelf)
        push!(y, loc.aisle)
        push!(labels, "$(loc.capacity)")
    end
    # Plotando os nós
    plt = plot(
        xlabel="Shelf", 
        ylabel="Aisle",
        title="Visualização do Armazém (Warehouse)",
        grid=false,
        legend=:best,
    )
    for i in 1:warehouse.locations[end].aisle
        plot!([-warehouse.locations[end].shelf, warehouse.locations[end].shelf], [i, i], 
        label="", 
        color=:black, 
        linewidth=2
        )
    end

    plot!([0, 0], [0,warehouse.locations[end].aisle], 
        label="", 
        color=:black, 
        linewidth=4,
    )
    
    scatter!(x, y, 
        label="Shelfes", 
        markersize=8, 
        markercolor=:gray,
        shape =:square
    )
    # Destacando o depósito com cor diferente
    scatter!([x[1]], [y[1]], label="Depot", markersize=12, markercolor=:black, shape=:square)

    # Adicionando os rótulos de texto ao lado dos pontos
    for i in eachindex(x)
        annotate!(x[i], y[i] - 0.3, text(labels[i], 8, :center))
    end

    results_dir::String = joinpath(@__DIR__, "..", "..", "Results_cache", "graphs")
    mkpath(results_dir)
    savefig(plt, joinpath(results_dir, "warehouse_graph.png"))
    end

function heatmap_main(matriz::Matrix, title::String)

    num_linhas, num_colunas = size(matriz)

    plt = heatmap(matriz,
        title=title,
        color=:viridis,
        aspect_ratio=:equal,
        yflip=true,
        
        # --- Correção dos Eixos ---
        xlims = (0.5, num_colunas + 0.5), # Define o limite exato do início ao fim das colunas
        xticks = [1;5:5:num_colunas],           # Força os rótulos a irem exatamente de 1 até o número de colunas
        ylims = (0.5, num_linhas + 0.5),  # Opcional: ajusta também o limite vertical
        yticks = [1;5:5:num_linhas]             # Opcional: força marcadores de 1 até o número de linhas
    )

    results_dir::String = joinpath(@__DIR__, "..", "..", "Results_cache", "graphs")
    mkpath(results_dir)

    filename = replace(title, " " => "_")
    filename = replace(filename, r"[^\w\-]" => "")

    savefig(plt, joinpath(results_dir, "heatmap_$(filename).png"))

end

function plot_allocation(x, warehouse)
    
    locations = warehouse.locations
    
    p = plot(
        aspect_ratio = :equal,
        legend = false,
        axis = false,
        grid = false,
        size = (900,700)
    )

    for i in 1:warehouse.locations[end].aisle
        plot!([-warehouse.locations[end].shelf, warehouse.locations[end].shelf], [i, i], 
        label="", 
        color=:black, 
        linewidth=2
        )
    end
    
    palette = cgrad(:tab20, max(size(x,2), 2))
    
    plot!([0, 0], [0,warehouse.locations[end].aisle], 
    label="", 
    color=:black, 
    linewidth=4,
    )
    
    # Todas as posições
    for loc in locations
        scatter!(
            [loc.shelf],
            [loc.aisle],
            marker = :rect,
            markersize = 18,
            markercolor = :white,
            markerstrokecolor = :black
            )
    end

    # Posições ocupadas
    for loc in locations
        
        q = x[loc.id, :]
        
        maximum(q) == 0 && continue
        
        sku = argmax(q)
        
        scatter!(
            [loc.shelf],
            [loc.aisle],
            marker = :rect,
            markersize = 18,
            markercolor = palette[(sku-1)/(size(x,2)-1)],
            markerstrokecolor = :black
            )
            
            annotate!(
                loc.shelf,
                loc.aisle,
                text(string(sku), 7, :black)
                )
    end
    
    scatter!(
        [warehouse.depot.shelf],
        [warehouse.depot.aisle],
        marker = :rect,
        markersize = 18,
        markercolor = :black,
        markerstrokecolor = :black
        )
        annotate!(
            warehouse.depot.shelf,
            warehouse.depot.aisle,
            text("Depot", 7, :white)
            )

    results_dir::String = joinpath(@__DIR__, "..", "..", "Results_cache", "graphs")
    mkpath(results_dir)
    savefig(p, joinpath(results_dir, "allocation.png"))

end