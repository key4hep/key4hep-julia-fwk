import Colors # Writing logs into a file would fail without this import 

# This is a workaround to make visualization work until the bugs are fixed in the package.
include("../../../../dagger_exts/GraphVizSimpleExt.jl")
using .ModGraphVizSimpleExt


include("../../../auxiliary/example_tasks.jl")
include("../../../../utilities/auxiliary_functions.jl")
include("../../../auxiliary/example_auxiliaries.jl")

FILENAME_TEMPLATE = "./examples/examples_results/log_sink/viz_modernAPI_localeventlog"

ctx = Dagger.Sch.eager_context()

# Setup the log sink (that basically chooses the behaviour of the logging mechanism)
# LocalEventLog
ctx.log_sink = Dagger.TimespanLogging.LocalEventLog()

graph_thunk = modernAPI_graph_setup(1)
println(fetch(graph_thunk))

logs = Dagger.TimespanLogging.get_logs!(ctx)
log_file_name = timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    ModGraphVizSimpleExt.show_logs(io, graph_thunk, logs, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, logs, :graphviz_simple) after the bug fix in the package
    # or ModGraphVizSimpleExt.show_logs(io, logs, :graphviz_simple) # Dagger.show_logs(io, logs, :graphviz_simple) after the bug fix in the package
    # or ModGraphVizSimpleExt.show_logs(io, graph_thunk, :graphviz_simple) # Dagger.show_logs(io, graph_thunk, :graphviz_simple) after the bug fix in the package
end

dot_to_png(log_file_name, timestamp_string(FILENAME_TEMPLATE) * ".png", 2000, 2000)