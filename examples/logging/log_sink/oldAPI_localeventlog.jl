import Colors # Writing logs into a file would fail without this import 
using key4hep_julia_fwk

include("../../tasks/oldAPI_tasks.jl")

output_dir = "examples/results/"
mkpath(output_dir)
LOG_FILE = key4hep_julia_fwk.timestamp_string("$output_dir/oldAPI_localeventlog") * ".dot"

ctx = Dagger.Sch.eager_context()

# Setup the log sink (that basically chooses the behaviour of the logging mechanism)

# LocalEventLog
ctx.log_sink = Dagger.TimespanLogging.LocalEventLog()

# Set the logs file
ctx.log_file = LOG_FILE

t = task_setup(1)

# println(collect(t)) # Will not give logs
println(collect(ctx, t)) # Gives logs