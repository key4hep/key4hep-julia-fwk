using Distributed
using Colors
using GraphViz
using Cairo
using Dagger

# This is a workaround to make visualization work until the bugs are fixed in the package.
include("../../../../dagger_exts/GraphVizSimpleExt.jl")
using .ModGraphVizSimpleExt

include("../../../auxiliary/example_tasks.jl")
include("../../../../utilities/auxiliary_functions.jl")
include("../../../../utilities/visualization_functions.jl")

FILENAME_TEMPLATE = "./examples/examples_results/enable_logging/viz_enable_logging_oldAPI"

function workaround()
    logs = Dagger.fetch_logs!() # Fetch all the logs
    events_logs = Dict()
    for (key, value) in logs
        events_logs[key] = value[:full] # Leave only the events logs
    end
    spans = Dagger.TimespanLogging.build_timespans(vcat(values(events_logs)...)).completed # Form the timespans
    convert(Vector{Dagger.TimespanLogging.Timespan}, spans)
end

function configure_MultiEventLog()
    Dagger.enable_logging!(timeline = true, # Some example configuration
        tasknames=true,
        taskdeps=true,
        taskargs=true,
        taskargmoves=true,
    )
    Dagger.Sch.eager_context().log_sink[:full] = Dagger.TimespanLogging.Events.FullMetrics()
end

# Use MultiEventLog sink:
configure_MultiEventLog()
# Or use a Local Event Log sink:
# configure_LocalEventLog()

graph_thunk = oldAPI_graph_setup(1)

println(collect(Dagger.Sch.eager_context(), graph_thunk)) # Wait for the graph execution and fetch the results

# Use MultiEventLog sink:
logs = workaround()
# Or use a Local Event Log sink:
# logs = Dagger.TimespanLogging.get_logs!(Dagger.Sch.eager_context())

log_file_name = timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    ModGraphVizSimpleExt.show_logs(io, graph_thunk, logs, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, logs, :graphviz_simple) after the bug fix in the package
    # Dagger.show_logs(graph_thunk, logs, :graphviz_simple) # Returns the string representation of the graph 
end

dot_to_png(log_file_name, timestamp_string(FILENAME_TEMPLATE) * ".png", 2000, 2000)
