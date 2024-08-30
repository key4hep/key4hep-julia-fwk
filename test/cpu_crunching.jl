using Test
using FrameworkDemo

@testset "cpu_crunching" begin
    coefficients = FrameworkDemo.calculate_coefficients(10, 100)
    @test !isnothing(coefficients)
    @test all(x -> !ismissing(x) && !isnan(x), coefficients)
    @test any(x -> !iszero(x), coefficients)
end
