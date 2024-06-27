import Colors
using Dagger
using TimespanLogging
using DaggerWebDash
using FrameworkDemo
include("../../../dummy_tasks.jl")

output_dir = "examples/results"
mkpath(output_dir)
FILENAME_TEMPLATE = "$output_dir/viz_enable_logging_modernAPI"

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

graph_thunk = modernAPI_graph_setup(1)

println(fetch(graph_thunk)) # Wait for the graph execution and fetch the results

# Use MultiEventLog sink:
logs = workaround()
# Or use a Local Event Log sink:
# logs = Dagger.TimespanLogging.get_logs!(Dagger.Sch.eager_context())

log_file_name = FrameworkDemo.timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    FrameworkDemo.ModGraphVizSimple.show_logs(io, graph_thunk, logs, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, logs, :graphviz_simple) after the bug fix & update in the package
    # FrameworkDemo.Dagger.show_logs(graph_thunk, logs, :graphviz_simple) # Returns the string representation of the graph 
end

FrameworkDemo.dot_to_png(log_file_name, FrameworkDemo.timestamp_string(FILENAME_TEMPLATE) * ".png", 2000, 2000)