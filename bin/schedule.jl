#!/usr/bin/env julia

using Distributed
using Dagger
using ArgParse
using FrameworkDemo

function parse_args()
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
        default = 3

        "--dot-trace"
        help = "Output graphviz dot file for execution logs graph"
        arg_type = String
    end

    return ArgParse.parse_args(s)
end

function main()
    args = parse_args()

    event_count = args["event-count"]
    max_concurrent = args["max-concurrent"]

    if !isnothing(args["dot-trace"])
        @info "Enabled logging"
        FrameworkDemo.configure_LocalEventLog()
    end

    graph = FrameworkDemo.parse_graphml(args["data-flow"])
    FrameworkDemo.run_events(graph, event_count, max_concurrent)

    if !isnothing(args["dot-trace"])
        logs = Dagger.fetch_logs!()
        open(args["dot-trace"], "w") do io
            FrameworkDemo.ModGraphVizSimple.show_logs(io, logs, :graphviz_simple)
            @info "Written logs dot graph to $(args["dot-trace"])"
        end
    end
end


if abspath(PROGRAM_FILE) == @__FILE__
    main()
    rmprocs!(Dagger.Sch.eager_context(), workers())
    rmprocs(workers())
end
