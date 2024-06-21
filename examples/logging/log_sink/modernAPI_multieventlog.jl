import Colors # Writing logs into a file would fail without this import 
using key4hep_julia_fwk

include("../../tasks/modernAPI_tasks.jl")

output_dir = "examples/results/"
mkpath(output_dir)
LOG_FILE = key4hep_julia_fwk.timestamp_string("$output_dir/modernAPI_multieventlog") * ".dot"

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

println(fetch(t))

# The logs will not be written to the file, as fetch() definition does not seem to perform any such actions (as it was with collect() respectively).

# Workaround
# Some arguments to the thunks may not be displayed 

logs = Dagger.TimespanLogging.get_logs!(ctx) # Get all kind of logs on all the workers
events_logs = Dict()
for (key, value) in logs
    events_logs[key] = value[:full] # Leave only the events logs
end
spans = Dagger.TimespanLogging.build_timespans(vcat(values(events_logs)...)).completed # Form the timespans
timespan_logs = convert(Vector{Dagger.TimespanLogging.Timespan}, spans)
open(ctx.log_file, "w") do io
    Dagger.show_plan(io, timespan_logs) # Writes graph to a file
end
