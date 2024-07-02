import UUIDs
import MetaGraphs
import Dagger
import Base.repr

include("TaskDAG.jl")

mutable struct TrackedTaskDAG <: AbstractMetaTask
    uuid::String
    state::TaskDAGState
    task_dag::TaskDAG
    notify_task::Union{Dagger.DTask, Nothing}

    function TrackedTaskDAG(name::String, dag::MetaGraphs.MetaDiGraph)
        task_dag = TaskDAG(name, dag)
        new(string(UUIDs.uuid4()), ready, task_dag, nothing)
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

# Default notify function
function task_DAG_finalization(tracked_task_dag::TrackedTaskDAG, promises...)
    println("Graph: $(get_name(tracked_task_dag)), entered notify, graph_id: $(get_uuid(tracked_task_dag)) !")
end

function start_DAG(tracked_task_dag::TrackedTaskDAG)
    tracked_task_dag.state = on_schedule
    start_DAG(tracked_task_dag.task_dag)
    tracked_task_dag.notify_task = Dagger.@spawn task_DAG_finalization(tracked_task_dag, get_leafs_promises(tracked_task_dag.task_dag)...)
    tracked_task_dag.state = running
end

function Base.wait(t::TrackedTaskDAG)
    if t.state in (on_schedule, running, completed)
        Dagger.wait(t.notify_task)
        t.state = completed
        t.task_dag.state = completed
    else 
        throw(ConcurrencyViolationError("Cannot `wait` on an unlaunched `TrackedTaskDAG`"))
    end
    
end

# TODO: return something more meaningful (for instance, dictionary of results for the specified vertices)
function Base.fetch(t::TrackedTaskDAG)
    res = fetch(t.notify_task)
    if (t.state !== completed)
        t.state = completed
    end
    return res
end
