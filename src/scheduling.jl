import Dagger
using Distributed
using Graphs
using MetaGraphs

mutable struct DataObject
    data
    size::Float64
end

function populate_data_object!(object::DataObject, data)
    proc = Dagger.thunk_processor()
    scope = Dagger.scope(worker=myid())

    chunk = Dagger.tochunk(data, proc, scope)

    object.data = chunk
end

# Algorithms
function _algorithm(graph::MetaDiGraph, vertex_id::Int)
    runtime = get_prop(graph, vertex_id, :runtime_average_s)

    function algorithm(inputs, outputs)
        println("Gaudi algorithm for vertex $vertex_id !")

        for output in outputs
            bytes = round(Int, output.size * 1e3)
            populate_data_object!(output, ' '^bytes)
        end

        sleep(runtime)
    end

    return algorithm
end

AVAILABLE_TRANSFORMS = Dict{String, Function}(
    "Algorithm" => _algorithm,
)

function get_transform(graph::MetaDiGraph, vertex_id::Int)
    type = get_prop(graph, vertex_id, :type)

    function f(data...; N_inputs)
        inputs = data[1:N_inputs]
        outputs = data[N_inputs+1:end]
        transform = AVAILABLE_TRANSFORMS[type](graph, vertex_id)
        return transform(inputs, outputs)
    end

    return f
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

function get_in_promises(G, vertex_id)
    return [get_prop(G, src, :res_data) for src in inneighbors(G, vertex_id)]
end

function get_out_promises(G, vertex_id)
    return [get_prop(G, src, :res_data) for src in outneighbors(G, vertex_id)]
end

function schedule_graph(G::MetaDiGraph)
    data_vertices = MetaGraphs.filter_vertices(G, :type, "DataObject")
    sorted_vertices = MetaGraphs.topological_sort(G)

    for data_id in data_vertices
        size = get_prop(G, data_id, :size_kb)
        set_prop!(G, data_id, :res_data, DataObject(nothing, size))
    end

    Dagger.spawn_datadeps() do
        for vertex_id in setdiff(sorted_vertices, data_vertices) 
            incoming_data = get_in_promises(G, vertex_id)
            outgoing_data = get_out_promises(G, vertex_id)
            transform = get_transform(G, vertex_id)
            N_inputs = length(incoming_data)
            res = Dagger.@spawn transform(In.(incoming_data)..., Out.(outgoing_data)...; N_inputs)
            set_prop!(G, vertex_id, :res_data, res)
        end
    end
end

function schedule_graph_with_notify(G::MetaDiGraph, notifications::RemoteChannel, graph_name::String, graph_id::Int)
    final_vertices = []

    schedule_graph(G)

    out_e_src_map = get_oute_map(G)
    for vertex_id in MetaGraphs.vertices(G)
        if !haskey(out_e_src_map, vertex_id)
            out_e_src_map[vertex_id] = []
        end
    end

    for vertex_id in keys(out_e_src_map)
        if out_e_src_map[vertex_id] == [] # TODO: a native method to check for emptiness should exist
            push!(final_vertices, vertex_id)
        end
    end

    Dagger.@spawn notify_graph_finalization(notifications, graph_name, graph_id, get_vertices_promises(final_vertices, G)...)
end
