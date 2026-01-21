using FrameworkDemo
using Test
using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(FrameworkDemo)
end
