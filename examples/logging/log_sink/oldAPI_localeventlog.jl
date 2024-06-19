import Colors # Writing logs into a file would fail without this import 

include("../../auxiliary/oldAPI_tasks.jl")
include("../../../utilities/auxiliary_functions.jl")

LOG_FILE = timestamp_string("./examples/logging/log_sink/results/oldAPI_localeventlog") * ".dot"

ctx = Dagger.Sch.eager_context()

# Setup the log sink (that basically chooses the behaviour of the logging mechanism)

# LocalEventLog
ctx.log_sink = Dagger.TimespanLogging.LocalEventLog()

# Set the logs file
ctx.log_file = LOG_FILE

t = task_setup(1)

# println(collect(t)) # Will not give logs
println(collect(ctx, t)) # Gives logs