using MetaGraphs

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

function get_name(alg::MockupAlgorithm)
    return alg.name
end

function mockup_dataflow(graph::MetaDiGraph)::DataFlowGraph
    data_flow = DataFlowGraph(graph)
    for i in data_flow.algorithm_indices
        alg = MockupAlgorithm(data_flow.graph, i)
        set_prop!(data_flow.graph, i, :algorithm, alg)
    end
    return data_flow
end
