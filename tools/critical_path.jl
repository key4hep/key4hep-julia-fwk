using ArgParse
using Graphs
using MetaGraphs
using GraphViz
using FileIO
using Printf
import GraphMLReader

const default_runtime = 0.0

function parse_args(args)
    s = ArgParseSettings(description = "Get critical path from data-flow graph.")
    @add_arg_table! s begin
        "input"
        help = "Input data-flow graph as a GraphML file"
        arg_type = String
        required = true

        "--output", "-o"
        help = "Output critical path graph. Either dot or graphics file format like png, svg, pdf "
        arg_type = String
        required = false
    end
    return ArgParse.parse_args(args, s)
end

function make_execution_graph(graph)
    exec_graph = MetaDiGraph()
    org2exec = Dict{Int, Int}()
    for (i, v) in enumerate(filter_vertices(graph, :type, "Algorithm"))
        add_vertex!(exec_graph)
        if has_prop(graph, v, :runtime_average_s)
            runtime = get_prop(graph, v, :runtime_average_s)
        else
            @warn "Runtime not provided for $(get_prop(graph, v, :node_id)) algorithm. Using default value $default_runtime"
            runtime = default_runtime
        end
        set_prop!(exec_graph, i, :runtime_average_s, runtime)
        set_prop!(exec_graph, i, :node_id, get_prop(graph, v, :node_id))
        org2exec[v] = i
    end
    for dataobject_idx in filter_vertices(graph, :type, "DataObject")
        predecessors = map(x -> org2exec[x], inneighbors(graph, dataobject_idx))
        successors = map(x -> org2exec[x], outneighbors(graph, dataobject_idx))
        for (p_idx, s_idx) in Iterators.product(predecessors, successors)
            if !has_edge(exec_graph, p_idx, s_idx)
                add_edge!(exec_graph, p_idx, s_idx, :weight,
                          get_prop(exec_graph, p_idx, :runtime_average_s))
            end
        end
    end
    return exec_graph
end

function get_critical_path_length(graph, indices)
    return sum(get_prop.(Ref(graph), indices, Ref(:runtime_average_s)))
end

function make_critical_path_graph(exec_graph, indices)
    graph = MetaDiGraph(length(indices))
    for (i, v) in enumerate(indices)
        set_prop!(graph, i, :label, get_prop(exec_graph, v, :node_id))
        set_prop!(graph, i, :shape, "box")
    end
    for i in 1:(nv(graph) - 1)
        add_edge!(graph, i, i + 1)
    end
    return graph
end

function save_graph(graph, path)
    if splitext(path)[2] == ".dot"
        open(path, "w") do io
            MetaGraphs.savedot(io, graph)
            @info "Written dot graph to $path"
        end
    else
        buffer = IOBuffer()
        MetaGraphs.savedot(buffer, graph)
        seekstart(buffer)
        graphviz = GraphViz.Graph(buffer)
        GraphViz.layout!(graphviz; engine = "dot")
        FileIO.save(path, graphviz)
        @info "Written graph to $path"
    end
end

function (@main)(raw_args)
    args = parse_args(raw_args)
    graph = GraphMLReader.loadgraphml(args["input"], "G")
    exec_graph = make_execution_graph(graph)
    indices = dag_longest_path(exec_graph)
    critical_path_length = get_critical_path_length(exec_graph, indices)
    @info "Critical path number of algorithms: $(length(indices))"
    @info "Critical path length (s): $(critical_path_length)"

    output_file = args["output"]
    if isnothing(output_file)
        return 0
    end

    critical_path_graph = make_critical_path_graph(exec_graph, indices)
    save_graph(critical_path_graph, output_file)
    return 0
end
