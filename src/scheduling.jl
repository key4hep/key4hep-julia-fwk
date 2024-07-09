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

# Function to get the map of incoming edges to a vertex (i.e. the sources of the incoming edges)
function get_ine_map(G)
    incoming_edges_sources_map = Dict{eltype(G), Vector{eltype(G)}}()

    for edge in Graphs.edges(G)
        src_vertex = src(edge)
        dest_vertex = dst(edge)

        if haskey(incoming_edges_sources_map, dest_vertex)
            push!(incoming_edges_sources_map[dest_vertex], src_vertex)
        else
            incoming_edges_sources_map[dest_vertex] = [src_vertex]
        end
    end

    return incoming_edges_sources_map
end

# Function to get the map of outgoing edges from a vertex (i.e. the destinations of the outgoing edges)
function get_oute_map(G)
    outgoing_edges_destinations_map = Dict{eltype(G), Vector{eltype(G)}}()

    for edge in Graphs.edges(G)
        src_vertex = src(edge)
        dest_vertex = dst(edge)

        if haskey(outgoing_edges_destinations_map, src_vertex)
            push!(outgoing_edges_destinations_map[src_vertex], dest_vertex)
        else
            outgoing_edges_destinations_map[src_vertex] = [dest_vertex]
        end
    end

    return outgoing_edges_destinations_map
end

function get_vertices_promises(vertices::Vector, G::MetaDiGraph)
    promises = []
    for vertex in vertices
        push!(promises, get_prop(G, vertex, :res_data))
    end
    return promises
end

function get_in_promises(graph::MetaDiGraph, vertex_id::Int)
    return [get_prop(graph, src, :res_data) for src in inneighbors(graph, vertex_id)]
end

function schedule_algorithm!(graph::MetaDiGraph, vertex_id::Int)
    incoming_data = get_in_promises(graph, vertex_id)
    algorithm = MockupAlgorithm(graph, vertex_id)
    Dagger.@spawn algorithm(incoming_data...)
end

function schedule_graph(G::MetaDiGraph)
    alg_vertices = MetaGraphs.filter_vertices(G, :type, "Algorithm")
    sorted_vertices = MetaGraphs.topological_sort(G)

    for vertex_id in intersect(sorted_vertices, alg_vertices)
        res = schedule_algorithm!(G, vertex_id)
        for v in outneighbors(G, vertex_id)
            set_prop!(G, v, :res_data, res)
        end
    end
end

function schedule_graph_with_notify(G::MetaDiGraph, notifications::RemoteChannel, graph_name::String, graph_id::Int)
    schedule_graph(G::MetaDiGraph)

    final_vertices = []

    out_e_src_map = get_oute_map(G)
    for vertex_id in MetaGraphs.vertices(G)
        if !haskey(out_e_src_map, vertex_id)
            out_e_src_map[vertex_id] = []
        end
    end

    for vertex_id in keys(out_e_src_map)
        if isempty(out_e_src_map[vertex_id])
            push!(final_vertices, vertex_id)
        end
    end

    Dagger.@spawn notify_graph_finalization(notifications, graph_name, graph_id, get_vertices_promises(final_vertices, G)...)
end
