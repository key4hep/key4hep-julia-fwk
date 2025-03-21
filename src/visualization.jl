import GraphViz
import FileIO
import DataFrames
import Plots
import JSON3

function save_trace(trace, ::String, ::Val{T}) where {T}
    throw(ArgumentError("Unsupported visualization mode: `$T`"))
end

function save_trace(trace, path::String, mode::Symbol)
    return save_trace(trace, path, Val{mode}())
end

function save_trace(trace, path::String, ::Val{:graph})
    if splitext(path)[2] == ".dot"
        open(path, "w") do io
            Dagger.show_logs(io, trace, :graphviz; color_by = :proc)
            @info "Written trace dot graph to $path"
        end
    else
        graphviz = Dagger.render_logs(trace, :graphviz; color_by = :proc)
        FileIO.save(path, graphviz)
        @info "Written trace graph to $path"
    end
end

function save_trace(trace, path::String, ::Val{:chrome})
    open(path, "w") do io
        Dagger.show_logs(io, trace, :chrome_trace)
        @info "Written chrome trace to $path"
    end
end

function save_trace(trace, path::String, ::Val{:gantt})
    plot = Dagger.render_logs(trace, :plots_gantt)
    Plots.savefig(plot, path)
    @info "Written trace gantt chart to $path"
end

function save_trace(trace, path::String, ::Val{:raw})
    if splitext(path)[2] == ".json"
        open(path, "w") do io
            JSON3.write(io, trace)
            @info "Written raw json trace to $path"
        end
    else
        open(path, "w") do io
            println(io, trace)
            @info "Written raw trace to $path"
        end
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

    for i in vertices(g)
        set_prop!(g, i, :shape, "box")
    end

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
