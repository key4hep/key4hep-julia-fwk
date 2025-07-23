using Test

if abspath(PROGRAM_FILE) == @__FILE__
    import Pkg
    try
        Pkg.test(; test_args = ARGS)
        exit(0)
    catch
        exit(1)
    end
end

@info("Execution environment details",
      julia_version=VERSION,
      n_threads=Threads.nthreads(),
      test_args=repr(ARGS))

@testset verbose=true "FrameworkDemo.jl" begin
    if "all" ∈ ARGS
        include("Aqua.jl")
    end
    include("parsing.jl")
    include("cpu_crunching.jl")
    include("scheduling.jl")
    include("demo_workflows.jl")
    include("visualization.jl")
end
