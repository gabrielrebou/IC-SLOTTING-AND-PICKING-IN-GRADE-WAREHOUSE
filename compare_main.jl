# src/compare_functions.jl
#
# Analise comparativa dos resultados salvos em compare.csv:
#   - Tabelas numericas impressas no terminal (brutas, agregadas e ranking)
#   - Histogramas de distancia e pickers, separados por merge_strategy:
#       CLARKE_WRIGHT (completo) / CLARKE_WRIGHT_HEURISTIC / NO_HEURISTIC
#   - Boxplots (facetados por routing_heuristic) de distancia e pickers
#   - Performance profile (Dolan-More), um por merge_strategy
#
# Uso:
#   1) Isolado, no terminal (a partir da pasta src/):
#        julia --project=.. compare_functions.jl
#      (o --project=.. ativa o ambiente do projeto, na pasta pai de src/,
#       onde deve estar o Project.toml com CSV/DataFrames/Plots/StatsPlots)
#
#   2) Incluido a partir de outro arquivo (ex.: main.jl):
#        include("compare_functions.jl")
#        gerar_comparacoes()
#      Nesse caso a funcao NAO roda automaticamente; e preciso chama-la.

import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using DataFrames
using Plots
using StatsPlots
using Statistics
using Printf

gr()  # backend leve, nao interativo por padrao ao rodar via script

# ----------------------------------------------------------------------
# Caminhos
# ----------------------------------------------------------------------

const COMPARE_CSV_PATH = joinpath(@__DIR__, "..", "compare.csv")
const GRAFICOS_DIR     = joinpath(@__DIR__, "..", "Graficos_comparacao")

function ensure_output_dirs()
    hist_dir = joinpath(GRAFICOS_DIR, "Histogramas")
    box_dir  = joinpath(GRAFICOS_DIR, "Boxplots")
    perf_dir = joinpath(GRAFICOS_DIR, "Performance_profile")

    mkpath(hist_dir)
    mkpath(box_dir)
    mkpath(perf_dir)

    return (histogramas = hist_dir, boxplots = box_dir, performance = perf_dir)
end

# ----------------------------------------------------------------------
# Carregamento e preparacao dos dados
# ----------------------------------------------------------------------

function load_compare_data(path::AbstractString = COMPARE_CSV_PATH)
    if !isfile(path)
        error("Arquivo compare.csv nao encontrado em: $path")
    end

    df = CSV.read(path, DataFrame)

    df.config_label = string.(
        df.allocation_method, " | ",
        df.routing_heuristic, " | ",
        df.merge_strategy
    )

    return df
end

# Abrevia nomes longos (ex.: MESSAGE_PASSING -> MESS_PASS) mantendo
# palavras curtas intactas (ex.: GREEDY, ALS, ABC ficam como estao).
function abbreviate(s::AbstractString; maxlen::Int = 4)
    parts = split(s, "_")
    abbr_parts = [length(p) > maxlen ? p[1:maxlen] : p for p in parts]
    return join(abbr_parts, "_")
end

# Adiciona colunas de razao em relacao ao melhor resultado DA MESMA
# INSTANCIA (data_id). Isso torna histogramas/boxplots comparaveis
# mesmo quando ha muitos casos de teste com escalas bem diferentes.
# 1.0 = melhor resultado daquela instancia; 2.0 = duas vezes pior, etc.
function add_ratio_columns!(df::DataFrame)
    transform!(
        groupby(df, :data_id),
        :distance    => (x -> x ./ minimum(x)) => :distance_ratio,
        :sum_pickers => (x -> x ./ minimum(x)) => :pickers_ratio,
    )
    return df
end

# Divide o DataFrame nos 3 grupos de merge_strategy. Valores nao
# reconhecidos caem em um grupo generico (fallback), para nao quebrar
# caso surjam novas estrategias de merge no futuro.
const MERGE_GROUP_INFO = [
    ("CLARKE_WRIGHT",           "clarke",            "Com merge Clarke-Wright (completo)"),
    ("CLARKE_WRIGHT_HEURISTIC", "clarke_heuristica", "Com merge Clarke-Wright (heurística)"),
    ("NO_HEURISTIC",            "sem_clarke",         "Sem merge (NO_HEURISTIC)"),
]

function split_merge_groups(df::DataFrame)
    grupos = NamedTuple[]
    valores_conhecidos = first.(MERGE_GROUP_INFO)

    for (valor, slug, label) in MERGE_GROUP_INFO
        sub = filter(row -> row.merge_strategy == valor, df)
        push!(grupos, (slug = slug, label = label, df = sub))
    end

    outros = filter(row -> !(row.merge_strategy in valores_conhecidos), df)
    if !isempty(outros)
        for valor in unique(outros.merge_strategy)
            sub = filter(row -> row.merge_strategy == valor, outros)
            push!(grupos, (slug = "outro_$(valor)", label = "Merge: $(valor)", df = sub))
        end
    end

    return grupos
end

_safe_filename(s::AbstractString) = replace(s, r"[^A-Za-z0-9_\-]" => "_")

# ----------------------------------------------------------------------
# Impressao de tabelas no terminal
# ----------------------------------------------------------------------

fmt_value(x::AbstractFloat) = isnan(x) ? "—" : @sprintf("%.3f", x)
fmt_value(x::Integer) = string(x)
fmt_value(x) = string(x)

# Imprime um DataFrame formatado como tabela de texto alinhada.
function print_table(df::DataFrame)
    if isempty(df)
        println("(sem dados)")
        return
    end

    cols = names(df)
    str_cols = Dict(c => [fmt_value(df[i, c]) for i in 1:nrow(df)] for c in cols)
    widths = Dict(c => max(length(c), maximum(length.(str_cols[c]); init = 0)) for c in cols)

    header = join([rpad(c, widths[c]) for c in cols], " | ")
    println(header)
    println("-"^length(header))

    for i in 1:nrow(df)
        println(join([rpad(str_cols[c][i], widths[c]) for c in cols], " | "))
    end
end

# Tabela agregada (media, mediana, desvio, min, max, n) por grupo.
function print_summary_table(
    df::DataFrame,
    group_cols::Vector{Symbol},
    value_col::Symbol,
    title_str::AbstractString,
)
    println("\n-- $title_str --")

    if isempty(df)
        println("(sem dados)")
        return
    end

    resumo = combine(
        groupby(df, group_cols),
        value_col => mean => :media,
        value_col => median => :mediana,
        value_col => std => :desvio,
        value_col => minimum => :minimo,
        value_col => maximum => :maximo,
        nrow => :n,
    )
    sort!(resumo, :media)

    print_table(resumo)
end

# Ranking geral: media da razao (em relacao ao melhor por instancia)
# de cada configuracao completa, do melhor para o pior.
function print_ranking(df::DataFrame, ratio_col::Symbol, title_str::AbstractString)
    println("\n-- Ranking — $title_str (média da razão em relação ao melhor por instância) --")

    resumo = combine(
        groupby(df, :config_label),
        ratio_col => mean => :media_razao,
        nrow => :n,
    )
    sort!(resumo, :media_razao)

    print_table(resumo)
end

function imprimir_tabelas(df::DataFrame)
    println("="^78)
    println("RESULTADOS BRUTOS (compare.csv)")
    println("="^78)

    cols_brutos = [
        :allocation_method, :routing_heuristic, :merge_strategy,
        :distance, :sum_pickers,
        :allocation_time, :route_time, :merge_time,
    ]

    for data_id in sort(unique(df.data_id))
        sub = filter(row -> row.data_id == data_id, df)
        nome = first(sub.data_name)
        println("\n--- Caso de teste id=$data_id ($nome) — ordenado por distância ---")
        sub_ordenado = sort(sub, :distance)
        print_table(select(sub_ordenado, cols_brutos))
    end

    println("\n" * "="^78)
    println("ESTATÍSTICAS POR MÉTODO DE ALOCAÇÃO (dentro de cada grupo de merge)")
    println("="^78)
    println("""
    Cada grupo abaixo mostra duas versões, sempre quebradas por
    allocation_method + routing_heuristic (junto elas ficam escondidas
    numa média só, o que mascara diferenças de até ~30% entre ASTAR e
    GREEDY para o mesmo método/merge):

      (bruto)  -> media/mediana/etc. da distância e dos pickers em
                  valor absoluto, agregando todas as instâncias
                  (data_id) sem nenhum ajuste. Cuidado: instâncias
                  maiores dominam a média aqui.

      (razão)  -> mesma coisa, mas cada valor foi antes dividido pelo
                  melhor resultado DA MESMA INSTÂNCIA (1.0 = melhor
                  daquela instância). Compara métodos de forma justa
                  mesmo com instâncias de tamanhos diferentes; é a
                  versão recomendada para dizer "método X é melhor
                  que Y".
    """)

    for grupo in split_merge_groups(df)
        println("\n### $(grupo.label) ###")

        println("\n[valores brutos, não normalizados]")
        print_summary_table(
            grupo.df, [:allocation_method, :routing_heuristic], :distance,
            "Distância por método e heurística (bruto)",
        )
        print_summary_table(
            grupo.df, [:allocation_method, :routing_heuristic], :sum_pickers,
            "Pickers por método e heurística (bruto)",
        )

        println("\n[valores normalizados — razão em relação ao melhor da instância]")
        print_summary_table(
            grupo.df, [:allocation_method, :routing_heuristic], :distance_ratio,
            "Distância por método e heurística (razão)",
        )
        print_summary_table(
            grupo.df, [:allocation_method, :routing_heuristic], :pickers_ratio,
            "Pickers por método e heurística (razão)",
        )
    end

    println("\n" * "="^78)
    println("RANKING GERAL DE CONFIGURAÇÕES COMPLETAS")
    println("="^78)
    print_ranking(df, :distance_ratio, "Distância")
    print_ranking(df, :pickers_ratio, "Quantidade de Pickers")
end

# ----------------------------------------------------------------------
# Histogramas
# ----------------------------------------------------------------------

function plot_grouped_histogram(
    df::DataFrame,
    value_col::Symbol,
    group_col::Symbol,
    title_str::AbstractString,
    filename::AbstractString,
    output_dir::AbstractString;
    xlabel_str::AbstractString = string(value_col),
    bins::Int = 12,
)
    if isempty(df)
        @warn "DataFrame vazio para \"$title_str\"; gráfico não gerado."
        return nothing
    end

    grupos = sort(unique(df[!, group_col]))

    p = plot(
        title = title_str,
        xlabel = xlabel_str,
        ylabel = "Frequência",
        legend = :outertopright,
        legendfontsize = 7,
        titlefontsize = 10,
        size = (800, 500),
    )

    for g in grupos
        vals = df[df[!, group_col] .== g, value_col]
        isempty(vals) && continue
        histogram!(p, vals; label = abbreviate(string(g)), alpha = 0.55, bins = bins)
    end

    savefig(p, joinpath(output_dir, filename))
    return p
end

function gerar_histogramas(df::DataFrame, hist_dir::AbstractString)
    for grupo in split_merge_groups(df)
        # --- versão bruta (não normalizada) ---
        plot_grouped_histogram(
            grupo.df, :distance, :allocation_method,
            "Distância (bruto) — $(grupo.label)",
            "hist_distancia_$(_safe_filename(grupo.slug))_bruto.png",
            hist_dir;
            xlabel_str = "Distância",
        )

        plot_grouped_histogram(
            grupo.df, :sum_pickers, :allocation_method,
            "Pickers (bruto) — $(grupo.label)",
            "hist_pickers_$(_safe_filename(grupo.slug))_bruto.png",
            hist_dir;
            xlabel_str = "Quantidade de Pickers",
        )

        # --- versão normalizada (razão vs. melhor da instância) ---
        plot_grouped_histogram(
            grupo.df, :distance_ratio, :allocation_method,
            "Distância (razão vs. melhor) — $(grupo.label)",
            "hist_distancia_$(_safe_filename(grupo.slug))_razao.png",
            hist_dir;
            xlabel_str = "Distância / melhor distância da instância",
        )

        plot_grouped_histogram(
            grupo.df, :pickers_ratio, :allocation_method,
            "Pickers (razão vs. melhor) — $(grupo.label)",
            "hist_pickers_$(_safe_filename(grupo.slug))_razao.png",
            hist_dir;
            xlabel_str = "Pickers / melhor quantidade da instância",
        )
    end
end

# ----------------------------------------------------------------------
# Boxplots — facetados por routing_heuristic para nao acumular
# combinacoes demais num unico eixo X
# ----------------------------------------------------------------------

function plot_boxplot_faceted(
    df::DataFrame,
    value_col::Symbol,
    x_col::Symbol,
    facet_col::Symbol,
    title_str::AbstractString,
    filename::AbstractString,
    output_dir::AbstractString;
    ylabel_str::AbstractString = string(value_col),
)
    if isempty(df)
        @warn "DataFrame vazio para \"$title_str\"; boxplot não gerado."
        return nothing
    end

    facetas = sort(unique(df[!, facet_col]))
    subplots = Plots.Plot[]

    for f in facetas
        sub = df[df[!, facet_col] .== f, :]
        labels = abbreviate.(string.(sub[!, x_col]))
        valores = sub[!, value_col]

        p = boxplot(
            labels, valores;
            title = abbreviate(string(f)),
            ylabel = ylabel_str,
            legend = false,
            xrotation = 20,
            titlefontsize = 9,
            guidefontsize = 8,
            tickfontsize = 7,
        )
        push!(subplots, p)
    end

    layout_final = plot(
        subplots...;
        layout = (1, length(subplots)),
        plot_title = title_str,
        plot_titlefontsize = 11,
        size = (420 * length(subplots), 480),
    )

    savefig(layout_final, joinpath(output_dir, filename))
    return layout_final
end

function gerar_boxplots(df::DataFrame, box_dir::AbstractString)
    for grupo in split_merge_groups(df)
        # --- versão bruta (não normalizada) ---
        plot_boxplot_faceted(
            grupo.df, :distance, :allocation_method, :routing_heuristic,
            "Distância (bruto) — $(grupo.label)",
            "boxplot_distancia_$(_safe_filename(grupo.slug))_bruto.png",
            box_dir;
            ylabel_str = "Distância",
        )

        plot_boxplot_faceted(
            grupo.df, :sum_pickers, :allocation_method, :routing_heuristic,
            "Pickers (bruto) — $(grupo.label)",
            "boxplot_pickers_$(_safe_filename(grupo.slug))_bruto.png",
            box_dir;
            ylabel_str = "Quantidade de Pickers",
        )

        # --- versão normalizada (razão vs. melhor da instância) ---
        plot_boxplot_faceted(
            grupo.df, :distance_ratio, :allocation_method, :routing_heuristic,
            "Distância (razão vs. melhor) — $(grupo.label)",
            "boxplot_distancia_$(_safe_filename(grupo.slug))_razao.png",
            box_dir;
            ylabel_str = "Distância / melhor da instância",
        )

        plot_boxplot_faceted(
            grupo.df, :pickers_ratio, :allocation_method, :routing_heuristic,
            "Pickers (razão vs. melhor) — $(grupo.label)",
            "boxplot_pickers_$(_safe_filename(grupo.slug))_razao.png",
            box_dir;
            ylabel_str = "Pickers / melhor da instância",
        )
    end
end

# ----------------------------------------------------------------------
# Performance profile (Dolan-More) — um grafico por grupo de merge,
# usando metodo+heuristica (abreviados) como "solver"
# ----------------------------------------------------------------------

function performance_profile(
    df::DataFrame,
    metric_col::Symbol,
    solver_col::Symbol,
    problem_col::Symbol,
    title_str::AbstractString,
    filename::AbstractString,
    output_dir::AbstractString;
    lower_is_better::Bool = true,
)
    if isempty(df)
        @warn "DataFrame vazio para \"$title_str\"; performance profile não gerado."
        return nothing
    end

    solvers  = sort(unique(df[!, solver_col]))
    problems = unique(df[!, problem_col])

    perf = Dict{Any, Dict{Any, Float64}}()
    for row in eachrow(df)
        p = row[problem_col]
        s = row[solver_col]
        d = get!(perf, p, Dict{Any, Float64}())
        d[s] = float(row[metric_col])
    end

    ratios = Dict{Any, Vector{Float64}}(s => Float64[] for s in solvers)

    for p in problems
        vals = perf[p]
        isempty(vals) && continue

        best = lower_is_better ? minimum(values(vals)) : maximum(values(vals))

        for s in solvers
            if haskey(vals, s)
                v = vals[s]
                r = if lower_is_better
                    best == 0 ? 1.0 : v / best
                else
                    v == 0 ? 1.0 : best / v
                end
                push!(ratios[s], r)
            else
                push!(ratios[s], Inf)
            end
        end
    end

    n_problems = length(problems)
    if n_problems == 0
        @warn "Nenhuma instância encontrada para \"$title_str\"."
        return nothing
    end

    finite_ratios = vcat([filter(isfinite, ratios[s]) for s in solvers]...)
    max_tau = isempty(finite_ratios) ? 2.0 : maximum(finite_ratios) * 1.1
    max_tau = max(max_tau, 1.05)

    taus = range(1.0, max_tau; length = 200)

    p_plot = plot(
        title = title_str,
        xlabel = "τ (fator em relação ao melhor resultado)",
        ylabel = "ρ(τ) — fração de instâncias",
        ylim = (0, 1.05),
        legend = :outertopright,
        legendfontsize = 7,
        titlefontsize = 10,
        size = (800, 500),
    )

    for s in solvers
        rho = [count(r -> r <= t, ratios[s]) / n_problems for t in taus]
        plot!(p_plot, taus, rho; label = string(s), linewidth = 2, seriestype = :steppost)
    end

    savefig(p_plot, joinpath(output_dir, filename))
    return p_plot
end

function gerar_performance_profiles(df::DataFrame, perf_dir::AbstractString)
    df = copy(df)
    df.metodo_heuristica = string.(
        abbreviate.(string.(df.allocation_method)), " | ",
        abbreviate.(string.(df.routing_heuristic))
    )

    for grupo in split_merge_groups(df)
        performance_profile(
            grupo.df, :distance, :metodo_heuristica, :data_id,
            "Performance Profile — Distância — $(grupo.label)",
            "performance_profile_distancia_$(_safe_filename(grupo.slug)).png",
            perf_dir;
            lower_is_better = true,
        )

        performance_profile(
            grupo.df, :sum_pickers, :metodo_heuristica, :data_id,
            "Performance Profile — Pickers — $(grupo.label)",
            "performance_profile_pickers_$(_safe_filename(grupo.slug)).png",
            perf_dir;
            lower_is_better = true,
        )
    end
end

# ----------------------------------------------------------------------
# Entrada principal
# ----------------------------------------------------------------------

function gerar_comparacoes(csv_path::AbstractString = COMPARE_CSV_PATH)
    df = load_compare_data(csv_path)
    add_ratio_columns!(df)
    dirs = ensure_output_dirs()

    imprimir_tabelas(df)

    gerar_histogramas(df, dirs.histogramas)
    gerar_boxplots(df, dirs.boxplots)
    gerar_performance_profiles(df, dirs.performance)

    println("\nGráficos salvos em: ", GRAFICOS_DIR)

    return nothing
end

# ----------------------------------------------------------------------
# Execucao isolada: `julia compare_functions.jl` roda tudo sozinho.
# Se o arquivo for apenas incluido (include("compare_functions.jl")) por
# outro script, este bloco nao executa, e quem incluiu precisa chamar
# gerar_comparacoes() manualmente.
# ----------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    gerar_comparacoes()
end