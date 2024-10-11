using Graphs
using MetaGraphs
import GraphMLReader

function parse_graphml(filename::String)::MetaDiGraph
    return GraphMLReader.loadgraphml(filename, "G")
end
