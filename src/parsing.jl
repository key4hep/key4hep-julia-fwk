using Graphs
using MetaGraphs
import GraphMLReader

"Poor man's node ids encoding with selected HTML entities"
function encode_ids!(g)
    for i in vertices(g)
        label = get_prop(g, i, :node_id)
        encoded_label = replace(label, "<" => "&lt;", ">" => "&gt;")
        set_prop!(g, i, :node_id, encoded_label)
    end
end

"""
    parse_graphml(filename::String) -> MetaDiGraph
"""
function parse_graphml(filename::String)
    g = GraphMLReader.loadgraphml(filename, "G")
    encode_ids!(g)
    return g
end
