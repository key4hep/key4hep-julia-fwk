using Colors
using DaggerWebDash
using Distributed
using GraphViz

addprocs(10)

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

    function mock_func()
        sleep(1)
        return
    end

    function print_func(x...)
        sleep(x[1])
        println("Finished")
        return length(x)
    end
end

function task_setup() 
    a = Dagger.delayed(taskA)()
    b = Dagger.delayed(taskB)(a)
    c = Dagger.delayed(taskC)(a)
    d = Dagger.delayed(taskD)(b, c)
    e = Dagger.delayed(taskE)(b, c, d)

    return e
end

function graph_viz_setup_logs() 
    ctx = Dagger.Sch.eager_context()
    log = TimespanLogging.LocalEventLog()
    ctx.log_sink = log
    ctx.log_file = "./graphs_scheduling/results/logs/out.svg"

    return
end

function get_viz_logs() 
    ctx = Dagger.Sch.eager_context()
    logs = TimespanLogging.get_logs!(ctx.log_sink)
    # plan = Dagger.show_plan(logs)

    return 
end

function do_DAGs_task(graphs_number, nodes_in_graph=3)
    # Execute the task graph
    parallel_graphs_results = []
    lock1 = ReentrantLock()
    
    for j in 1:graphs_number
        graph_result = []
        for i in 1:nodes_in_graph
            if (i > 1)
                result = Dagger.@spawn print_func(graph_result...)
            else
                result = Dagger.@spawn print_func(i)
            end
            
            lock(lock1)
            push!(graph_result, result)
            unlock(lock1)
        end
        push!(parallel_graphs_results, graph_result)
    end

    for (i, graph) in enumerate(parallel_graphs_results)
        println("Graph $i")
        for res in graph
            println(fetch(res))
        end
    end

    # res = Dagger.delayed(finish_func)(parallel_graphs...)
    res = Dagger.delayed(mock_func)()
    ctx = Dagger.Sch.eager_context()
    a = collect(ctx, res)
end


# configure_webdash_multievent()
# sleep(10)

graph_viz_setup_logs()
do_DAGs_task(5)
get_viz_logs()
