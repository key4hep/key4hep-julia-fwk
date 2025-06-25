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

function parse_graphml(filename::String, duration_scale::Float64)::MetaDiGraph
    g = GraphMLReader.loadgraphml(filename, "G")
    encode_ids!(g)

    algo_vertices = filter_vertices(g, :type, "Algorithm")
    for v in algo_vertices
        old_rt = get_prop(g, v, :runtime_average_s, 0.0)
        set_prop!(g, v, :runtime_average_s, old_rt * duration_scale)
    end
    return g
end
