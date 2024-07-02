import Distributed

if abspath(PROGRAM_FILE) == @__FILE__
    new_procs = Distributed.addprocs(12, lazy=false) # Set the number of workers
end

import Dagger
import Graphs
import MetaGraphs
import FrameworkDemo
import FrameworkDemo.ModGraphVizSimple # This is a workaround to make visualization work until the bugs are fixed in the package.


# Defining constants
output_dir = "results"
graph1_path = "./data/sequencer_demo/df_sequencer_demo.graphml"
graph2_path = "./data/sequencer_demo/another_test_graph.graphml"

LOGS_FILE = FrameworkDemo.timestamp_string("$output_dir/out") * ".dot"
GRAPH_IMAGE_PATH = FrameworkDemo.timestamp_string("$output_dir/DAG") * ".png"

OUTPUT_GRAPH_PATH = "$output_dir/"
OUTPUT_GRAPH_IMAGE_PATH = "$output_dir/"

MAX_GRAPHS_RUN = 3

function execution(graphs_map::Dict{String, String})
    notifications = Channel{String}(32)
    dags = Dict{String, FrameworkDemo.TrackedTaskDAG}()
    running_dags = Set{String}()
    completed_dags = Set{String}()

    schedule_graphs(notifications, graphs_map, dags, running_dags, completed_dags)
    wait_dags_to_finish(notifications, dags, running_dags, completed_dags)
end

function parse_graph(graph_name::String, graph_path::String, output_graph_path::String, output_graph_image_path::String)
    parsed_graph_dot = FrameworkDemo.timestamp_string("$output_graph_path$graph_name") * ".dot"
    parsed_graph_image = FrameworkDemo.timestamp_string("$output_graph_image_path$graph_name") * ".png"
    G = FrameworkDemo.parse_graphml([graph_path])
    
    open(parsed_graph_dot, "w") do f
        MetaGraphs.savedot(f, G)
    end
    FrameworkDemo.dot_to_png(parsed_graph_dot, parsed_graph_image)
    return G
end

function schedule_graphs(notifications::Channel{String}, graphs_map::Dict{String, String},
    dags::Dict{String, FrameworkDemo.TrackedTaskDAG}, running_dags::Set{String}, completed_dags::Set{String})

    for (g_name, g_path) in graphs_map
        g = parse_graph(g_name, g_path, OUTPUT_GRAPH_PATH, OUTPUT_GRAPH_IMAGE_PATH)
        tracked_task_dag = FrameworkDemo.TrackedTaskDAG(g_name, g)
        dags[FrameworkDemo.get_uuid(tracked_task_dag)] = tracked_task_dag

        while length(running_dags) >= MAX_GRAPHS_RUN
            wait_dags_to_finish(notifications, dags, running_dags, completed_dags, length(running_dags) - MAX_GRAPHS_RUN + 1)
        end
        schedule_DAG(tracked_task_dag, notifications, running_dags)
    end    
end

function schedule_DAG(tracked_task_dag::FrameworkDemo.TrackedTaskDAG, notifications::Channel{String}, running_dags::Set{String})
    uuid = FrameworkDemo.get_uuid(tracked_task_dag)
    FrameworkDemo.start_DAG(tracked_task_dag)
    push!(running_dags, uuid)
    println("Dispatcher: graph scheduled - $uuid: $(FrameworkDemo.get_name(tracked_task_dag))")
    Threads.@spawn begin
        wait(tracked_task_dag)
        put!(notifications, string(FrameworkDemo.get_uuid(tracked_task_dag)))
    end
end

function wait_dags_to_finish(notifications::Channel{String}, dags::Dict{String, FrameworkDemo.TrackedTaskDAG}, running_dags::Set{String},
    completed_dags::Set{String}, num=length(running_dags))
    for i in 1:num
        uuid = take!(notifications)
        delete!(running_dags, uuid)
        push!(completed_dags, uuid)
        println("Dispatcher: graph finished - $uuid: $(FrameworkDemo.get_name(dags[uuid]))")
    end
end

function main(graphs_map)
    FrameworkDemo.configure_LocalEventLog()
    #
    # OR 
    #
    # configure_webdash_multievent()

    @time execution(graphs_map)

    ctx = Dagger.Sch.eager_context()
    logs = Dagger.TimespanLogging.get_logs!(ctx)
    open(LOGS_FILE, "w") do io
        FrameworkDemo.ModGraphVizSimple.show_logs(io, logs, :graphviz_simple)
    end
    FrameworkDemo.dot_to_png(LOGS_FILE, GRAPH_IMAGE_PATH, 7000, 8000) # adjust picture size, if needed (optional param)
    
end

graphs_map = Dict{String, String}(
"graph1" => graph1_path,
"graph2" => graph2_path,
"graph3" => graph1_path,
"graph4" => graph2_path
)

if abspath(PROGRAM_FILE) == @__FILE__
    mkpath(output_dir)
    main(graphs_map)
    Dagger.rmprocs!(Dagger.Sch.eager_context(), Distributed.workers())
    Distributed.rmprocs(Distributed.workers())
end
