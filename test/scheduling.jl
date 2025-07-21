using FrameworkDemo
using Test
using Graphs
using MetaGraphs
using Logging

@testset "Scheduling" begin
    path = joinpath(pkgdir(FrameworkDemo), "data/demo/datadeps/df.graphml")
    graph = FrameworkDemo.parse_graphml(path)
    ilength(x) = sum(_ -> 1, x) # no standard length for MetaGraphs.filter_vertices iterator
    algorithms_count = ilength(MetaGraphs.filter_vertices(graph, :type, "Algorithm"))
    set_indexing_prop!(graph, :node_id)
    is_fast = "no-fast" ∉ ARGS
    coefficients = FrameworkDemo.calibrate_crunch(; fast = is_fast)

    @testset "Pipeline" begin
        event_count = 5
        data_flow = FrameworkDemo.mockup_dataflow(graph)

        test_logger = TestLogger()
        with_logger(test_logger) do
            FrameworkDemo.run_pipeline(data_flow;
                                       max_concurrent = 3,
                                       event_count = event_count,
                                       crunch_coefficients = coefficients)
        end
        @testset "Start message" begin
            messages = for i in 1:event_count
                @test any(record -> record.message == FrameworkDemo.dispatch_begin_msg(i),
                          test_logger.logs)
            end
        end
        @testset "Finish message" begin
            messages = for i in 1:event_count
                @test any(record -> record.message == FrameworkDemo.dispatch_end_msg(i),
                          test_logger.logs)
            end
        end
    end
end
