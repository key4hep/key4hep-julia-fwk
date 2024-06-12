import Colors # Writing logs into a file would fail without this import 

include("../../auxiliary/oldAPI_tasks.jl")
include("../../../utilities/auxiliary_functions.jl")

LOG_FILE = timestamp_string("./examples/logging/log_sink/results/oldAPI_multieventlog") * ".dot"

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

# Set the logs file
ctx.log_file = LOG_FILE

t = task_setup(1)

# Should give the warning: only LocalEventLog log_sink is supported to write logs in this way. Therefore, the log file will be empty. 
println(collect(ctx, t))

# Workaround to write logs to a file in a .dot format

logs = Dagger.TimespanLogging.get_logs!(ctx) # Get all kind of logs on all the workers
events_logs = Dict()
for (key, value) in logs
    events_logs[key] = value[:full] # Leave only the events logs
end
spans = Dagger.TimespanLogging.build_timespans(vcat(values(events_logs)...)).completed # Form the timespans
timespan_logs = convert(Vector{Dagger.TimespanLogging.Timespan}, spans)
open(ctx.log_file, "w") do io
    Dagger.show_plan(io, timespan_logs, t) # Writes graph to a file
end
