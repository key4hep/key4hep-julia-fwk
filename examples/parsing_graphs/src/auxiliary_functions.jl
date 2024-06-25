using Graphs

function mockup_function(data::Vector)
    push!(data, 0) # so data is never empty
    result = sum(fetch, data)
    result += 1
    return result
end

function wrapper(data::Vector, vertex_id)
    resulting_data = mockup_function(data)
    # println("Vertex $vertex_id processed with resulting_data: $resulting_data")
    return resulting_data
end

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

function get_deps_promises(vertex_id, map, G)
    incoming_data = []
    if haskey(map, vertex_id)
        for src in map[vertex_id]
            push!(incoming_data, get_prop(G, src, :res_data))
        end
    end
    return incoming_data
end

function parse_graphml(path)
    file_path = joinpath(path...)
    G = GraphMLReader.loadgraphml(file_path, "G")
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

