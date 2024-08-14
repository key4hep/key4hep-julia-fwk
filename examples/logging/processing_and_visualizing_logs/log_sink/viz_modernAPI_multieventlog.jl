import Colors # Writing logs into a file would fail without this import 
using FrameworkDemo
include("../../../dummy_tasks.jl")

output_dir = "examples/results"
mkpath(output_dir)

FILENAME_TEMPLATE = "$output_dir/viz_modernAPI_multieventlog"

ctx = Dagger.Sch.eager_context()

# Setup the log sink (that basically chooses the behaviour of the logging mechanism)
# MultiEventLog
ml = Dagger.TimespanLogging.MultiEventLog()

# MultiEventLog configuration
ml[:core] = Dagger.TimespanLogging.Events.CoreMetrics()
ml[:id] = Dagger.TimespanLogging.Events.IDMetrics()
ml[:full] = Dagger.TimespanLogging.Events.FullMetrics()
ml[:timeline] = Dagger.TimespanLogging.Events.TimelineMetrics()
ml[:wsat] = Dagger.Events.WorkerSaturation()
ml[:loadavg] = Dagger.TimespanLogging.Events.CPULoadAverages()
ml[:bytes] = Dagger.Events.BytesAllocd()
ml[:mem] = Dagger.TimespanLogging.Events.MemoryFree()
ml[:esat] = Dagger.TimespanLogging.Events.EventSaturation()
ml[:psat] = Dagger.Events.ProcessorSaturation()

ctx.log_sink = ml

graph_thunk = modernAPI_graph_setup(1)
println(fetch(graph_thunk))

# Workaround to use show_logs() with the MultiEventLog
logs = Dagger.TimespanLogging.get_logs!(ctx) # Get all kind of logs on all the workers
events_logs = Dict()
for (key, value) in logs
    events_logs[key] = value[:full] # Leave only the events logs
end
spans = Dagger.TimespanLogging.build_timespans(vcat(values(events_logs)...)).completed # Form the timespans
timespan_logs = convert(Vector{Dagger.TimespanLogging.Timespan}, spans)
log_file_name = FrameworkDemo.timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    FrameworkDemo.ModGraphVizSimple.show_logs(io, graph_thunk, timespan_logs,
                                              :graphviz_simple) # Dagger.show_logs(io, graph_thunk, timespan_logs, :graphviz_simple) after the bug fix in the package
    # or FrameworkDemo.ModGraphVizSimpleExt.show_logs(io, timespan_logs, :graphviz_simple) # Dagger.show_logs(io, timespan_logs, :graphviz_simple) after the bug fix in the package
    # or FrameworkDemo.ModGraphVizSimpleExt.show_logs(io, graph_thunk, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, :graphviz_simple) after the bug fix in the package
end

FrameworkDemo.dot_to_png(log_file_name,
                         FrameworkDemo.timestamp_string(FILENAME_TEMPLATE) * ".png", 2000,
                         2000)
