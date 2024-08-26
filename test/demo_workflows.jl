using FrameworkDemo
using Test
using Dagger

function run_demo(name::String, coefficients::Union{Dagger.Shard, Nothing})
    @testset "$name" begin
        println("Running $(name) workflow demo")
        path = joinpath(pkgdir(FrameworkDemo), "data/demo/$(name)/df.graphml")
        graph = FrameworkDemo.parse_graphml(path)
        df = FrameworkDemo.DataFlowGraph(graph)
        event = FrameworkDemo.Event(df)
        @test_nowarn wait.(FrameworkDemo.schedule_graph(event, coefficients))
    end
end

@testset "Demo workflows" begin
    Dagger.disable_logging!()
    is_fast = "no-fast" ∉ ARGS
    coefficients = FrameworkDemo.calibrate_crunch(; fast = is_fast)
    run(name) = run_demo(name, coefficients)
    run("sequential")
    run("sequential_terminated")
    run("parallel")
    run("datadeps")
    run("sequencer")
end
