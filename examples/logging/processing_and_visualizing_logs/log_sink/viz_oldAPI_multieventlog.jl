import Colors # Writing logs into a file would fail without this import 

# This is a workaround to make visualization work until the bugs are fixed in the package.
include("../../../../dagger_exts/GraphVizSimpleExt.jl")
using .ModGraphVizSimpleExt


include("../../../auxiliary/example_tasks.jl")
include("../../../../utilities/auxiliary_functions.jl")
include("../../../auxiliary/example_auxiliaries.jl")

FILENAME_TEMPLATE = "./examples/examples_results/log_sink/viz_oldAPI_multieventlog"

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

graph_thunk = oldAPI_graph_setup(1)
println(collect(ctx, graph_thunk))

# Workaround to use show_logs() with the MultiEventLog
logs = Dagger.TimespanLogging.get_logs!(ctx) # Get all kind of logs on all the workers
events_logs = Dict()
for (key, value) in logs
    events_logs[key] = value[:full] # Leave only the events logs
end
spans = Dagger.TimespanLogging.build_timespans(vcat(values(events_logs)...)).completed # Form the timespans
timespan_logs = convert(Vector{Dagger.TimespanLogging.Timespan}, spans)
log_file_name = timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    ModGraphVizSimpleExt.show_logs(io, graph_thunk, timespan_logs, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, timespan_logs, :graphviz_simple) after the bug fix in the package
    # or ModGraphVizSimpleExt.show_logs(io, timespan_logs, :graphviz_simple) # Dagger.show_logs(io, timespan_logs, :graphviz_simple) after the bug fix in the package
    # or ModGraphVizSimpleExt.show_logs(io, graph_thunk, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, :graphviz_simple) after the bug fix in the package
end

dot_to_png(log_file_name, timestamp_string(FILENAME_TEMPLATE) * ".png", 2000, 2000)