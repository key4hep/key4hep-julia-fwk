using FrameworkDemo
using Test
using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(FrameworkDemo;
                  ambiguities = false,
                  stale_deps = (; ignore = [:ArgParse]),# bin/
                  persistent_tasks = (; broken = true)) # GraphMLReader [8e6830a9] has no known versions!
end
