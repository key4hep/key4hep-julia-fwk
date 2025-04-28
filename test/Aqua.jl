using FrameworkDemo
using Test
using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(FrameworkDemo;
                  ambiguities = false,
                  stale_deps = (; ignore = [:ArgParse]),) # bin/
end
