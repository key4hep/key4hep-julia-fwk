import Dagger
using Distributed
using MetaGraphs

# Algorithms

abstract type AbstractAlgorithm end

function (alg::AbstractAlgorithm)(args...; event_number::Int,
                                  coefficients::Union{Vector{Float64}, Missing})
    error("Subtypes of AbstractAlgorithm must implement function call")
end

struct MockupAlgorithm <: AbstractAlgorithm
    name::String
    runtime::Float64
    input_length::UInt
    function MockupAlgorithm(graph::MetaDiGraph, vertex_id::Int)
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

function (alg::MockupAlgorithm)(args...; event_number::Int,
                                coefficients::Union{Vector{Float64}, Missing})
    println("Executing $(alg.name) event $event_number")
    if coefficients isa Vector{Float64}
        crunch_for_seconds(alg.runtime, coefficients)
    end

    return alg.name
end

struct BoundAlgorithm
    alg::AbstractAlgorithm
    event_number::Int
end

function (algorithm::BoundAlgorithm)(data...; coefficients::Union{Vector{Float64}, Missing})
    return algorithm.alg(data...; event_number = algorithm.event_number,
                         coefficients = coefficients)
end

struct DataFlowGraph
    graph::MetaDiGraph
    algorithm_indices::Vector{Int}
    function DataFlowGraph(graph::MetaDiGraph)
        alg_vertices = MetaGraphs.filter_vertices(graph, :type, "Algorithm")
        sorted_vertices = MetaGraphs.topological_sort(graph)
        sorted_alg_vertices = intersect(sorted_vertices, alg_vertices)
        new(graph, sorted_alg_vertices)
    end
end

function get_algorithm(data_flow::DataFlowGraph, index::Int)::AbstractAlgorithm
    return get_prop(data_flow.graph, index, :algorithm)
end

function mockup_dataflow(graph::MetaDiGraph)::DataFlowGraph
    data_flow = DataFlowGraph(graph)
    for i in data_flow.algorithm_indices
        alg = MockupAlgorithm(data_flow.graph, i)
        set_prop!(data_flow.graph, i, :algorithm, alg)
    end
    return data_flow
end

struct Event
    data_flow::DataFlowGraph
    store::Dict{Int, Dagger.DTask}
    event_number::Int
    function Event(data_flow::DataFlowGraph, event_number::Int = 0)
        new(data_flow, Dict{Int, Dagger.DTask}(), event_number)
    end
end

function put_result!(event::Event, index::Int, result::Dagger.DTask)
    return event.store[index] = result
end

function get_result(event::Event, index::Int)::Dagger.DTask
    return event.store[index]
end

function get_results(event::Event, vertices::Vector{Int})
    return get_result.(Ref(event), vertices)
end

function notify_graph_finalization(notifications::RemoteChannel, graph_id::Int,
                                   terminating_results...)
    println("Graph $graph_id: all tasks in the graph finished!")
    put!(notifications, graph_id)
    println("Graph $graph_id: notified!")
end

function is_terminating_alg(graph::AbstractGraph, vertex_id::Int)
    successor_dataobjects = outneighbors(graph, vertex_id)
    is_terminating(vertex) = isempty(outneighbors(graph, vertex))
    all(is_terminating, successor_dataobjects)
end

function schedule_algorithm(event::Event, vertex_id::Int,
                            coefficients::Union{Dagger.Shard, Nothing})
    incoming_data = get_results(event, inneighbors(event.data_flow.graph, vertex_id))
    algorithm = BoundAlgorithm(get_algorithm(event.data_flow, vertex_id),
                               event.event_number)
    if isnothing(coefficients)
        alg_helper(data...) = algorithm(data...; coefficients = missing)
        return Dagger.@spawn alg_helper(incoming_data...)
    else
        return Dagger.@spawn algorithm(incoming_data...; coefficients = coefficients)
    end
end

function schedule_graph!(event::Event, coefficients::Union{Dagger.Shard, Nothing})
    terminating_results = Dagger.DTask[]
    for vertex_id in event.data_flow.algorithm_indices
        res = schedule_algorithm(event, vertex_id, coefficients)
        put_result!(event, vertex_id, res)
        for v in outneighbors(event.data_flow.graph, vertex_id)
            put_result!(event, v, res)
        end
        is_terminating_alg(event.data_flow.graph, vertex_id) &&
            push!(terminating_results, res)
    end

    return terminating_results
end

function calibrate_crunch(; fast::Bool = false)::Union{Dagger.Shard, Nothing}
    return fast ? nothing : Dagger.@shard calculate_coefficients()
end

function run_pipeline(data_flow::DataFlowGraph;
                      event_count::Int,
                      max_concurrent::Int,
                      fast::Bool = false)
    graphs_tasks = Dict{Int, Dagger.DTask}()
    notifications = RemoteChannel(() -> Channel{Int}(max_concurrent))
    coefficients = FrameworkDemo.calibrate_crunch(; fast = fast)

    for idx in 1:event_count
        while length(graphs_tasks) >= max_concurrent
            finished_graph_id = take!(notifications)
            delete!(graphs_tasks, finished_graph_id)
            @info dispatch_end_msg(finished_graph_id)
        end
        event = Event(data_flow, idx)
        terminating_tasks = FrameworkDemo.schedule_graph!(event, coefficients)
        graphs_tasks[idx] = Dagger.@spawn notify_graph_finalization(notifications, idx,
                                                                    terminating_tasks...)

        @info dispatch_begin_msg(idx)
    end

    for (idx, future) in graphs_tasks
        wait(future)
        @info dispatch_end_msg(idx)
    end
end
