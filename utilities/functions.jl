@everywhere begin
    using DaggerWebDash
    using Dagger
    # Algorithms
    function mock_Gaudi_algorithm(id, data...)
        println("Gaudi algorithm for vertex $id !")
        sleep(1)
        # println("Previous vertices: $data")
        
        return id
    end

    function dataobject_algorithm(id, data...)
        sleep(0.1)
        return "dataobject"
    end

    function notify_graph_finalization(notifications::RemoteChannel, graph_id::Int, final_vertices_promises)
        # println("Entered notify $graph_id")
        for promise in final_vertices_promises
            wait(promise) # Actually, all the promises should be fulfilled at the moment of calling this function
        end
        put!(notifications, graph_id)
    end

    function mock_func()
        sleep(1)
        return
    end
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
        push!(graphs, G)
    end
    return graphs
end

function show_graph(G)
    for (_, v) in enumerate(Graphs.vertices(G))
        println("Node: ")
        print("Node type: ")
        println(get_prop(G, v, :type))
        if has_prop(G, v, :class)
            print("Node class: ")
            println(get_prop(G, v, :class))
        end
        if has_prop(G, v, :runtime_average_s)
            print("Average runtime [s]: ")
            println(get_prop(G, v, :runtime_average_s))
        end
        if has_prop(G, v, :size_average_B)
            print("Average size [B]: ")
            println(get_prop(G, v, :size_average_B))
        end
        print("Original name: ")
        println(get_prop(G, v, :original_id))
        print("Node name: ")
        println(get_prop(G, v, :node_id))
        println()
    end
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

function get_deps_promises(vertex_id, map, G)
    incoming_data = []
    if haskey(map, vertex_id)
        for src in map[vertex_id]
            push!(incoming_data, get_prop(G, src, :res_data))
        end
    end
    return incoming_data
end

function schedule_graph(G::MetaDiGraph)
    inc_e_src_map = get_ine_map(G)

    for vertex_id in MetaGraphs.topological_sort(G)
        incoming_data = get_deps_promises(vertex_id, inc_e_src_map, G)
        set_prop!(G, vertex_id, :res_data, Dagger.@spawn AVAILABLE_TRANSFORMS[get_prop(G, vertex_id, :type)](vertex_id, incoming_data...))
    end
end

function schedule_graph_with_notify(G::MetaDiGraph, notifications::RemoteChannel, graph_id::Int)
    final_vertices = []
    inc_e_src_map = get_ine_map(G)

    for vertex_id in MetaGraphs.topological_sort(G)
        incoming_data = get_deps_promises(vertex_id, inc_e_src_map, G)
        set_prop!(G, vertex_id, :res_data, Dagger.@spawn AVAILABLE_TRANSFORMS[get_prop(G, vertex_id, :type)](vertex_id, incoming_data...))
    end

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

    Dagger.@spawn notify_graph_finalization(notifications, graph_id, get_vertices_promises(final_vertices, G))
end

function flush_logs_to_file()
    ctx = Dagger.Sch.eager_context()
    logs = Dagger.TimespanLogging.get_logs!(ctx)
    open(ctx.log_file, "w") do io
        Dagger.show_plan(io, logs) # Writes graph to a file
    end
end


AVAILABLE_TRANSFORMS = Dict{String, Function}("Algorithm" => mock_Gaudi_algorithm, "DataObject" => dataobject_algorithm)
