using MetaGraphs
using Base.Threads
import NVTX
using Colors

nvtx_color = Colors.distinguishable_colors(32)

abstract type AbstractAlgorithm end

function (alg::AbstractAlgorithm)(args...; event_number::Int,
                                  coefficients::Union{Vector{Float64}, Missing})
    error("Subtypes of AbstractAlgorithm must implement function call")
end

function get_name(alg::AbstractAlgorithm)
    error("Subtypes of AbstractAlgorithm must implement get_name")
end

struct BoundAlgorithm{T <: AbstractAlgorithm}
    alg::T
    event_number::Int
end

NVTX.@annotate get_name(algorithm) color=nvtx_color[mod1(algorithm.event_number, 32)] payload=algorithm.event_number function (algorithm::BoundAlgorithm)(data...;
                                                                                                                                                          coefficients::Union{Vector{Float64},
                                                                                                                                                                              Missing})
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
        algo_vertices = MetaGraphs.filter_vertices(graph, :type, "Algorithm")
        sorted_vertices = MetaGraphs.topological_sort(graph)
        sorted_algo_vertices = intersect(sorted_vertices, algo_vertices)
        new(graph, sorted_algo_vertices)
    end
end

function get_algorithm(data_flow::DataFlowGraph, index::Int)::AbstractAlgorithm
    return get_prop(data_flow.graph, index, :algorithm)
end

# removed Dagger.DTask
struct Event
    data_flow::DataFlowGraph
    store::Dict{Int, Any}
    event_number::Int
    function Event(data_flow::DataFlowGraph, event_number::Int = 0)
        new(data_flow, Dict{Int, Any}(), event_number)
    end
end

# removed Dagger.DTask
function put_result!(event::Event, index::Int, result::Any)
    return event.store[index] = result
end

function get_result(event::Event, index::Int)::Any
    return event.store[index]
end

function get_results(event::Event, vertices::Vector{Int})
    return get_result.(Ref(event), vertices)
end

function notify_graph_finalization(notifications::Channel{Int}, graph_id::Int, # RemoteChannel to Channel{Int}
                                   terminating_results...)
    @info "Graph $graph_id: all tasks in the graph finished!"
    put!(notifications, graph_id)
    @info "Graph $graph_id: notified!"
end

function is_terminating_alg(graph::AbstractGraph, vertex_id::Int)
    successor_dataobjects = outneighbors(graph, vertex_id)
    is_terminating(vertex) = isempty(outneighbors(graph, vertex))
    all(is_terminating, successor_dataobjects)
end

#---------------- Removing Dagger from Scheduling ----------------#

# modified schedule_algorithm for threading
function schedule_algorithm(event::Event, vertex_id::Int,
                            coefficients::Union{Any, Nothing},
                            done_channel::Channel{Tuple{Int, Any}})
    # get the incoming vertices for this algorithm
    incoming_vertices = inneighbors(event.data_flow.graph, vertex_id)

    # debug: Check if all incoming data is available
    for v in incoming_vertices
        if !haskey(event.store, v)
            @error "Missing data for vertex $v required by algorithm vertex $vertex_id"
            @error "Available vertices in store: $(keys(event.store))"
            @error "Algorithm vertices: $(event.data_flow.algorithm_indices)"
        end
    end

    incoming_data = get_results(event, incoming_vertices)
    algorithm = BoundAlgorithm(get_algorithm(event.data_flow, vertex_id),
                               event.event_number)

    # Use the provided coefficients or missing
    coeff_to_use = isnothing(coefficients) ? missing : coefficients

    # Spawn the task on a thread
    Threads.@spawn begin
        alg_name = get_name(algorithm)
        @debug "Executing $alg_name (vertex $vertex_id) on thread $(threadid())"

        result = algorithm(incoming_data...; coefficients = coeff_to_use)
        put!(done_channel, (vertex_id, result))
    end
end

function schedule_graph!(event::Event, coefficients::Union{Any, Nothing})
    graph = event.data_flow.graph
    all_vertices = vertices(graph)
    algo_vertices = event.data_flow.algorithm_indices

    @debug "Running with $(Threads.nthreads()) threads"

    # data vertices (non algo)
    data_vertices = setdiff(all_vertices, algo_vertices)

    # Initialize all data vertices
    for v in data_vertices
        put_result!(event, v, Float64[])
    end

    # dependency tracking
    algorithm_dependencies = Dict{Int, Set{Int}}()
    parent_count = Dict{Int, Int}()
    children = Dict{Int, Vector{Int}}()

    for v in algo_vertices
        deps = Set{Int}()

        # find all data vertices this algorithm needs
        data_inputs = filter(d -> d in data_vertices, inneighbors(graph, v))

        # for each data input find which algorithm produces it
        for data_v in data_inputs
            # find the algorithm that produces this data
            producers = filter(p -> p in algo_vertices, inneighbors(graph, data_v))
            for producer in producers
                push!(deps, producer)
            end
        end

        algorithm_dependencies[v] = deps
        parent_count[v] = length(deps)
        children[v] = Int[]
    end

    # build children relationships
    for v in algo_vertices
        for dep in algorithm_dependencies[v]
            push!(children[dep], v)
        end
    end

    # channel to receive completion notifications
    done_channel = Channel{Tuple{Int, Any}}(length(algo_vertices))

    # track active tasks and terminating results
    active = 0
    terminating_results = []

    # spawning a vertex
    function spawn_vertex(vertex_id)
        alg_name = get_name(get_algorithm(event.data_flow, vertex_id))
        @debug "Spawning algorithm $alg_name (vertex $vertex_id) on thread $(threadid())"

        schedule_algorithm(event, vertex_id, coefficients, done_channel)
    end

    # spawn all vertices without parents
    for v in algo_vertices
        if parent_count[v] == 0
            spawn_vertex(v)
            active += 1
        end
    end

    while active > 0
        (vertex_id, result) = take!(done_channel)
        active -= 1

        alg_name = get_name(get_algorithm(event.data_flow, vertex_id))
        @debug "Completed algorithm $alg_name (vertex $vertex_id) on thread $(threadid())"

        # Store the result in the algorithm vertex
        put_result!(event, vertex_id, result)

        # Also store in all connected data vertices (algorithm outputs)
        for data_vertex in outneighbors(graph, vertex_id)
            if !(data_vertex in algo_vertices)
                put_result!(event, data_vertex, result)
            end
        end

        # Track terminating algorithms
        if is_terminating_alg(graph, vertex_id)
            push!(terminating_results, result)
        end

        # Check algorithm children to see if they're ready
        for child in children[vertex_id]
            parent_count[child] -= 1
            if parent_count[child] == 0
                spawn_vertex(child)
                active += 1
            end
        end
    end

    close(done_channel)

    return terminating_results
end
#----------------------------------------------#

# removed Dagger.Shard by just using Vector
function calibrate_crunch(min::Int = 1000, max::Int = 200_000;
                          fast::Bool = false)::Union{Vector{Float64}, Nothing}
    return fast ? nothing : calculate_coefficients(min, max)
end

function run_pipeline(data_flow::DataFlowGraph;
                      event_count::Int,
                      max_concurrent::Int,
                      crunch_coefficients::Union{Vector{Float64}, Nothing} = nothing)

    # Create semaphore with max_concurrent permits
    semaphore = Base.Semaphore(max_concurrent)

    # Store all tasks to wait for completion
    all_tasks = Task[]

    # run graph in a thread with semaphore control
    function run_graph_with_semaphore(idx::Int)
        # Acquire semaphore (blocks if all permits taken)
        Base.acquire(semaphore)

        try
            @info dispatch_begin_msg(idx)
            event = Event(data_flow, idx)
            terminating_results = schedule_graph!(event, crunch_coefficients)
            @info dispatch_end_msg(idx)
            return terminating_results
        finally
            # Always release semaphore, even if task fails
            Base.release(semaphore)
        end
    end

    # Launch ALL events immediately - semaphore controls concurrency
    for idx in 1:event_count
        task = Threads.@spawn run_graph_with_semaphore(idx)
        push!(all_tasks, task)
    end

    # Wait for all tasks to complete
    for task in all_tasks
        wait(task)
    end
end
