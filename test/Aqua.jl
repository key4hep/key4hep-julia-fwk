using Aqua
using FrameworkDemo

@testset "Aqua.jl" begin
    Aqua.test_all(FrameworkDemo;
                  ambiguities = false,
                  stale_deps = (;
                                ignore = [:ArgParse, # bin/
                                    :BenchmarkTools, # benchmarks.jl
                                    :Plots, # benchmarks.jl, Dagger ext
                                    :DataFrames]))
end
