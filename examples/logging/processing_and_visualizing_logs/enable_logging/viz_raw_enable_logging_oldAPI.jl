# TODO: push "import Dagger: istask, dependents" to graphsimpleviz_ext
import Colors
using Distributed
using Dagger
using FrameworkDemo
include("../../../dummy_tasks.jl")

output_dir = "examples/results"
mkpath(output_dir)

FILENAME_TEMPLATE = "$output_dir/viz_raw_enable_logging_oldAPI"

Dagger.enable_logging!()

graph_thunk = oldAPI_graph_setup(1)

ctx = Dagger.Sch.eager_context()
println(collect(ctx, graph_thunk)) # Wait for the graph execution and fetch the results

log_file_name = FrameworkDemo.timestamp_string(FILENAME_TEMPLATE) * ".dot"
open(log_file_name, "w") do io
    #FrameworkDemo.ModGraphVizSimple.show_logs(io, graph_thunk, Dagger.fetch_logs!(), :graphviz_simple)
    FrameworkDemo.ModGraphVizSimple.show_logs(graph_thunk, Dagger.fetch_logs!(), :graphviz_simple)
end

FrameworkDemo.dot_to_png(log_file_name, FrameworkDemo.timestamp_string(FILENAME_TEMPLATE) * ".png", 700, 700)
