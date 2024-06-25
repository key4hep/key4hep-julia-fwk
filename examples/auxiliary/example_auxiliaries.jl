using GraphViz
using FileIO
using Cairo


function dot_to_png(in, out, width=7000, height=2000)
    dot_code = read(in, String)
    graph = GraphViz.load(IOBuffer(dot_code))
    GraphViz.layout!(graph)

    surface = Cairo.CairoSVGSurface(IOBuffer(), width, height)
    context = Cairo.CairoContext(surface)

    GraphViz.render(context, graph)
    write_to_png(surface, out)
end
