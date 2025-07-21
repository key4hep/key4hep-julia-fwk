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

    df = FrameworkDemo.mockup_dataflow(graph)
    event = FrameworkDemo.Event(df)

    test_logger = TestLogger()
    with_logger(test_logger) do
        FrameworkDemo.schedule_graph!(event, coefficients)
    end
    @testset "Timeline" begin
        # store order of appearance in the log by message
        log_position = Dict{String, Int}()
        for (i, record) in enumerate(test_logger.logs)
            # match name from message "Executing $name $event_number" logged by mockup algs
            m = match(r"Executing (\w+)", record.message)
            if m !== nothing
                component = m.captures[1]
                log_position[component] = i
            end
        end

        @test log_position["ProducerA"] < log_position["TransformerAB"]
        @test log_position["ProducerBC"] < log_position["TransformerAB"]
        @test log_position["ProducerBC"] < log_position["ConsumerBC"]
        @test log_position["ProducerBC"] < log_position["TransformerC"]
        @test log_position["ProducerBC"] < log_position["ConsumerCD"]
        @test log_position["TransformerAB"] < log_position["ConsumerE"]
        @test log_position["TransformerAB"] < log_position["ConsumerCD"]
    end

    @testset "Dependencies" begin
        get_id(name) = graph[name, :node_id]
        get_parent(name) = FrameworkDemo.get_result(event, graph[name, :node_id])
        @test get_parent("a") == get_id("ProducerA")
        @test get_parent("b") == get_id("ProducerBC")
        @test get_parent("c") == get_id("ProducerBC")
        @test get_parent("d") == get_id("TransformerAB")
        @test get_parent("e") == get_id("TransformerAB")
        @test get_parent("f") == get_id("TransformerAB")
        @test get_parent("g") == get_id("TransformerC")
    end
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
