#!/usr/bin/env julia

using Colors
using DaggerWebDash
using Distributed
using MetaGraphs
using Graphs
using GraphViz
using Dates
using key4hep_julia_fwk
@everywhere using Distributed, Dagger
# if isdefined(Main, :Dagger) # The Dagger scheduler is already running (?)
#     ctx = Dagger.Sch.eager_context()
#     addprocs!(ctx, new_procs)
# end

# Defining constants
graph1_path = "./data/sequencer_demo/df_sequencer_demo.graphml"
graph2_path = "./data/sequencer_demo/another_test_graph.graphml"

output_dir = "results/"
LOGS_FILE = key4hep_julia_fwk.timestamp_string(output_dir) * ".dot"
GRAPH_IMAGE_PATH = key4hep_julia_fwk.timestamp_string(output_dir) * ".png"

OUTPUT_GRAPH_PATH = output_dir
OUTPUT_GRAPH_IMAGE_PATH = output_dir

MAX_GRAPHS_RUN = 3

function execution(graphs_map)
    graphs_being_run = Set{Int}()

    graphs = key4hep_julia_fwk.parse_graphs(graphs_map, OUTPUT_GRAPH_PATH, OUTPUT_GRAPH_IMAGE_PATH)

    notifications = RemoteChannel(()->Channel{Int}(32))

    for (i, g) in enumerate(graphs)
        
        while !(length(graphs_being_run) < MAX_GRAPHS_RUN)
            finished_graph_id = take!(notifications)
            delete!(graphs_being_run, finished_graph_id)
            println("Dispatcher: graph finished - $finished_graph_id")
        end

        key4hep_julia_fwk.schedule_graph_with_notify(g, notifications, i)
        push!(graphs_being_run, i)
        println("Dispatcher: scheduled graph $i")
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

if abspath(PROGRAM_FILE) == @__FILE__
    mkpath(output_dir)
    #new_procs = addprocs(1) # Set the number of workers
    main(graphs_map)
    rmprocs(workers()) # TODO: there is some issue here, as it throws errors, and restarting the file in the REPL ignores adding the procs

end
