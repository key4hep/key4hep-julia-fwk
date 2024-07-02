module FrameworkDemo

include("logging.jl")
include("parsing.jl")
include("scheduling.jl")
include("visualization.jl")

include("TrackedTaskDAG.jl")

# to be removed 
include("ModGraphVizSimple.jl")

end # FrameworkDemo