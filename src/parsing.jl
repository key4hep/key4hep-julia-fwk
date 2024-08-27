using Graphs
using MetaGraphs
include("../deps/GraphMLReader.jl/src/GraphMLReader.jl")

function parse_graphml(filename::String)::MetaDiGraph
    return GraphMLReader.loadgraphml(filename, "G")
end

