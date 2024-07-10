import Dagger
using Distributed
using MetaGraphs

# Algorithms
struct MockupAlgorithm
    name::String
    runtime::Float64
    input_length::UInt
    MockupAlgorithm(graph::MetaDiGraph, vertex_id::Int) = begin
        runtime = get_prop(graph, vertex_id, :runtime_average_s)
        name = get_prop(graph, vertex_id, :node_id)
        inputs = length(inneighbors(graph, vertex_id))
        new(name, runtime, inputs)
    end
end

function (alg::MockupAlgorithm)(args...)
    println("Executing $(alg.name)")

    return alg.name
end

function notify_graph_finalization(notifications::RemoteChannel, graph_name::String, graph_id::Int, final_vertices_promises...)
    println("Graph: $graph_name, entered notify, graph_id: $graph_id !")
    println("Graph: $graph_name, all tasks in the graph finished, graph_id: $graph_id !")
    put!(notifications, graph_id)
    println("Graph: $graph_name, notified, graph_id: $graph_id !")
end

function parse_graphs(graphs_map::Dict, output_graph_path::String, output_graph_image_path::String)
    graphs = []
    for (graph_name, graph_path) in graphs_map
        parsed_graph_dot = timestamp_string("$output_graph_path$graph_name") * ".dot"
        parsed_graph_image = timestamp_string("$output_graph_image_path$graph_name") * ".png"
        G = parse_graphml([graph_path])

        open(parsed_graph_dot, "w") do f
            MetaGraphs.savedot(f, G)
        end
        dot_to_png(parsed_graph_dot, parsed_graph_image)
        push!(graphs, (graph_name, G))
    end
    return graphs
end

function get_promises(graph::MetaDiGraph, vertices::Vector)
    return [get_prop(graph, v, :res_data) for v in vertices]
end

function is_terminating_alg(graph::AbstractGraph, vertex_id::Int)
    successor_dataobjects = outneighbors(graph, vertex_id)
    is_terminating(vertex) = isempty(outneighbors(graph, vertex))
    all(is_terminating, successor_dataobjects)
end

function schedule_algorithm!(graph::MetaDiGraph, vertex_id::Int)
    incoming_data = get_promises(graph, inneighbors(graph, vertex_id))
    algorithm = MockupAlgorithm(graph, vertex_id)
    Dagger.@spawn algorithm(incoming_data...)
end

function schedule_graph(graph::MetaDiGraph)
    alg_vertices = MetaGraphs.filter_vertices(graph, :type, "Algorithm")
    sorted_vertices = MetaGraphs.topological_sort(graph)

    terminating_results = []

    for vertex_id in intersect(sorted_vertices, alg_vertices)
        res = schedule_algorithm!(graph, vertex_id)
        set_prop!(graph, vertex_id, :res_data, res)
        for v in outneighbors(graph, vertex_id)
            set_prop!(graph, v, :res_data, res)
        end

        is_terminating_alg(graph, vertex_id) && push!(terminating_results, res)
    end

    return terminating_results
end

function schedule_graph_with_notify(graph::MetaDiGraph,
        notifications::RemoteChannel,
        graph_name::String,
        graph_id::Int)
    terminating_results = schedule_graph(graph)

    Dagger.@spawn notify_graph_finalization(notifications, graph_name, graph_id, terminating_results...)
end
