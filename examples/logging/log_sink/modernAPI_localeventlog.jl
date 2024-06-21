import Colors # Writing logs into a file would fail without this import 
using key4hep_julia_fwk

include("../../tasks/modernAPI_tasks.jl")

output_dir = "examples/results/"
mkpath(output_dir)
LOG_FILE = key4hep_julia_fwk.timestamp_string("$output_dir/modernAPI_localeventlog") * ".dot"

ctx = Dagger.Sch.eager_context()

# Setup the log sink (that basically chooses the behaviour of the logging mechanism)

# LocalEventLog
ctx.log_sink = Dagger.TimespanLogging.LocalEventLog()

# Set the logs file
ctx.log_file = LOG_FILE

t = task_setup(1)

println(fetch(t))
# The logs will not be written to the file, as fetch() definition does not seem to perform any such actions (as it was with collect() respectively).


# The drawback of both workarounds is that some arguments to the thunks may not be displayed

# Workaround 1
# To flush the logs, uncomment this:
# t = Dagger.delayed(() -> begin println("Mock function to flush logs") end)()
# collect(ctx, t)

# Workaround 2

logs = Dagger.TimespanLogging.get_logs!(ctx)
open(ctx.log_file, "w") do io
    Dagger.show_plan(io, logs) # Writes graph to a file
end
