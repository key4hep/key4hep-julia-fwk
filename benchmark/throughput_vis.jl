using Plots
using CSV
using DataFrames
using ArgParse
using Statistics

function parse_args(args)
    s = ArgParseSettings(description = "Visualize the throughput from timing CSV files")
    @add_arg_table! s begin
        "input"
        help = "Input timing CSV file"
        arg_type = String
        nargs = '+'
        required = true

        "--t-min"
        help = "Minimum number of threads"
        arg_type = Int

        "--t-max"
        help = "Maximum number of threads"
        arg_type = Int

        "--no-scale"
        help = "Do not include comparison with linear scaling for throughput"
        action = :store_true

        "--no-gctime"
        help = "Do not include GC time plot"
        action = :store_true

        "--median"
        help = "Use median instead of minimum for throughput"
        action = :store_true
    end

    return ArgParse.parse_args(args, s)
end

function (@main)(args)
    parsed_args = parse_args(args)
    metric = parsed_args["median"] ? median : minimum
    @info "Using metric: $(metric)"

    df = vcat(map(file -> DataFrame(CSV.File(file)), parsed_args["input"])...)
    cols = [:time, :throughput]

    if !parsed_args["no-gctime"]
        df.gctime_percent = 100 * df.gctime ./ df.time
        push!(cols, :gctime_percent)
    end
    gdf = groupby(df, [:threads, :event_count, :max_concurrent])
    df = combine(gdf, cols .=> metric .=> (col -> Symbol(col, "_metric")))
    df = sort(df, [:threads, :event_count, :max_concurrent])
    println("DataFrame: ", df)

    if (!isnothing(parsed_args["t-min"]))
        filter!(row -> row.threads >= parsed_args["t-min"], df)
    end
    if (!isnothing(parsed_args["t-max"]))
        filter!(row -> row.threads <= parsed_args["t-max"], df)
    end

    df.perfect_scaling = (df.threads) .* (df.throughput_metric[1]) / (df.threads[1])

    output_file = "throughput.png"
    series = [df.throughput_metric]
    labels = ["Measured"]
    if !parsed_args["no-scale"]
        push!(series, df.perfect_scaling)
        push!(labels, "Linear scaling")
    end
    plot(df.threads, series, labels = hcat(labels...),
         title = "Throughput scaling", xlabel = "Number of threads",
         ylabel = "Throughput (events/s)", marker = (:circle, 5), linewidth = 3,
         xguidefonthalign = :right, yguidefontvalign = :top)
    savefig(output_file)
    @info "Saved plot to $output_file"

    output_file = "ratio.png"
    plot(df.threads, df.throughput_metric ./ df.perfect_scaling, label = "Ratio",
         title = "Throughput per thread scaling", xlabel = "Number of threads",
         ylabel = "Throughput per thread ratio", marker = (:circle, 5), linewidth = 3,
         xguidefonthalign = :right, yguidefontvalign = :top)
    savefig(output_file)
    @info "Saved plot to $output_file"

    if !parsed_args["no-gctime"]
        output_file = "gc.png"
        plot(df.threads, df.gctime_percent_metric, label = "GC time",
             title = "Garbage collection time", xlabel = "Number of threads",
             ylabel = "GC time (%)", marker = (:circle, 5), linewidth = 3,
             xguidefonthalign = :right, yguidefontvalign = :top)
        savefig(output_file)
        @info "Saved plot to $output_file"
    end
    return
end
