using Distributed
new_procs = addprocs(4) # Set the number of workers
using Colors
using GraphViz
using Cairo
using Dagger
using FrameworkDemo
include("../../../dummy_tasks.jl")

output_dir = "examples/results"
mkpath(output_dir)

Dagger.enable_logging!(tasknames = true,
                       taskdeps = true,
                       taskargs = true,
                       taskargmoves = true)

a = modernAPI_graph_setup(0.1)

ctx = Dagger.Sch.eager_context()
println(fetch(a))

graph = Dagger.render_logs(Dagger.fetch_logs!(), :graphviz, disconnected = true,
                           color_by = :proc)

surface = Cairo.CairoSVGSurface(IOBuffer(), 7000, 2000)
context = Cairo.CairoContext(surface)

GraphViz.render(context, graph)
img_name = FrameworkDemo.timestamp_string("$output_dir/render_graphviz_simple") * ".png"
FrameworkDemo.write_to_png(surface, img_name)
