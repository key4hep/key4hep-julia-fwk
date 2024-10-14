#!/usr/bin/env julia
using ArgParse
using CSV
using DataFrames
using Plots
using Printf
using Statistics
using MetaGraphs
import GraphMLReader

function parse_args(args)
    s = ArgParseSettings(description =
                         """
                         Calculate distributions of Gaudi algorithm execution duration time
                         from a timeline extracted with Gaudi TimelineSvc or data-flow graph
                         """)

    @add_arg_table! s begin
        "input"
        help = "Input Gaudi timeline CSV file or data-flow graph GraphML file"
        arg_type = String
        required = true

        "output"
        help = "Output histogram file"
        arg_type = String
        required = false
    end
    return ArgParse.parse_args(args, s)
end

function durations_from_csv(filename)
    df = CSV.read(filename, DataFrame)
    rename!(df, "#start" => :start)
    df.duration = (df.end .- df.start) ./ 1e9
    return df.duration
end

function durations_from_graphml(filename)
    graph = GraphMLReader.loadgraphml(filename, "G")
    algorithm_vertices = MetaGraphs.filter_vertices(graph, :type, "Algorithm")
    return [get_prop(graph, vertex, :runtime_average_s)
            for vertex in algorithm_vertices if has_prop(graph, vertex, :runtime_average_s)]
end

function main(args)
    parsed_args = parse_args(args)

    input_file = parsed_args["input"]
    ext = splitext(input_file)[2]
    durations = []
    if ext == ".csv"
        durations = durations_from_csv(input_file)
    elseif ext == ".graphml"
        durations = durations_from_graphml(input_file)
    end

    n = length(durations)
    min_duration = minimum(durations)
    max_duration = maximum(durations)
    println("Entries: $n")
    println("Algorithm execution duration:")
    @printf "\tmin:\t %.2e s\n" min_duration
    @printf "\tmedian:\t %.2e s\n" median(durations)
    @printf "\tmean:\t %.2e s\n" mean(durations)
    @printf "\tmax:\t %.2e s\n" max_duration
    @printf "\tstd:\t %.2e s\n" std(durations)

    output_file = parsed_args["output"]
    if isnothing(output_file)
        return
    end

    if min_duration <= 0
        @warn "Skipping negative and zero durations"
        positive_durations = filter(x -> x > 0, durations)
        min_duration = minimum(positive_durations)
        max_duration = maximum(positive_durations)
        n = length(positive_durations)
    end
    num_bins = sqrt(n) |> ceil |> Int

    bin_edges = exp10.(range(log10(min_duration), stop = log10(max_duration),
                             length = num_bins + 3))

    histogram(durations; label = "", bin = bin_edges, xscale = :log10,
              xlim = extrema(bin_edges),
              title = "Algorithm execution duration", xlabel = "Duration (s)",
              ylabel = "Counts",
              xguidefonthalign = :right, yguidefontvalign = :top)
    savefig(output_file)
    @info "Histogram saved to $output_file"
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
