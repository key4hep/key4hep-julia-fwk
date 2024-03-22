module GraphMLReader

using EzXML
using LightGraphs
using MetaGraphs
using Graphs

export loadgraphml,
    node_fields, edge_fields,
    check_node_fields, check_edge_fields,
    gmlid2metaid

include("graphml.jl")
include("util.jl")
end # module
