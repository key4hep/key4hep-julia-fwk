include("../../auxiliary/example_tasks.jl") # here Dagger is imported as well

Dagger.enable_logging!(tasknames=true, # Here we can choose the consumers to use. Check source code for more.
taskdeps=true,
taskargs=true,
taskargmoves=true,
)

t = modernAPI_graph_setup(1) # Can also be the old API
fetch(t)

logs = Dagger.fetch_logs!()
println("\n\nRaw logs:")
println(logs) # <- That should be a Dictionary of the form: {worker_id -> {consumer_symbol -> [list of the events on that worker after being processed by a consumer corresponding to this symbol]}}