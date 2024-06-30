using FrameworkDemo
using Dagger
using Graphs
using MetaGraphs

function get_alg_timeline(logs::Dict)
    timeline = Dict{Int,Any}()
    Dagger.logs_event_pairs(logs) do w, start_idx, finish_idx
        category = logs[w][:core][start_idx].category
        if category == :compute
            tid = logs[w][:id][start_idx].thunk_id
            t_start = logs[w][:core][start_idx].timestamp
            t_stop = logs[w][:core][finish_idx].timestamp
            timeline[tid] = (start=t_start, stop=t_stop)
        end
    end
    return timeline
end

@testset verbose = true "Scheduling" begin
    graph = FrameworkDemo.parse_graphml(["../data/datadeps_demo/df.graphml"])
    algorithms_count = 7
    set_indexing_prop!(graph, :node_id)

    Dagger.enable_logging!(timeline=true,
        tasknames=true,
        taskdeps=true,
        taskargs=true,
        taskargmoves=true,
    )
    _ = Dagger.fetch_logs!() # flush logs

    FrameworkDemo.schedule_graph!(graph, "", 0)
    for v in vertices(graph)
        wait(get_prop(graph, v, :res_data))
    end
    logs = Dagger.fetch_logs!()
    @test !isnothing(logs)

    task_to_tid = lock(Dagger.Sch.EAGER_ID_MAP) do id_map
        return deepcopy(id_map)
    end

    @testset "Timeline" begin
        timeline = get_alg_timeline(logs)
        @test count(timeline) == algorithms_count broken = true

        function get_time(node_id)
            task = get_prop(graph, graph[node_id, :node_id], :res_data)
            tid = task_to_tid[task.uid]
            return timeline[tid]
        end

        @test get_time("ProducerA").stop < get_time("TransformerAB").start
        @test get_time("ProducerBC").stop < get_time("TransformerAB").start
        @test get_time("ProducerBC").stop < get_time("ConsumerBC").start
        @test get_time("ProducerBC").stop < get_time("TransformerC").start
        @test get_time("ProducerBC").stop < get_time("ConsumerCD").start
        @test get_time("TransformerAB").stop < get_time("ConsumerE").start
        @test get_time("TransformerAB").stop < get_time("ConsumerCD").start
    end
end