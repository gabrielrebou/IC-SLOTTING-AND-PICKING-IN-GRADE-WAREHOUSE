"""
compare_methods.jl

Funções para comparar métodos (ABC / MsgPassing / AllocOnly, com ou sem CW)
ao longo de muitos ids de instância, sem depender de "1 gráfico de barras por id".

Estratégia:
  1) `load_results`      -> lê o csv e deriva colunas úteis (method, total_time, total_bytes)
  2) `plot_metric_dist`  -> boxplot/violin da métrica por método (todos os ids juntos)
  3) `compute_wins` / `plot_wins` -> quantas vezes cada método "venceu" em cada id
  4) `compute_gain` / `plot_gain` -> ganho % (antes x depois do CW) por método
  5) `plot_heatmap`      -> id x método, valor normalizado por linha (inspeção fina)

Todas as funções `plot_*` recebem um parâmetro `outdir`. Se `outdir` for
passado, o gráfico é salvo como .png nessa pasta (criada automaticamente
se não existir) em vez de ser exibido. Se `outdir === nothing` (padrão),
o gráfico só é retornado (comportamento antigo, exibe normalmente).

Uso típico (salvando tudo em disco):

    using CSV, DataFrames, StatsPlots
    include("compare_methods.jl")

    df = load_results("resultados.csv")

    plot_metric_dist(df, :sum_pickers; cw=true, outdir="figs")
    plot_wins(df, :distance; cw=true, minimize=true, outdir="figs")
    plot_gain(df, :total_time; outdir="figs")
    plot_heatmap(df, :sum_pickers; cw=true, outdir="figs")

    # ou, pra gerar tudo de uma vez pra várias métricas:
    generate_all_reports(df, "figs")
"""

using CSV
using DataFrames
using StatsPlots
using Statistics
# ---------------------------------------------------------------------------
# 1) Carregar e preparar os dados
# ---------------------------------------------------------------------------

"""
    load_results(path::AbstractString) -> DataFrame

Lê o csv e cria:
  - `method`      :: String  ("ABC", "MsgPassing" ou "AllocOnly")
  - `total_time`  :: Float64 (allocation_time + route_time + cw_time)
  - `total_bytes` :: Float64 (allocation_bytes + route_bytes + cw_bytes)

Ajuste a lógica do `method` se a combinação de booleans que define cada
método for diferente da que você descreveu.
"""
function load_results(path::AbstractString)
    df = CSV.read(path, DataFrame)

    df.method = map(eachrow(df)) do r
        if r.do_abc
            "ABC"
        elseif r.do_message_passing
            "MsgPassing"
        else
            "AllocOnly"
        end
    end

    df.total_time  = df.allocation_time  .+ df.route_time  .+ df.cw_time
    df.total_bytes = df.allocation_bytes .+ df.route_bytes .+ df.cw_bytes

    return df
end

# ---------------------------------------------------------------------------
# Helper: salvar em disco em vez de exibir
# ---------------------------------------------------------------------------

"""
    _save_or_show(plt, outdir, filename)

Se `outdir !== nothing`, cria a pasta (se preciso) e salva `plt` como
"\$outdir/\$filename.png". Caso contrário, apenas retorna `plt` (exibe
normalmente no REPL/Jupyter/Pluto).
"""
function _save_or_show(plt, outdir::Union{Nothing,AbstractString}, filename::AbstractString)
    if outdir === nothing
        return plt
    end
    mkpath(outdir)
    savefig(plt, joinpath(outdir, filename * ".png"))
    return plt
end

# ---------------------------------------------------------------------------
# 2) Distribuição de uma métrica por método (substitui "1 barra por id")
# ---------------------------------------------------------------------------

"""
    plot_metric_dist(df, metric; cw=true, kind=:box, title="", outdir=nothing)

Boxplot (ou violin, com `kind=:violin`) da `metric` por `method`,
usando todos os ids de uma vez. `cw` filtra as linhas com/sem coordenação.
Se `outdir` for passado, salva o png lá em vez de exibir.
"""
function plot_metric_dist(df::DataFrame, metric::Symbol;
                           cw::Bool=true, kind::Symbol=:box, title::AbstractString="",
                           outdir::Union{Nothing,AbstractString}=nothing)
    sub = filter(:do_cw => x -> x == cw, df)
    ttl = isempty(title) ? "$(metric) por método (cw = $cw)" : title

    plotfun = kind == :violin ? violin : boxplot
    plt = @df sub plotfun(:method, cols(metric),
                           legend=false, title=ttl,
                           xlabel="Método", ylabel=string(metric))

    _save_or_show(plt, outdir, "dist_$(metric)_cw$(cw)")
end

# ---------------------------------------------------------------------------
# 3) Quem venceu em cada id (win-count) -> aí sim, bar chart faz sentido
# ---------------------------------------------------------------------------

"""
    compute_wins(df, metric; cw=true, minimize=true) -> Dict{String,Int}

Para cada id, olha os métodos (com o `do_cw` escolhido) e conta quem tem o
melhor valor da métrica (menor se `minimize=true`, maior caso contrário).
"""
function compute_wins(df::DataFrame, metric::Symbol; cw::Bool=true, minimize::Bool=true)
    sub = filter(:do_cw => x -> x == cw, df)
    wins = Dict{String,Int}()

    for g in groupby(sub, :data_id)
        idx = minimize ? argmin(g[!, metric]) : argmax(g[!, metric])
        best_method = g[idx, :method]
        wins[best_method] = get(wins, best_method, 0) + 1
    end

    return wins
end

"""
    plot_wins(df, metric; cw=true, minimize=true, outdir=nothing)

Gráfico de barras com o número de ids em que cada método foi o melhor
na `metric` (poucas barras, uma por método -> legível mesmo com 90 ids).
Se `outdir` for passado, salva o png lá em vez de exibir.
"""
function plot_wins(df::DataFrame, metric::Symbol; cw::Bool=true, minimize::Bool=true,
                    outdir::Union{Nothing,AbstractString}=nothing)
    wins = compute_wins(df, metric; cw=cw, minimize=minimize)
    methods = collect(keys(wins))
    counts  = collect(values(wins))

    sense = minimize ? "menor" : "maior"
    plt = bar(methods, counts, legend=false,
              title="Nº de ids em que o método teve $sense $(metric) (cw = $cw)",
              xlabel="Método", ylabel="Contagem")

    _save_or_show(plt, outdir, "wins_$(metric)_cw$(cw)")
end

# ---------------------------------------------------------------------------
# 4) Ganho percentual trazido pelo CW, por método
# ---------------------------------------------------------------------------

"""
    compute_gain(df, metric) -> DataFrame

Para cada (id, método), compara a métrica com `do_cw=false` (antes)
e `do_cw=true` (depois) e calcula o ganho percentual:

    gain_pct = (antes - depois) / antes * 100

Valor positivo = métrica melhorou (diminuiu) com o CW.
Assume que existe exatamente uma linha para cada combinação
(id, method, do_cw); ajuste se isso não for verdade no seu csv.
"""
function compute_gain(df::DataFrame, metric::Symbol)
    gains = DataFrame(data_id=Int[], method=String[], gain_pct=Union{Missing,Float64}[])

    for g in groupby(df, [:data_id, :method])
        before_rows = g[g.do_cw .== false, metric]
        after_rows  = g[g.do_cw .== true,  metric]

        if isempty(before_rows) || isempty(after_rows)
            continue
        end

        before = before_rows[1]
        after  = after_rows[1]
        gain = before == 0 ? missing : (before - after) / before * 100

        push!(gains, (g.data_id[1], g.method[1], gain))
    end

    return gains
end

"""
    plot_gain(df, metric; kind=:box, outdir=nothing)

Boxplot do ganho % (antes x depois do CW) por método, ao longo de todos os ids.
Se `outdir` for passado, salva o png lá em vez de exibir.
"""
function plot_gain(df::DataFrame, metric::Symbol; kind::Symbol=:box,
                    outdir::Union{Nothing,AbstractString}=nothing)
    gains = dropmissing(compute_gain(df, metric), :gain_pct)
    plotfun = kind == :violin ? violin : boxplot

    plt = @df gains plotfun(:method, :gain_pct, legend=false,
                             title="Ganho % em $(metric) após aplicar CW",
                             xlabel="Método", ylabel="Ganho (%)")

    _save_or_show(plt, outdir, "gain_$(metric)")
end

# ---------------------------------------------------------------------------
# 5) Heatmap id x método (inspeção fina, sem estourar 90 gráficos)
# ---------------------------------------------------------------------------

"""
    plot_heatmap(df, metric; cw=true, outdir=nothing)

Heatmap com ids nas linhas e métodos nas colunas, valor normalizado
(0 a 1) dentro de cada linha/id, pra facilitar comparação visual mesmo
com escalas diferentes entre instâncias. Se `outdir` for passado, salva
o png lá em vez de exibir.
"""
function plot_heatmap(df::DataFrame, metric::Symbol; cw::Bool=true,
                       outdir::Union{Nothing,AbstractString}=nothing)
    sub = filter(:do_cw => x -> x == cw, df)
    piv = unstack(sub, :data_id, :method, metric)

    ids = piv.data_id
    method_cols = names(piv)[2:end]
    mat = Matrix(piv[:, 2:end])

    normmat = similar(mat, Float64)
    for i in 1:size(mat, 1)
        row = mat[i, :]
        mn, mx = minimum(row), maximum(row)
        normmat[i, :] = mx == mn ? zeros(length(row)) : (row .- mn) ./ (mx - mn)
    end

    plt = heatmap(method_cols, string.(ids), normmat,
                  xlabel="Método", ylabel="ID",
                  title="$(metric) normalizado por id (cw = $cw)",
                  color=:viridis)

    _save_or_show(plt, outdir, "heatmap_$(metric)_cw$(cw)")
end

# ---------------------------------------------------------------------------
# 6) Resumo tabular (útil pra conferir números antes de plotar)
# ---------------------------------------------------------------------------

"""
    summary_table(df, metric; cw=true) -> DataFrame

Média, mediana e desvio padrão da `metric` por método, ao longo dos ids.
"""
function summary_table(df::DataFrame, metric::Symbol; cw::Bool=true)
    sub = filter(:do_cw => x -> x == cw, df)
    combine(groupby(sub, :method),
            metric => mean   => :mean,
            metric => median => :median,
            metric => std    => :std)
end

# ---------------------------------------------------------------------------
# 7) Gerar e salvar tudo de uma vez
# ---------------------------------------------------------------------------

"""
    generate_all_reports(df, outdir;
                          dist_metrics = [:sum_pickers, :distance, :total_time, :total_bytes],
                          win_metrics  = [(:sum_pickers, true), (:distance, true),
                                          (:total_time, true), (:total_bytes, true)],
                          gain_metrics = [:sum_pickers, :distance, :total_time, :total_bytes],
                          heatmap_metrics = [:sum_pickers, :distance])

Gera e salva em `outdir` (cria a pasta se não existir):
  - distribuição (boxplot) de cada métrica em `dist_metrics`, com cw=true e cw=false
  - win-count de cada métrica em `win_metrics` (tupla (métrica, minimize::Bool))
  - ganho % de cada métrica em `gain_metrics`
  - heatmap de cada métrica em `heatmap_metrics`, com cw=true e cw=false

Também salva um `summary.csv` com `summary_table` de cada métrica (cw=true).

Retorna a lista de arquivos gerados.
"""
function generate_all_reports(df::DataFrame, outdir::AbstractString;
        dist_metrics = [:sum_pickers, :distance, :total_time, :total_bytes],
        win_metrics  = [(:sum_pickers, true), (:distance, true),
                         (:total_time, true), (:total_bytes, true)],
        gain_metrics = [:sum_pickers, :distance, :total_time, :total_bytes],
        heatmap_metrics = [:sum_pickers, :distance])

    mkpath(outdir)

    for metric in dist_metrics
        plot_metric_dist(df, metric; cw=true,  outdir=outdir)
        plot_metric_dist(df, metric; cw=false, outdir=outdir)
    end

    for (metric, minimize) in win_metrics
        plot_wins(df, metric; cw=true, minimize=minimize, outdir=outdir)
    end

    for metric in gain_metrics
        plot_gain(df, metric; outdir=outdir)
    end

    for metric in heatmap_metrics
        plot_heatmap(df, metric; cw=true,  outdir=outdir)
        plot_heatmap(df, metric; cw=false, outdir=outdir)
    end

    # tabela resumo consolidada (cw=true) pra todas as métricas de dist_metrics
    summaries = DataFrame()
    for metric in dist_metrics
        st = summary_table(df, metric; cw=true)
        st.metric = fill(string(metric), nrow(st))
        summaries = vcat(summaries, st; cols=:union)
    end
    CSV.write(joinpath(outdir, "summary.csv"), summaries)

    return readdir(outdir)
end