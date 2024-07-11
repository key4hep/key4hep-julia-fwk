using Distributed
new_procs = addprocs(4) # Set the number of workers
using Colors
using GraphViz
using Cairo
using Dagger
using DataFrames
using Plots
using DaggerWebDash
using Graphs
using MetaGraphs
using FrameworkDemo

# Defining constants
graph1_path = "./data/demo/sequencer/df.graphml"
graph2_path = "./data/demo/parallel/df.graphml"

output_dir = "examples/results"
mkpath(output_dir)
LOGS_FILE = FrameworkDemo.timestamp_string("$output_dir/out") * ".dot"
GRAPH_IMAGE_PATH = FrameworkDemo.timestamp_string("$output_dir/DAG") * ".png"

OUTPUT_GRAPH_PATH = "$output_dir/"
OUTPUT_GRAPH_IMAGE_PATH = "$output_dir/"

MAX_GRAPHS_RUN = 3

function execution(graphs_map)
    graphs_being_run = Set{Int}()
    graphs_dict = Dict{Int, String}()
    graphs_tasks = Dict{Int,Dagger.DTask}()
    graphs = FrameworkDemo.parse_graphs(graphs_map, OUTPUT_GRAPH_PATH, OUTPUT_GRAPH_IMAGE_PATH)
    notifications = RemoteChannel(()->Channel{Int}(32))
    # notifications = Channel{Int}(32)
    for (i, (g_name, g)) in enumerate(graphs)
        graphs_dict[i] = g_name
        while !(length(graphs_being_run) < MAX_GRAPHS_RUN)
            finished_graph_id = take!(notifications)
            delete!(graphs_being_run, finished_graph_id)
            delete!(graphs_tasks, i)
            println("Dispatcher: graph finished - $finished_graph_id: $(graphs_dict[finished_graph_id])")
        end
        graphs_tasks[i] = FrameworkDemo.schedule_graph_with_notify(g, notifications, g_name, i)
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
    for (_, task) in graphs_tasks
        wait(task)
    end
end

function main(graphs_map)
    Dagger.enable_logging!(tasknames=true,
    taskdeps=true,
    taskargs=true, 
    taskargmoves=true,
    )

    @time execution(graphs_map)

    plot = Dagger.render_logs(Dagger.fetch_logs!(), :plots_gantt_ps)
    display(plot)
end

graphs_map = Dict{String, String}(
"graph1" => graph1_path,
"graph2" => graph2_path,
"graph3" => graph1_path,
"graph4" => graph2_path
)

main(graphs_map)
rmprocs!(Dagger.Sch.eager_context(), workers())
rmprocs(workers())