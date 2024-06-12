# This example was taken from https://juliaparallel.org/Dagger.jl/v0.18/processors/

using Distributed

ps1 = addprocs(2, exeflags="--project")
@everywhere using Distributed, Dagger

# Dummy task to wait for 0.5 seconds and then return the id of the worker
ts = delayed(vcat)((delayed(i -> (sleep(0.5); myid()))(i) for i in 1:20)...)

ctx = Context()
# Scheduler is blocking, so we need a new task to add workers while it runs
job = @async collect(ctx, ts)

# Lets fire up some new workers
ps2 = addprocs(2, exeflags="--project")
@everywhere ps2 using Distributed, Dagger
# New workers are not available until we do this
addprocs!(ctx, ps2)

# Lets hope the job didn't complete before workers were added :)
@show fetch(job) |> unique

# and cleanup after ourselves...
workers() |> rmprocs