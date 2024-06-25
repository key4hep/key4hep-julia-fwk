using Colors
using DaggerWebDash
using Distributed

addprocs(3)

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

    # function print_func(x)
    #     x = 1/0
    #     sleep(x)
    #     println("Finished")
    # end

    # function dispatcher(graphs, graphs_num)
    #     ids = []
    #     h = Dagger.sch_handle()
    #     for n in 1:graphs_num
    #         id = Dagger.Sch.add_thunk!(print_func, h, nothing=>n)
    #         push!(ids, id)
    #     end 
    #     for id in ids
    #         fetch(h, id)
    #     end
    # end
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
    ctx.log_file = "outt.svg"

    return
end

function get_viz_logs() 
    ctx = Dagger.Sch.eager_context()
    logs = TimespanLogging.get_logs!(ctx.log_sink)
    # plan = Dagger.show_plan(logs)

    return 
end

function do_DAGs_task(graphs_number)
    # Execute the task graph
    results = []
    
    @sync for i in 1:graphs_number
        t = Dagger.@spawn begin
            result = task_setup()
            println("hello")
            return collect(result)
        end

        push!(results, t)
    end

    for r in results
        println(fetch(r))
    end

    # res = Dagger.delayed(finish_func)(parallel_graphs...)
    # res = Dagger.delayed(dispatcher)([], graphs_number)
    # ctx = Dagger.Sch.eager_context()
    # a = collect(ctx, res)
end

graph_viz_setup_logs()

# configure_webdash_multievent()

do_DAGs_task(5)

plan = get_viz_logs()
# println(typeof(plan))
# println(plan)
