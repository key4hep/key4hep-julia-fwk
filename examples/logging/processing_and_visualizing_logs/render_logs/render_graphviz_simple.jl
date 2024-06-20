using Distributed
using Colors
using GraphViz
using Cairo
using Dagger

include("../../../auxiliary/example_tasks.jl")
include("../../../../utilities/auxiliary_functions.jl")

Dagger.enable_logging!(tasknames=true,
taskdeps=true,
taskargs=true,
taskargmoves=true,
)

a = modernAPI_graph_setup(0.1)

ctx = Dagger.Sch.eager_context()
println(fetch(a))

graph = Dagger.render_logs(Dagger.fetch_logs!(), :graphviz, disconnected=true, color_by=:proc)

surface = Cairo.CairoSVGSurface(IOBuffer(), 7000, 2000)
context = Cairo.CairoContext(surface)

GraphViz.render(context, graph)
img_name = timestamp_string("./examples/examples_results/render_logs/render_graphviz_simple") * ".png"
write_to_png(surface, img_name)
