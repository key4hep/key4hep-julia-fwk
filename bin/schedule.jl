#!/usr/bin/env julia

import Preferences
if Preferences.load_preference("FrameworkDemo", "distributed-package") == "DistributedNext"
    using DistributedNext
else
    using Distributed
end
using Dagger
using ArgParse
using FrameworkDemo
using Logging
using DataFrames
using CSV
using Printf

const trace_formats = ["graph", "chrome", "gantt", "raw"]

function parse_args(raw_args)
    s = ArgParseSettings()

    @add_arg_table! s begin
        "data-flow"
        help = "Input data-flow graph as a GraphML file"
        arg_type = String
        required = true

        "--warmup-count"
        help = "Number of events to be processed as a warm up before the actual run"
        arg_type = Int
        default = 0

        "--event-count"
        help = "Number of events to be processed"
        arg_type = Int
        default = 1

        "--max-concurrent"
        help = "Number of slots for graphs to be scheduled concurrently"
        arg_type = Int
        default = 1

        "--trace-graph"
        help = "Output the execution trace as a graph. Either dot or graphics file format like png, svg, pdf"
        arg_type = String

        "--trace-chrome"
        help = "Output the execution trace as a chrome trace. Must be a json file"
        arg_type = String

        "--trace-gantt"
        help = "Output the execution trace as a Gantt chart. Must be a graphics file format like png, svg, pdf"
        arg_type = String

        "--trace-raw"
        help = "Output the execution trace as text. The file will be formatted as json if json extension is given"
        arg_type = String

        "--dump-plan"
        help = "Output the execution plan as a graph. Either dot or graphics file format like png, svg, pdf"
        arg_type = String

        "--fast"
        help = "Execute algorithms immediately skipping algorithm runtime information and crunching. Conflicts with --crunch-coefficients"
        action = :store_true

        "--dry-run"
        help = "Assemble workflow but don't schedule it, don't create any output files"
        action = :store_true

        "--disable-logging"
        help = "Disable logging for a given level and below (debug, info, warn, error)"
        arg_type = String

        "--crunch-coefficients"
        help = "Set the CPU-crunching coefficients manually. Must be a 2-element vector. Each process will use the same values. Conflicts with --fast"
        arg_type = Float64
        nargs = 2

        "--save-timing"
        help = "Output the timing information. Must be a csv file"
        arg_type = String

        "--trials"
        help = "Run the pipeline N times"
        arg_type = Int
        default = 1

        "--duration-scale"
        help = "Scale factor to apply to the duration of each algorithm"
        arg_type = Float64
        default = 1.0

        "--disable-mempool-gc"
        help = "Disable MemPool automatic GC. Use to reduce the GC time on systems with low memory (laptop)"
        action = :store_true

        "--profile"
        help = "Output execution profile. Must be a html file"
        arg_type = String

        "--profile-walltime"
        help = "Use wall-time profiler. Requires julia 1.12 or later"
        action = :store_true

        "--profile-view"
        help = "Open the execution profile in a browser or vscode tab if run in vscode REPL"
        action = :store_true
    end

    parsed = ArgParse.parse_args(raw_args, s)
    if !isempty(parsed["crunch-coefficients"]) && parsed["fast"]
        error("--fast and --crunch-coefficients are mutually exclusive")
    end
    return parsed
end

function disable_logging(level_str::AbstractString)
    level_map = Dict("debug" => Logging.Debug,
                     "info" => Logging.Info,
                     "warn" => Logging.Warn,
                     "error" => Logging.Error)
    level = get(level_map, lowercase(level_str), nothing)
    isnothing(level) &&
        error("Invalid log level: $level_str. Choose from debug, info, warn, error.")
    Logging.disable_logging(level) # global setting, named logging levels differ by 1000
end

function measure_pipeline(data_flow,
                          event_count,
                          max_concurrent,
                          crunch_coefficients)
    @info "Pipeline: processing $event_count events"
    stats = @timed FrameworkDemo.run_pipeline(data_flow;
                                              event_count = event_count,
                                              max_concurrent = max_concurrent,
                                              crunch_coefficients = crunch_coefficients)
    msg = @sprintf("Pipeline (throughput %.2f events/s)", event_count/stats.time)
    print_timing(msg, stats)
    return stats
end

function print_timing(message, stats)
    Base.time_print(stdout, stats.time * 1e9, stats.gcstats.allocd,
                    stats.gcstats.total_time,
                    Base.gc_alloc_count(stats.gcstats), stats.lock_conflicts,
                    stats.compile_time * 1e9,
                    stats.recompile_time * 1e9, true; msg = message)
end

function timings_to_df(stats, event_count, max_concurrent, coefs_shard)
    df = DataFrame(stats)
    transform!(df, :gcstats => ByRow(x -> x.allocd) => :gc_allocd)
    transform!(df, :gcstats => ByRow(x -> x.total_time) => :gc_total_time)
    transform!(df, :gcstats => ByRow(x -> Base.gc_alloc_count(x)) => :gc_alloc_count)
    transform!(df, :time => ByRow(x -> event_count / x) => :throughput)
    select!(df, Not([:value, :gcstats]))
    df.threads .= Threads.nthreads()
    df.event_count .= event_count
    df.max_concurrent .= max_concurrent
    df.coefs .= [coefs_shard for _ in 1:nrow(df)]
    return df
end


function (@main)(raw_args)
    args = parse_args(raw_args)

    if !isnothing(args["disable-logging"])
        disable_logging(args["disable-logging"])
    end

    tracing_required = any(x -> !isnothing(args["trace-$x"]), trace_formats)

    if tracing_required
        FrameworkDemo.enable_tracing!()
        @info "Enabled tracing"
    end

    graph = FrameworkDemo.parse_graphml(args["data-flow"],
                                        duration_scale = args["duration-scale"])
    data_flow = FrameworkDemo.mockup_dataflow(graph)
    warmup_count = args["warmup-count"]
    event_count = args["event-count"]
    max_concurrent = args["max-concurrent"]
    fast = args["fast"]

    if !isnothing(args["dump-plan"])
        FrameworkDemo.save_execution_plan(data_flow, args["dump-plan"])
    end

    if args["dry-run"]
        @info "Dry run: not executing workflow, not writing traces"
        return
    end

    if !isempty(args["crunch-coefficients"])
        crunch_coefficients = args["crunch-coefficients"]
        @info "Using provided CPU-crunching coefficients: $coefs"
    else
        crunch_coefficients = FrameworkDemo.calibrate_crunch(; fast = fast)
    end

    if warmup_count > 0
        @info "Warm up: processing $warmup_count events"
        @time "Warm up" FrameworkDemo.run_pipeline(data_flow;
                                                   event_count = warmup_count,
                                                   max_concurrent = max_concurrent,
                                                   crunch_coefficients = crunch_coefficients)
        if tracing_required
            trace = FrameworkDemo.fetch_trace!()
            for format in trace_formats
                path = args["trace-$format"]
                if !isnothing(path)
                    base, ext = splitext(path)
                    warmup_path = base * "_warmup" * ext
                    FrameworkDemo.save_trace(trace, warmup_path, Symbol(format))
                end
            end
        end
    end

    # Schedule the pipelines
    pipeline_stats = [measure_pipeline(data_flow, event_count,
                                       max_concurrent, crunch_coefficients)
                      for _ in 1:args["trials"]]

    if tracing_required
        trace = FrameworkDemo.fetch_trace!()
        for format in trace_formats
            path = args["trace-$format"]
            if !isnothing(path)
                FrameworkDemo.save_trace(trace, path, Symbol(format))
            end
        end
    end

    df = timings_to_df(pipeline_stats, event_count, max_concurrent, crunch_coefficients)

    if args["trials"] > 1
        println(select(df, Not([:threads, :event_count, :max_concurrent, :coefs])))
    end

    if !isnothing(args["save-timing"])
        path = args["save-timing"]
        CSV.write(path, df)
        @info "Written timing information to $path"
    end

    if length(workers()) > 1
        rmprocs!(Dagger.Sch.eager_context(), workers())
        workers() |> rmprocs |> wait
    end
end
