#module graphs_scheduling

using Colors
using DaggerWebDash
using Distributed
using MetaGraphs
using GraphViz
using Dates
include("../../utilities/GraphMLReader.jl/src/GraphMLReader.jl")

# Set the number of workers
addprocs(12)

# Including neccessary functions
include("./functions.jl")
include("../../utilities/auxiliary_functions.jl")
include("../../utilities/visualization_functions.jl")

# Defining constants
graph1_path = "./data/sequencer_demo/df_sequencer_demo.graphml"
graph2_path = "./data/sequencer_demo/another_test_graph.graphml"

LOGS_FILE = timestamp_string("./graphs_scheduling/results/logs/out") * ".dot"
GRAPH_IMAGE_PATH = timestamp_string("./graphs_scheduling/results/scheduler_images/DAG") * ".png"


function parse_stage(graphs_map::Dict)
    graphs = []
    for (graph_name, graph_path) in graphs_map
        parsed_graph_dot = timestamp_string("./graphs_scheduling/results/parsed_graphs/$graph_name") * ".dot"
        parsed_graph_image = timestamp_string("./graphs_scheduling/results/parsed_graphs_images/$graph_name") * ".png"
        G = parse_graphml([graph_path])
        # G_copy = deepcopy(G)
        # show_graph(G_copy)
        
        open(parsed_graph_dot, "w") do f
            MetaGraphs.savedot(f, G)
        end
        dot_to_png(parsed_graph_dot, parsed_graph_image)
        push!(graphs, G)
    end
    return graphs
end

function execution(graphs_map)
    graphs = parse_stage(graphs_map)
    for g in graphs
        schedule_graph(g)
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
    configure_LocalEventLog()
    set_log_file(LOGS_FILE)
    #
    # OR 
    #
    # configure_webdash_multievent()

    @time execution(graphs_map)

    # To be fixed
    flush_logs_to_file()

    # println(fetch_LocalEventLog())

    dot_to_png(LOGS_FILE, GRAPH_IMAGE_PATH)
    
end

graphs_map = Dict{String, String}(
"graph1" => graph1_path,
"graph2" => graph2_path,
"graph3" => graph1_path,
"graph4" => graph2_path
)

main(graphs_map)

#end # module graphs_scheduling