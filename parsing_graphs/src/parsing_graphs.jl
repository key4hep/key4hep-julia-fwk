module parsing_graphs

using EzXML
using Graphs
using MetaGraphs
using Dagger
using DaggerWebDash
include("../../utilities/GraphMLReader.jl/src/GraphMLReader.jl")
include("../../utilities/auxiliary_functions.jl")


function main()
    G = parse_graphml(["./data/sequencer_demo/df_sequencer_demo.graphml"])
    G_copy = deepcopy(G)
    show_graph(G_copy)
end

main()

end # module parsing_graphs