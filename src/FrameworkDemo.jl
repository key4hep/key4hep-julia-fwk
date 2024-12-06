module FrameworkDemo
import Preferences
if Preferences.load_preference("Dagger", "distributed-package") == "DistributedNext"
    using DistributedNext
else
    using Distributed
end
include("logging.jl")
include("parsing.jl")
include("scheduling.jl")
include("visualization.jl")
include("cpu_crunching.jl")
include("mockup.jl")

end # FrameworkDemo
