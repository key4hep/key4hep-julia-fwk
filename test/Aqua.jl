using Aqua
using FrameworkDemo

@testset "Aqua.jl" begin
    Aqua.test_all(FrameworkDemo;
                  ambiguities = false,)
end
