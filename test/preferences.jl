using Test
using Preferences

@testset "Preferences" begin
    distributed_package = Preferences.load_preference("FrameworkDemo",
                                                      "distributed-package")
    @test distributed_package ∈ ("Distributed", "DistributedNext")
    @test Preferences.load_preference("Dagger", "distributed-package") ==
          distributed_package
    @test Preferences.load_preference("MemPool", "distributed-package") ==
          distributed_package
    @test Preferences.load_preference("TimespanLogging", "distributed-package") ==
          distributed_package
end
