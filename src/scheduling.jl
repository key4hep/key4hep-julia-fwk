using MetaGraphs
using OhMyThreads: @tasks, @set, @spawn
import NVTX
import Colors

const nvtx_colors = Colors.distinguishable_colors(32)

abstract type AbstractAlgorithm end

function (alg::AbstractAlgorithm)(args...; event_number::Int,
                                  coefficients::Union{Vector{Float64}, Nothing})
    error("Subtypes of AbstractAlgorithm must implement function call")
end

function get_name(alg::AbstractAlgorithm)
    error("Subtypes of AbstractAlgorithm must implement get_name")
end

struct BoundAlgorithm{T <: AbstractAlgorithm}
    alg::T
    event_number::Int
end

NVTX.@annotate get_name(algorithm) color=nvtx_colors[mod1(algorithm.event_number,
                                                          length(nvtx_colors))] payload=algorithm.event_number function (algorithm::BoundAlgorithm)(data...;
                                                                                                                                                    coefficients::Union{Vector{Float64},
                                                                                                                                                                        Nothing})
    return algorithm.alg(data...; event_number = algorithm.event_number,
                         coefficients = coefficients)
end

function get_name(alg::BoundAlgorithm)
    return get_name(alg.alg)
end

struct DataFlowGraph
    graph::MetaDiGraph{Int, Float64}
    algorithm_indices::Vector{Int}
    function DataFlowGraph(graph::MetaDiGraph)
        alg_vertices = MetaGraphs.filter_vertices(graph, :type, "Algorithm")
        sorted_vertices = MetaGraphs.topological_sort(graph)
        sorted_alg_vertices = intersect(sorted_vertices, alg_vertices)

        # cache number of algorithm dependencies for each algorithms
        # and indices of dependant algorithms
        for v in sorted_alg_vertices
            set_prop!(graph, v, :deps, 0)
        end
        for v in sorted_alg_vertices
            successor_algs = Vector{Int}()
            for data_successor in outneighbors(graph, v)
                successors = outneighbors(graph, data_successor)
                append!(successor_algs, successors)
            end
            unique!(successor_algs) # remove duplicates - algorithms consuming multiple objects produced by the the same algorithms
            set_prop!(graph, v, :successor_algs, successor_algs)
            for alg in successor_algs
                deps = get_prop(graph, alg, :deps)
                set_prop!(graph, alg, :deps, deps + 1)
            end
        end
        new(graph, sorted_alg_vertices)
    end
end

function get_algorithm(data_flow::DataFlowGraph, index::Int)::AbstractAlgorithm
    return get_prop(data_flow.graph, index, :algorithm)
end

struct Event
    data_flow::DataFlowGraph
    store::Dict{Int, Any}
    event_number::Int
    function Event(data_flow::DataFlowGraph, event_number::Int = 0)
        new(data_flow, Dict{Int, Any}(), event_number)
    end
end

function put_result!(event::Event, index::Int, result::Any)
    return event.store[index] = result
end

function put_results!(event::Event, indices, results)
    for (k, v) in zip(indices, results)
        put_result!(event, k, v)
    end
end

function get_result(event::Event, index::Int)::Any
    return event.store[index]
end

function get_results(event::Event, vertices::Vector{Int})
    return get_result.(Ref(event), vertices)
end

function is_terminating_alg(graph::AbstractGraph, vertex_id::Int)
    successor_dataobjects = outneighbors(graph, vertex_id)
    is_terminating(vertex) = isempty(outneighbors(graph, vertex))
    all(is_terminating, successor_dataobjects)
end

function schedule_algorithm(event::Event, vertex_id::Int,
                            coefficients::Union{Any, Nothing},
                            done_channel::Channel{Tuple{Int, Any}})
    # get the incoming vertices for this algorithm
    incoming_vertices = inneighbors(event.data_flow.graph, vertex_id)
    incoming_data = get_results(event, incoming_vertices)

    algorithm = BoundAlgorithm(get_algorithm(event.data_flow, vertex_id),
                               event.event_number)

    @spawn begin
        results = algorithm(incoming_data...; coefficients = coefficients)
        put!(done_channel, (vertex_id, results))
    end
end

function schedule_graph!(event::Event, coefficients::Union{Any, Nothing})
    algo_vertices = event.data_flow.algorithm_indices
    done_channel = Channel{Tuple{Int, Any}}(length(algo_vertices))  # channel to receive completion notifications
    algs_in_flight = 0 # number of algorithms currently running
    deps = Dict{Int, Int}() # map of algorithm vertices to number of dependencies

    # copy number of dependencies or immediately schedule algorithms without dependencies
    for v in algo_vertices
        deps_number = get_prop(event.data_flow.graph, v, :deps)
        if deps_number == 0
            schedule_algorithm(event, v, coefficients, done_channel)
            algs_in_flight += 1
        else
            deps[v] = deps_number
        end
    end

    while algs_in_flight > 0
        vertex_id, results = take!(done_channel)
        result_vertices = outneighbors(event.data_flow.graph, vertex_id)
        put_results!(event, result_vertices, results)
        algs_in_flight -= 1
        # Check algorithm children to see if they're ready
        for child in get_prop(event.data_flow.graph, vertex_id, :successor_algs)
            count = deps[child] -= 1
            if count == 0
                schedule_algorithm(event, child, coefficients, done_channel)
                algs_in_flight += 1
            end
        end
    end

    close(done_channel)
    return nothing
end

function calibrate_crunch(min::Int = 1000, max::Int = 200_000;
                          fast::Bool = false)::Union{Vector{Float64}, Nothing}
    return fast ? nothing : calculate_coefficients(min, max)
end

function run_pipeline(data_flow::DataFlowGraph;
                      event_count::Int,
                      max_concurrent::Int,
                      crunch_coefficients::Union{Vector{Float64}, Nothing} = nothing)
    @tasks for idx in 1:event_count
        @set begin
            ntasks = max_concurrent
        end
        @info dispatch_begin_msg(idx)
        event = Event(data_flow, idx)
        schedule_graph!(event, crunch_coefficients)
        @info dispatch_end_msg(idx)
    end
end
