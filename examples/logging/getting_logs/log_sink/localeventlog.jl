include("../../../auxiliary/example_tasks.jl") # here Dagger is imported as well

ctx = Dagger.Sch.eager_context()
ctx.log_sink = Dagger.TimespanLogging.LocalEventLog() # By default, NoOpLog, which does nothing, is set

t = modernAPI_graph_setup(1) # Can also be the old API
fetch(t)

logs = Dagger.TimespanLogging.get_logs!(ctx)
println("\n\nRaw logs:")
println(logs) # <- That should be a Dictionary of the form: {worker_id -> [list of the events on that worker]}
