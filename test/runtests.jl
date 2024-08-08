using Distributed
using Test

@info("Execution environment details",
      julia_version=VERSION,
      n_workers=Distributed.nworkers(),
      n_procs=Distributed.nprocs(),
      n_threads=Threads.nthreads(),
      test_args=repr(ARGS))

@testset verbose=true "FrameworkDemo.jl" begin
    include("Aqua.jl")
    include("parsing.jl")
    include("scheduling.jl")
    include("demo_workflows.jl")
end
