using FrameworkDemo
using Test
using Logging

function run_demo(name::String, coefficients::Union{Vector{Float64}, Nothing})
    @testset "$name" begin
        println("Running $(name) workflow demo")
        path = joinpath(pkgdir(FrameworkDemo), "data/demo/$(name)/df.graphml")
        graph = FrameworkDemo.parse_graphml(path)
        df = FrameworkDemo.mockup_dataflow(graph)
        event = FrameworkDemo.Event(df)
        @test_logs min_level=Logging.Warn FrameworkDemo.schedule_graph!(event,
                                                                        coefficients)
    end
end

@testset "Demo workflows" begin
    #FrameworkDemo.disable_tracing!()
    is_fast = "no-fast" ∉ ARGS
    coefficients = FrameworkDemo.calibrate_crunch(; fast = is_fast)
    run(name) = run_demo(name, coefficients)
    run("sequential")
    run("sequential_terminated")
    run("parallel")
    run("datadeps")
    run("sequencer")
end
