using Distributed

if abspath(PROGRAM_FILE) == @__FILE__
    new_procs = addprocs(12) # Set the number of workers
end

using Dagger
using Graphs
using MetaGraphs
using FrameworkDemo
using FrameworkDemo.ModGraphVizSimple # This is a workaround to make visualization work until the bugs are fixed in the package.


# Defining constants
output_dir = "results"
graph1_path = "./data/sequencer_demo/df_sequencer_demo.graphml"
graph2_path = "./data/sequencer_demo/another_test_graph.graphml"

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
        data_vertices = MetaGraphs.filter_vertices(g, :type, "DataObject")
        for vertex_id in data_vertices
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
    FrameworkDemo.configure_LocalEventLog()

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
    rmprocs!(Dagger.Sch.eager_context(), workers())
    rmprocs(workers())
end
