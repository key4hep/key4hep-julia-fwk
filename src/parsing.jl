using Graphs
using MetaGraphs
include("../deps/GraphMLReader.jl/src/GraphMLReader.jl")

function parse_graphml(filename::String)::MetaDiGraph
    GraphMLReader.loadgraphml(filename, "G")
end

function show_graph(G)
    for v in Graphs.vertices(G)
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
