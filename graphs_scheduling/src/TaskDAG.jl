import UUIDs
import MetaGraphs
import Dagger
import Base.repr

include("MetaTask.jl")
include("../../utilities/functions.jl")

mutable struct TaskDAG <: AbstractMetaTask
    uuid::String
    name::String
    state::Symbol
    dag::MetaGraphs.MetaDiGraph
    leafs_promises::Vector{Dagger.DTask}

    function TaskDAG(name::String, dag::MetaGraphs.MetaDiGraph)
        new(string(UUIDs.uuid4()), name, :ready, dag)
    end
end

function get_uuid(task_dag::TaskDAG)
    return task_dag.uuid
end

function get_name(task_dag::TaskDAG)
    return task_dag.name
end

function get_DAG(task_dag::TaskDAG)
    return task_dag.dag
end

function Base.repr(task_dag::TaskDAG)
    return get_name(task_dag) * ": TaskDAG"
end

function is_ready(task_dag::TaskDAG)
    return task_dag.state == :ready
end

function is_running(task_dag::TaskDAG)
    return task_dag.state == :running
end

function is_done(task_dag::TaskDAG)
    return task_dag.state == :done
end

function start_DAG(task_dag::TaskDAG)
    task_dag.state = :on_schedule

    inc_e_src_map = get_ine_map(task_dag.dag)

    for vertex_id in MetaGraphs.topological_sort(task_dag.dag)
        incoming_data = get_deps_promises(vertex_id, inc_e_src_map, task_dag.dag)
        set_prop!(task_dag.dag, vertex_id, :res_data, Dagger.@spawn AVAILABLE_TRANSFORMS[get_prop(task_dag.dag, vertex_id, :type)](task_dag.name, task_dag.uuid, vertex_id, incoming_data...))
    end

    task_dag.leafs_promises = _get_leafs_promises(task_dag) # assume the graph will not be modified
    task_dag.state = :running
end

function _get_leafs_promises(task_dag::TaskDAG)
    final_vertices = []
    out_e_src_map = get_oute_map(task_dag.dag)

    for vertex_id in MetaGraphs.vertices(task_dag.dag)
        if !haskey(out_e_src_map, vertex_id)
            out_e_src_map[vertex_id] = []
        end
    end

    for vertex_id in keys(out_e_src_map)
        if isempty(out_e_src_map[vertex_id])
            push!(final_vertices, vertex_id)
        end
    end

    return get_vertices_promises(final_vertices, task_dag.dag)
end

function get_leafs_promises(task_dag::TaskDAG)
    if (task_dag.state !== :running && task_dag.state !== :done)
        throw(error("Task DAG was not started yet"))
    end
    return task_dag.leafs_promises
end

function wait(task_dag::TaskDAG)
    if (task_dag.state !== :ready)
        for promise in task_dag.leafs_promises
            wait(promise)
        end
        task_dag.state = :done
    else
        throw(ConcurrencyViolationError("Cannot `wait` on an unlaunched `TaskDAG`"))
    end
end

function fetch(task_dag::TaskDAG, vertex_id::Int)
    fetch(get_prop(task_dag.dag, vertex_id, :res_data))
end