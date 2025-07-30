using MetaGraphs

struct MockupAlgorithm <: AbstractAlgorithm
    name::String
    runtime::Float64
    output_length::UInt
    id::Int
    function MockupAlgorithm(data_flow::DataFlowGraph, vertex_id::Int)
        graph = data_flow.graph
        name = get_prop(graph, vertex_id, :node_id)
        runtime = get_prop(graph, vertex_id, :runtime_average_s)
        outputs = length(outneighbors(graph, vertex_id))
        new(name, runtime, outputs, vertex_id)
    end
end

const mockup_alg_default_runtime_s = 0

function (alg::MockupAlgorithm)(args...; event_number::Int,
                                coefficients::Union{Vector{Float64}, Nothing})
    # @info "Executing $(alg.name) event $event_number"
    if coefficients isa Vector{Float64}
        crunch_for_seconds(alg.runtime, coefficients)
    end

    return fill(alg.id, alg.output_length)
end

function get_name(alg::MockupAlgorithm)
    return alg.name
end

function mockup_dataflow(graph::MetaDiGraph)::DataFlowGraph
    data_flow = DataFlowGraph(graph)
    for i in data_flow.algorithm_indices
        alg = MockupAlgorithm(data_flow, i)
        set_prop!(data_flow.graph, i, :algorithm, alg)
    end
    return data_flow
end
