#!/usr/bin/env julia

using Distributed
using Dagger
using ArgParse
using FrameworkDemo

const trace_formats = ["graph", "chrome", "gantt", "raw"]

function parse_args(raw_args)
    s = ArgParseSettings()

    @add_arg_table! s begin
        "data-flow"
        help = "Input data-flow graph as a GraphML file"
        arg_type = String
        required = true

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
        help = "Execute algorithms immediately skipping algorithm runtime information and crunching"
        action = :store_true

        "--dry-run"
        help = "Assemble workflow but don't schedule it, don't create any output files"
        action = :store_true
    end

    return ArgParse.parse_args(raw_args, s)
end

function (@main)(raw_args)
    args = parse_args(raw_args)
    tracing_required = any(x -> !isnothing(args["trace-$x"]), trace_formats)

    if tracing_required
        FrameworkDemo.enable_tracing!()
        @info "Enabled tracing"
    end

    graph = FrameworkDemo.parse_graphml(args["data-flow"])
    data_flow = FrameworkDemo.mockup_dataflow(graph)
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

    crunch_coefficients = FrameworkDemo.calibrate_crunch(; fast = fast)

    @time "Pipeline execution" FrameworkDemo.run_pipeline(data_flow;
                                                          event_count = event_count,
                                                          max_concurrent = max_concurrent,
                                                          crunch_coefficients = crunch_coefficients)

    if tracing_required
        trace = FrameworkDemo.fetch_trace!()
        for format in trace_formats
            path = args["trace-$format"]
            if !isnothing(path)
                FrameworkDemo.save_trace(trace, path, Symbol(format))
            end
        end
    end

    if length(workers()) > 1
        rmprocs!(Dagger.Sch.eager_context(), workers())
        workers() |> rmprocs |> wait
    end
end
