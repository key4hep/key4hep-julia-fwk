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
        default = 1

        "--dot-trace"
        help = "Output graphviz dot file for execution logs graph"
        arg_type = String

        "--fast"
        help = "Execute algorithms immediately skipping algorithm runtime information and crunching"
        action = :store_true
    end

    return ArgParse.parse_args(s)
end

function main()
    args = parse_args()

    logging_required = !isnothing(args["dot-trace"])

    if logging_required
        FrameworkDemo.configure_LocalEventLog()
        @info "Enabled logging"
    end

    graph = FrameworkDemo.parse_graphml(args["data-flow"])
    data_flow = FrameworkDemo.mockup_dataflow(graph)
    event_count = args["event-count"]
    max_concurrent = args["max-concurrent"]
    fast = args["fast"]

    @time "Pipeline execution" FrameworkDemo.run_pipeline(data_flow;
                                                          event_count = event_count,
                                                          max_concurrent = max_concurrent,
                                                          fast = fast)
    if logging_required
        logs = FrameworkDemo.fetch_logs!()
        if !isnothing(args["dot-trace"])
            FrameworkDemo.save_logs_dot(logs, args["dot-trace"])
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
    if length(workers()) > 1
        rmprocs!(Dagger.Sch.eager_context(), workers())
        rmprocs(workers())
    end
end
