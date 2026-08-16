
using CSV, DataFrames, StatsPlots
include("compare_functions.jl")

df = load_results(joinpath(@__DIR__, "compare.csv"))

plot_metric_dist(df, :sum_pickers; cw=true, outdir="figs")
plot_wins(df, :distance; cw=true, minimize=true, outdir="figs")
plot_gain(df, :total_time; outdir="figs")
plot_heatmap(df, :sum_pickers; cw=true, outdir="figs")

# ou, pra gerar tudo de uma vez pra várias métricas:
generate_all_reports(df, "figs")