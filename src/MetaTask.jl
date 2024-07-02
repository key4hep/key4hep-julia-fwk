import Dagger

abstract type AbstractMetaTask 
end

struct MetaTask <: AbstractMetaTask
    uuid::String
    name::String
    task::Dagger.DTask
end

function get_uuid(meta_task::AbstractMetaTask)
    return meta_task.uuid
end

function get_name(meta_task::AbstractMetaTask)
    return "tracked_" * meta_task.name
end

function wait(meta_task::AbstractMetaTask)
    wait(meta_task.task)
end