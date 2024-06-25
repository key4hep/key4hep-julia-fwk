#module graphs_scheduling

using Colors
using DaggerWebDash
using Distributed
using MetaGraphs
using GraphViz
using Dates
include("../../utilities/GraphMLReader.jl/src/GraphMLReader.jl")

# This is a workaround to make visualization work until the bugs are fixed in the package.
include("../../dagger_exts/GraphVizSimpleExt.jl")
using .ModGraphVizSimpleExt


# Set the number of workers
new_procs = addprocs(12)

# Including neccessary functions
include("../../utilities/functions.jl")
include("../../utilities/auxiliary_functions.jl")
include("../../utilities/visualization_functions.jl")

# if isdefined(Main, :Dagger) # The Dagger scheduler is already running (?)
#     ctx = Dagger.Sch.eager_context()
#     addprocs!(ctx, new_procs)
# end

# Defining constants
graph1_path = "./data/sequencer_demo/df_sequencer_demo.graphml"
graph2_path = "./data/sequencer_demo/another_test_graph.graphml"

LOGS_FILE = timestamp_string("./graphs_scheduling/results/logs/out") * ".dot"
GRAPH_IMAGE_PATH = timestamp_string("./graphs_scheduling/results/scheduler_images/DAG") * ".png"

OUTPUT_GRAPH_PATH = "./graphs_scheduling/results/parsed_graphs/"
OUTPUT_GRAPH_IMAGE_PATH = "./graphs_scheduling/results/parsed_graphs_images/"

MAX_GRAPHS_RUN = 3

function execution(graphs_map)
    graphs_being_run = Set{Int}()
    graphs_dict = Dict{Int, String}()

    graphs = parse_graphs(graphs_map, OUTPUT_GRAPH_PATH, OUTPUT_GRAPH_IMAGE_PATH)

    notifications = RemoteChannel(()->Channel{Int}(32))
    # notifications = Channel{Int}(32)

    for (i, (g_name, g)) in enumerate(graphs)
        graphs_dict[i] = g_name
        while !(length(graphs_being_run) < MAX_GRAPHS_RUN)
            finished_graph_id = take!(notifications)
            delete!(graphs_being_run, finished_graph_id)
            println("Dispatcher: graph finished - $finished_graph_id: $(graphs_dict[finished_graph_id])")
        end

        schedule_graph_with_notify(g, notifications, g_name, i)
        push!(graphs_being_run, i)
        println("Dispatcher: scheduled graph $i: $g_name")
    end

    results = []
    for (g_name, g) in graphs
        g_map = Dict{Int, Any}()
        for vertex_id in Graphs.vertices(g)
            future = get_prop(g, vertex_id, :res_data)
            g_map[vertex_id] = fetch(future)
        end
        push!(results, (g_name, g_map))
    end

    for (g_name, res) in results
        for (id, value) in res
            println("Graph: $g_name, Final result for vertex $id: $value")
        end
    end
end

function main(graphs_map)
    configure_LocalEventLog()
    #
    # OR 
    #
    # configure_webdash_multievent()

    @time execution(graphs_map)

    ctx = Dagger.Sch.eager_context()
    logs = Dagger.TimespanLogging.get_logs!(ctx)
    open(LOGS_FILE, "w") do io
        ModGraphVizSimpleExt.show_logs(io, logs, :graphviz_simple)
    end

    dot_to_png(LOGS_FILE, GRAPH_IMAGE_PATH, 7000, 8000) # adjust picture size, if needed (optional param)
    
end

graphs_map = Dict{String, String}(
"graph1" => graph1_path,
"graph2" => graph2_path,
"graph3" => graph1_path,
"graph4" => graph2_path
)

main(graphs_map)
rmprocs(workers()) # TODO: there is some issue here, as it throws errors, and restarting the file in the REPL ignores adding the procs

#end # module graphs_scheduling