#module graphs_scheduling

import Base.wait
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
new_procs = addprocs(12, lazy=false)

@everywhere begin
    include("MetaTask.jl")
    include("TaskDAG.jl")
    include("TrackedTaskDAG.jl")
end

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

function execution(graphs_map::Dict{String, String})
    notifications = Channel{String}(32)
    dags = Dict{String, TrackedTaskDAG}()
    running_dags = Set{String}()
    done_dags = Set{String}()
    waiting_notifiers = Dict{String, Task}()
    lk = ReentrantLock() 

    schedule_graphs(notifications, graphs_map, dags, running_dags, done_dags, waiting_notifiers, lk)
    wait_dags_to_finish(notifications, dags, running_dags, done_dags, waiting_notifiers, lk)
end

function parse_graph(graph_name::String, graph_path::String, output_graph_path::String, output_graph_image_path::String)
    parsed_graph_dot = timestamp_string("$output_graph_path$graph_name") * ".dot"
    parsed_graph_image = timestamp_string("$output_graph_image_path$graph_name") * ".png"
    G = parse_graphml([graph_path])
    
    open(parsed_graph_dot, "w") do f
        MetaGraphs.savedot(f, G)
    end
    dot_to_png(parsed_graph_dot, parsed_graph_image)
    return G
end

function schedule_graphs(notifications::Channel{String}, graphs_map::Dict{String, String},
    dags::Dict{String, TrackedTaskDAG}, running_dags::Set{String}, done_dags::Set{String},
    waiting_notifiers::Dict{String, Task}, lk::ReentrantLock)

    for (g_name, g_path) in graphs_map
        g = parse_graph(g_name, g_path, OUTPUT_GRAPH_PATH, OUTPUT_GRAPH_IMAGE_PATH)
        tracked_task_dag = TrackedTaskDAG(g_name, g)
        dags[get_uuid(tracked_task_dag)] = tracked_task_dag

        while length(running_dags) >= MAX_GRAPHS_RUN
            wait_dags_to_finish(notifications, dags, running_dags, done_dags,
             waiting_notifiers, lk, length(running_dags) - MAX_GRAPHS_RUN + 1)
        end
        schedule_DAG(tracked_task_dag, notifications, running_dags, waiting_notifiers)
    end    
end

function schedule_DAG(tracked_task_dag::TrackedTaskDAG, notifications::Channel{String}, running_dags::Set{String}, waiting_notifiers::Dict{String, Task})
    uuid = get_uuid(tracked_task_dag)
    start_DAG(tracked_task_dag)
    push!(running_dags, uuid)
    println("Dispatcher: graph scheduled - $uuid: $(get_name(tracked_task_dag))")
    notifier = Threads.@spawn begin
        wait(tracked_task_dag)
        put!(notifications, string(get_uuid(tracked_task_dag)))
    end
    waiting_notifiers[uuid] = notifier
end

function wait_dags_to_finish(notifications::Channel{String}, dags::Dict{String, TrackedTaskDAG}, running_dags::Set{String},
     done_dags::Set{String}, waiting_notifiers::Dict{String, Task}, lk::ReentrantLock, num=length(waiting_notifiers))
    for i in 1:num
        uuid = take!(notifications)
        lock(lk)
        delete!(waiting_notifiers, uuid)
        delete!(running_dags, uuid)
        push!(done_dags, uuid)
        unlock(lk)
        println("Dispatcher: graph finished - $uuid: $(get_name(dags[uuid]))")
    end
end

function main(graphs_map)
    configure_LocalEventLog()

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