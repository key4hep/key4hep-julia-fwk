import Dagger
using Distributed
using MetaGraphs

# Algorithms
struct MockupAlgorithm
    name::String
    runtime::Float64
    input_length::UInt
    MockupAlgorithm(graph::MetaDiGraph, vertex_id::Int) = begin
        name = get_prop(graph, vertex_id, :node_id)
        if has_prop(graph, vertex_id, :runtime_average_s)
           runtime = get_prop(graph, vertex_id, :runtime_average_s)
        else
            runtime = alg_default_runtime_s
            @warn "Runtime not provided for $name algorithm. Using default value $runtime"
        end
        inputs = length(inneighbors(graph, vertex_id))
        new(name, runtime, inputs)
    end
end

alg_default_runtime_s::Float64 = 0

function (alg::MockupAlgorithm)(args...; coefficients::Vector{Float64})
    println("Executing $(alg.name)")
    crunch_for_seconds(alg.runtime, coefficients)

    return alg.name
end

function notify_graph_finalization(notifications::RemoteChannel, graph_id::Int, terminating_results...)
    println("Graph $graph_id: all tasks in the graph finished!")
    put!(notifications, graph_id)
    println("Graph $graph_id: notified!")
end

function get_promises(graph::MetaDiGraph, vertices::Vector)
    return [get_prop(graph, v, :res_data) for v in vertices]
end

function is_terminating_alg(graph::AbstractGraph, vertex_id::Int)
    successor_dataobjects = outneighbors(graph, vertex_id)
    is_terminating(vertex) = isempty(outneighbors(graph, vertex))
    all(is_terminating, successor_dataobjects)
end

function schedule_algorithm(graph::MetaDiGraph, vertex_id::Int, coefficients::Dagger.Shard)
    incoming_data = get_promises(graph, inneighbors(graph, vertex_id))
    algorithm = MockupAlgorithm(graph, vertex_id)
    Dagger.@spawn algorithm(incoming_data...; coefficients)
end

function schedule_graph(graph::MetaDiGraph, coefficients::Dagger.Shard)
    alg_vertices = MetaGraphs.filter_vertices(graph, :type, "Algorithm")
    sorted_vertices = MetaGraphs.topological_sort(graph)

    terminating_results = []

    for vertex_id in intersect(sorted_vertices, alg_vertices)
        res = schedule_algorithm(graph, vertex_id, coefficients)
        set_prop!(graph, vertex_id, :res_data, res)
        for v in outneighbors(graph, vertex_id)
            set_prop!(graph, v, :res_data, res)
        end

        is_terminating_alg(graph, vertex_id) && push!(terminating_results, res)
    end

    return terminating_results
end

function run_events(graph::MetaDiGraph,
        event_count::Int,
        max_concurrent::Int)

    graphs_tasks = Dict{Int,Dagger.DTask}()
    notifications = RemoteChannel(()->Channel{Int}(32))
    coefficients = Dagger.@shard FrameworkDemo.calculate_coefficients()

    for idx in 1:event_count
        while length(graphs_tasks) >= max_concurrent 
            finished_graph_id = take!(notifications)
            delete!(graphs_tasks, finished_graph_id)
            println("Dispatcher: graph finished - graph $finished_graph_id")
        end

        terminating_results = FrameworkDemo.schedule_graph(graph, coefficients)
        graphs_tasks[idx] = Dagger.@spawn notify_graph_finalization(notifications, idx, terminating_results...)

        println("Dispatcher: scheduled graph $idx")
    end

    values(graphs_tasks) .|> wait
end
