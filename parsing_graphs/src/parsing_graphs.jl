module parsing_graphs

using EzXML
using Graphs
using MetaGraphs
using Dagger
include("../GraphMLReader.jl/src/GraphMLReader.jl")
include("./auxiliary_functions.jl")

function test_schedule_by_graph(G::MetaDiGraph)
    inc_e_src_map = get_ine_map(G)

    @sync for vertex_id in MetaGraphs.topological_sort(G)
        incoming_data = get_deps_promises(vertex_id, inc_e_src_map, G)
        set_prop!(G, vertex_id, :res_data, Dagger.@spawn wrapper(incoming_data, vertex_id))
    end

    for vertex_id in Graphs.vertices(G)
        future = get_prop(G, vertex_id, :res_data)
        result = fetch(future)
        println("Final result for vertex $vertex_id: $result")
    end
end

G = parse_graphml(["../data/sequencer_demo/df_sequencer_demo.graphml"])
G_copy = deepcopy(G)

test_schedule_by_graph(G_copy)
show_graph(G_copy)

end # module parsing_graphs
