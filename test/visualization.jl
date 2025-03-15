using FrameworkDemo
using Test
using Graphs
using MetaGraphs

@testset "Visualization" begin
    @testset "Execution plan" begin
        graph = joinpath(pkgdir(FrameworkDemo), "data/demo/datadeps/df.graphml") |>
                FrameworkDemo.parse_graphml |> FrameworkDemo.mockup_dataflow |>
                FrameworkDemo.get_execution_plan

        @test nv(graph) == 7
        @test ne(graph) == 7
        has_edge(x::String, y::String) = Graphs.has_edge(graph, graph[x, :label],
                                                         graph[y, :label])
        @test has_edge("ProducerA", "TransformerAB")
        @test has_edge("ProducerBC", "TransformerAB")
        @test has_edge("ProducerBC", "ConsumerBC")
        @test has_edge("ProducerBC", "TransformerC")
        @test has_edge("ProducerBC", "ConsumerCD")
        @test has_edge("TransformerAB", "ConsumerE")
        @test has_edge("TransformerAB", "ConsumerCD")
    end

    @testset "Save trace" begin
        @test_throws ArgumentError FrameworkDemo.save_trace(Dict{}(), tempname(),
                                                            :unsupported_format)
    end
end
