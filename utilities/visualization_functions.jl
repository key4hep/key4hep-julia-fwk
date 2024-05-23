using GraphViz
using FileIO
using Cairo


function dot_to_png(in, out)
    dot_code = read(in, String)
    graph = GraphViz.load(IOBuffer(dot_code))
    GraphViz.layout!(graph)

    surface = Cairo.CairoSVGSurface(IOBuffer(), 5000, 2000)
    context = Cairo.CairoContext(surface)

    GraphViz.render(context, graph)
    write_to_png(surface, out);
end
