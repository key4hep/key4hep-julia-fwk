using Distributed
using Test

if abspath(PROGRAM_FILE) == @__FILE__
    if !isnothing(Base.find_package("TestEnv"))
        import TestEnv
        TestEnv.activate()
    else
        @error "Install TestEnv package for running manually"
        exit(1)
    end
end

@info("Execution environment details",
      julia_version=VERSION,
      n_workers=Distributed.nworkers(),
      n_procs=Distributed.nprocs(),
      n_threads=Threads.nthreads(),
      test_args=repr(ARGS))

@testset verbose=true "FrameworkDemo.jl" begin
    if "all" ∈ ARGS
        include("Aqua.jl")
    end
    include("parsing.jl")
    include("scheduling.jl")
    include("demo_workflows.jl")
    include("visualization.jl")
end
