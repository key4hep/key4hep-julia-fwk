using Graphs
using MetaGraphs
include("../ext/GraphMLReader/src/GraphMLReader.jl")

function parse_graphml(path)
    file_path = joinpath(path...)
    G = GraphMLReader.loadgraphml(file_path, "G")
end

function show_graph(G)
    for (_, v) in enumerate(Graphs.vertices(G))
        println("Node: ")
        print("Node type: ")
        println(get_prop(G, v, :type))
        print("Node class (only for algorithms): ")
        println(get_prop(G, v, :class))
        print("Original name: ")
        println(get_prop(G, v, :original_id))
        print("Node name: ")
        println(get_prop(G, v, :node_id))
        println()
    end
end