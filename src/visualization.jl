import GraphViz
import FileIO
import DataFrames
import Plots
import JSON3

function save_logs_graphviz(logs, path::String)
    if splitext(path)[2] == ".dot"
        open(path, "w") do io
            Dagger.show_logs(io, logs, :graphviz; color_by = :proc)
            @info "Written logs dot graph to $path"
        end
    else
        graphviz = Dagger.render_logs(logs, :graphviz; color_by = :proc)
        FileIO.save(path, graphviz)
        @info "Written logs graph to $path"
    end
end

function save_logs_chrome_trace(logs, path::String)
    open(path, "w") do io
        Dagger.show_logs(io, logs, :chrome_trace)
        @info "Written logs trace to $path"
    end
end

function save_logs_gantt(logs, path::String)
    plot = Dagger.render_logs(logs, :plots_gantt)
    Plots.savefig(plot, path)
    @info "Written logs gantt chart to $path"
end

function save_logs_raw(logs, path::String)
    open(path, "w") do io
        println(io, logs)
        @info "Written raw logs to $path"
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
