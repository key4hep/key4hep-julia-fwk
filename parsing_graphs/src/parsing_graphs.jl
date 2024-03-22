module parsing_graphs

using EzXML
using MetaGraphs

include("GraphMLReader/GraphMLReader.jl")

file_path = joinpath("../data/sequencer_demo/df_sequencer_demo.graphml")
G = GraphMLReader.loadgraphml(file_path, "G")

println(G)
println(GraphMLReader.node_fields(G))
println(get_prop(G, 1, :type))
println(get_prop(G, 1, :class))
println(get_prop(G, 1, :original_id))
println(get_prop(G, 1, :node_id))

end # module parsing_graphs
