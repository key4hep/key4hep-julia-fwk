using Colors
using DaggerWebDash
using Distributed
using Graphs
using MetaGraphs
using GraphViz
using Dates
using key4hep_julia_fwk

# Set the number of workers
# addprocs(12)

# Defining constants
graph1_path = "./data/sequencer_demo/df_sequencer_demo.graphml"
graph2_path = "./data/sequencer_demo/another_test_graph.graphml"

output_dir = "examples/results/"
mkpath(output_dir)

LOGS_FILE = key4hep_julia_fwk.timestamp_string(output_dir) * ".dot"
GRAPH_IMAGE_PATH = key4hep_julia_fwk.timestamp_string(output_dir) * ".png"


function parse_graphs(graphs_map::Dict)
    graphs = []
    for (graph_name, graph_path) in graphs_map
        parsed_graph_dot = key4hep_julia_fwk.timestamp_string("$output_dir/$graph_name") * ".dot"
        parsed_graph_image = key4hep_julia_fwk.timestamp_string("$output_dir/$graph_name") * ".png"
        G = key4hep_julia_fwk.parse_graphml([graph_path])
        # G_copy = deepcopy(G)
        # show_graph(G_copy)
        
        open(parsed_graph_dot, "w") do f
            MetaGraphs.savedot(f, G)
        end
        key4hep_julia_fwk.dot_to_png(parsed_graph_dot, parsed_graph_image)
        push!(graphs, G)
    end
    return graphs
end

function execution(graphs_map)
    graphs = parse_graphs(graphs_map)
    for g in graphs
        key4hep_julia_fwk.schedule_graph(g)
    end

    results = []
    for g in graphs
        g_map = Dict{Int, Any}()
        for vertex_id in Graphs.vertices(g)
            future = get_prop(g, vertex_id, :res_data)
            g_map[vertex_id] = fetch(future)
        end
        push!(results, g_map)
    end

    for res in results
        for (id, value) in res
            println("Final result for vertex $id: $value")
        end
    end
end

function main(graphs_map)
    key4hep_julia_fwk.configure_LocalEventLog()
    key4hep_julia_fwk.set_log_file(LOGS_FILE)
    #
    # OR 
    #
    # configure_webdash_multievent()

    @time execution(graphs_map)

    key4hep_julia_fwk.flush_logs_to_file()

    # println(fetch_LocalEventLog())

    key4hep_julia_fwk.dot_to_png(LOGS_FILE, GRAPH_IMAGE_PATH)
    
end

graphs_map = Dict{String, String}(
"graph1" => graph1_path,
"graph2" => graph2_path,
"graph3" => graph1_path,
"graph4" => graph2_path
)

main(graphs_map)
