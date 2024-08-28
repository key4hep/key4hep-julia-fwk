import Colors
import GraphViz
import FileIO
import DataFrames
import Plots

function save_logs_dot(logs, path::String)
    if splitext(path)[2] == ".dot"
        open(path, "w") do io
            ModGraphVizSimple.show_logs(io, logs, :graphviz_simple)
            @info "Written logs dot graph to $path"
        end
    else
        buffer = IOBuffer()
        ModGraphVizSimple.show_logs(buffer, logs, :graphviz_simple)
        dot = String(take!(buffer))
        graphviz = GraphViz.Graph(dot)
        GraphViz.layout!(graphviz; engine = "dot")
        FileIO.save(path, graphviz)
        @info "Written logs graph to $path"
    end
end
