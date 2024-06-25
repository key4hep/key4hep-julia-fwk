import UUIDs
import MetaGraphs
import Dagger
import Base.repr

include("TaskDAG.jl")


mutable struct TrackedTaskDAG <: AbstractMetaTask
    uuid::String
    state::Symbol
    task_dag::TaskDAG
    notify_task::Union{Dagger.DTask, Nothing}

    function TrackedTaskDAG(name::String, dag::MetaGraphs.MetaDiGraph)
        task_dag = TaskDAG(name, dag)
        new(string(UUIDs.uuid4()), :ready, task_dag, nothing)
    end
end

function get_uuid(tracked_task_dag::TrackedTaskDAG)
    return tracked_task_dag.uuid
end

function get_name(tracked_task_dag::TrackedTaskDAG)
    return "tracked_" * tracked_task_dag.task_dag.name
end

function get_task_DAG(tracked_task_dag::TrackedTaskDAG)
    return tracked_task_dag.task_dag
end

function Base.repr(task_dag::TrackedTaskDAG)
    return get_name(task_dag) * ": TrackedTaskDAG"
end

function task_DAG_finalization(tracked_task_dag::TrackedTaskDAG, promises...)
    println("Graph: $(get_name(tracked_task_dag)), entered notify, graph_id: $(get_uuid(tracked_task_dag)) !")
end

function start_DAG(tracked_task_dag::TrackedTaskDAG)
    start_DAG(tracked_task_dag.task_dag)
    tracked_task_dag.notify_task = Dagger.@spawn task_DAG_finalization(tracked_task_dag, get_leafs_promises(tracked_task_dag.task_dag)...)
    tracked_task_dag.state = :running
end

function Base.wait(t::TrackedTaskDAG)
    if (t.state !== :ready)
        Dagger.wait(t.notify_task)
        t.state = :done
        t.task_dag.state = :done
    else 
        throw(ConcurrencyViolationError("Cannot `wait` on an unlaunched `TrackedTaskDAG`"))
    end
    
end

function Base.fetch(t::TrackedTaskDAG)
    res = fetch(t.notify_task)
    if (t.state !== :done)
        t.state = :done
    end
    return res
end
