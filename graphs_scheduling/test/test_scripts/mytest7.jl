using Colors
using DaggerWebDash
using Distributed
using GraphViz

addprocs(1)

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
    Dagger.enable_logging!()
    return
end

function get_viz_logs() 
    logs = Dagger.fetch_logs!()
    print(logs)
    println("\n")
    println("END OF LOGS")
    Dagger.render_logs(logs, :graphviz)
    Dagger.disable_logging!()
    return 
end

function do_DAGs_task(graphs_number)
    # Execute the task graph
    parallel_graphs = []
    lock1 = ReentrantLock()
    
    println(graphs_number)
    for i in 1:graphs_number
        println(i)
        if (i > 1)
            result = Dagger.@spawn print_func(parallel_graphs...)
        else
            result = Dagger.@spawn print_func(i)
        end
        
        lock(lock1)
        push!(parallel_graphs, result)
        unlock(lock1)
    end

    for res in parallel_graphs
        println(fetch(res))
    end

    # res = Dagger.delayed(finish_func)(parallel_graphs...)
    res = Dagger.delayed(print_func)(0, [])
    ctx = Dagger.Sch.eager_context()
    a = collect(ctx, res)
end


# configure_webdash_multievent()
# sleep(10)

graph_viz_setup_logs()
do_DAGs_task(5)
get_viz_logs()
