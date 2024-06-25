using Colors
using DaggerWebDash
using Distributed

addprocs(4)

@everywhere begin
    using Dagger
    using TimespanLogging
    using DaggerWebDash

    function taskA()
        println("In taskA, worker id: " * string(myid()))

        for _ in 1:1
            sleep(1)
            println("Slept for a 2 seconds in taskA")
        end
        
        return "Executed A"
    end
    
    function taskB(x)
        println("In taskB, worker id: " * string(myid()))

        for _ in 1:1
            sleep(2)
            println("Slept for a 2 seconds in taskB")
        end
        
        return "Executed B after " * x
    end
    
    function taskC(x)
        println("In taskC, worker id: " * string(myid()))

        for _ in 1:1
            sleep(1)
            println("Slept for a 2 seconds in taskC")
        end
        
        return "Executed C after " * x
    end
    
    function taskD(x, y)
        println("In taskD, worker id: " * string(myid()))

        for _ in 1:1
            sleep(1)
            println("Slept for a 2 seconds in taskD")
        end
        
        return "Executed D after " * x * " and " * y
    end

    function taskE(x, y, z)
        println("In taskE, worker id: " * string(myid()))

        for _ in 1:1
            sleep(1)
            println("Slept for a 2 seconds in taskE")
        end
        
        return "Executed E after " * x * " and " * y * " and " * z
    end

    function task_setup() 
        a = Dagger.delayed(taskA)()
        b = Dagger.delayed(taskB)(a)
        c = Dagger.delayed(taskC)(a)
        d = Dagger.delayed(taskD)(b, c)
        e = Dagger.delayed(taskE)(b, c, d)
    
        return e
    end

    function finish_func(arg)
        println("Sleep for", arg)
        sleep(arg)
        println("Finished")
        return arg
    end

    # function add_graphs(graphs)
    #     h = Dagger.sch_handle()
    #     ids = []
    #     for graph in graphs
    #         print("test")
    #         # id = Dagger.Sch.add_thunk!(graph, h)
    #         print("test")
    #         # push!(ids, id)
    #     end 

    #     return ids
    # end

    function dispatcher(graphs_number)
        println("Dispatcher is alive!")
        # Execute the task graph
        parallel_graphs = []
        lock1 = ReentrantLock()

        @sync for i in 1:graphs_number
            Threads.@spawn begin
                result = task_setup()
                lock(lock1)
                push!(parallel_graphs, result)
                unlock(lock1)
            end
        end

        ctx = Dagger.Sch.eager_context()
        # h = Dagger.sch_handle()
        # ids = []
        # for graph in parallel_graphs
        #     t = Dagger.delayed(finish_func)(graph)
        #     # id = Dagger.Sch.add_thunk!(compute, h, ctx, t)
        #     id = Dagger.Sch.exec!(Dagger.Sch._add_thunk!, h, compute, [ctx, t], nothing, nothing, nothing)
        #     push!(ids, id)
        # end 
        @sync for (i, graph) in enumerate(parallel_graphs)
            @async begin
                ctx = Dagger.Context()
                log = TimespanLogging.LocalEventLog()
                ctx.log_sink = log
                ctx.log_file = "out" * string(i) * ".svg"

                println(compute(ctx, graph))
            end
        end
        print("Dispatcher finished!")

        # for id in ids
        #     println(fetch(h, id))
        # end
    end
end

function graph_viz_setup_logs() 
    ctx = Dagger.Sch.eager_context()
    log = TimespanLogging.LocalEventLog()
    ctx.log_sink = log
    ctx.log_file = "out.svg"

    return
end

function get_viz_logs() 
    ctx = Dagger.Sch.eager_context()
    logs = TimespanLogging.get_logs!(ctx.log_sink)
    # plan = Dagger.show_plan(logs)

    # return plan
end

function do_DAGs_task(graphs_number)
    ctx = Dagger.Sch.eager_context()
    results = []
    a = Dagger.@spawn dispatcher(graphs_number)
    fetch(a)
    # for id in ids
    #     println(compute(ctx, id))
    # end
    println("finish")

    # println("TEST")
    # @sync for id in ids
    #     Threads.@spawn wait(h, id)
    # end

    # for res in results
    #     println("Result: ", res)
    # end
    # # println("test")
    # return result
end

# function collect_DAGs(promises)
#     for result in promises
#         println("Next:")
#         println(collect(result))
#     end
# end

graph_viz_setup_logs()

# configure_webdash_multievent()

# graphs = []
# @sync for i in 1:3
#     Threads.@spawn push!(graphs, do_DAG())
# end
# collect_DAGs(graphs)

do_DAGs_task(3)

plan = get_viz_logs()
# println(typeof(plan))
# println(plan)
