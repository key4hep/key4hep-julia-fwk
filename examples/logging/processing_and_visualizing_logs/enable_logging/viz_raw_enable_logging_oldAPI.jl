# TODO: push "import Dagger: istask, dependents" to graphsimpleviz_ext

import Colors
using Distributed
using Dagger

# This is a workaround to make visualization work until the bugs are fixed in the package.
include("../../../../dagger_exts/GraphVizSimpleExt.jl")
using .ModGraphVizSimpleExt

include("../../../auxiliary/example_tasks.jl")
include("../../../../utilities/auxiliary_functions.jl")
include("../../../../utilities/visualization_functions.jl")

FILENAME_TEMPLATE = "./examples/examples_results/enable_logging/viz_raw_enable_logging_oldAPI"

Dagger.enable_logging!()

graph_thunk = oldAPI_graph_setup(1)

ctx = Dagger.Sch.eager_context()
println(collect(ctx, graph_thunk)) # Wait for the graph execution and fetch the results

log_file_name = timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    # ModGraphVizSimpleExt.show_logs(io, graph_thunk, Dagger.fetch_logs!(), :graphviz_simple)
    ModGraphVizSimpleExt.show_logs(graph_thunk, Dagger.fetch_logs!(), :graphviz_simple)
end

dot_to_png(log_file_name, timestamp_string(FILENAME_TEMPLATE) * ".png", 700, 700)
