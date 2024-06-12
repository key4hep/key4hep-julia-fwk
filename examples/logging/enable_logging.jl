include("../auxiliary/modernAPI_tasks.jl")

# Enable logging is absent in Dagger 0.18.8
# Dagger.enable_logging!()
t = task_setup()
println(collect(t))
