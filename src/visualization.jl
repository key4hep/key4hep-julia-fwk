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

function get_execution_plan(df::DataFlowGraph)::MetaDiGraph
    g = MetaDiGraph()
    for (i, v) in enumerate(df.algorithm_indices)
        add_vertex!(g)
        label = get_name(get_prop(df.graph, i, :algorithm))
        set_prop!(g, i, :label, label)
    end
    set_indexing_prop!(g, :label)
    dataobject_indices = filter_vertices(df.graph, :type, "DataObject")

    get_algs(indices) = get_prop.(Ref(df.graph), indices, Ref(:algorithm))
    names_to_vertices(labels) = getindex.(Ref(g), labels, Ref(:label))
    translate_alg_vertices(indices) = indices |> get_algs .|>
                                      get_name .|> names_to_vertices

    for dataobject_idx in dataobject_indices
        predecessors_vertices = inneighbors(df.graph, dataobject_idx) |>
                                translate_alg_vertices
        successors_vertices = outneighbors(df.graph, dataobject_idx) |>
                              translate_alg_vertices
        for (i, j) in Iterators.product(predecessors_vertices, successors_vertices)
            if !has_edge(g, i, j)
                add_edge!(g, i, j)
            end
        end
    end
    return g
end

function save_execution_plan(df::DataFlowGraph, path::String)
    g = get_execution_plan(df)
    if splitext(path)[2] == ".dot"
        open(path, "w") do io
            MetaGraphs.savedot(io, g)
            @info "Written execution plan dot graph to $path"
        end
    else
        buffer = IOBuffer()
        MetaGraphs.savedot(buffer, g)
        dot = String(take!(buffer))
        graphviz = GraphViz.Graph(dot)
        GraphViz.layout!(graphviz; engine = "dot")
        FileIO.save(path, graphviz)
        @info "Written execution plan graph to $path"
    end
end
