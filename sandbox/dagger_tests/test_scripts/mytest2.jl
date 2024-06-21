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

function configure_webdash_multievent()
    ctx = Dagger.Sch.eager_context()
    ml = Dagger.TimespanLogging.MultiEventLog()

    TimespanLogging = Dagger.TimespanLogging
    ## Add some logging events of interest

    ml[:core] = TimespanLogging.Events.CoreMetrics()
    ml[:id] = TimespanLogging.Events.IDMetrics()
    ml[:timeline] = TimespanLogging.Events.TimelineMetrics()
    # ...

    # (Optional) Enable profile flamegraph generation with ProfileSVG
    ml[:profile] = DaggerWebDash.ProfileMetrics()
    ctx.profile = true

    # Create a LogWindow; necessary for real-time event updates
    lw = TimespanLogging.Events.LogWindow(20*10^9, :core)
    ml.aggregators[:logwindow] = lw

    # Create the D3Renderer server on port 8080
    d3r = DaggerWebDash.D3Renderer(8080)

    ## Add some plots! Rendered top-down in order

    # Show an overview of all generated events as a Gantt chart
    push!(d3r, DaggerWebDash.GanttPlot(:core, :id, :esat, :psat; title="Overview"))

    # Show various numerical events as line plots over time
    push!(d3r, DaggerWebDash.LinePlot(:core, :wsat, "Worker Saturation", "Running Tasks"))
    push!(d3r, DaggerWebDash.LinePlot(:core, :loadavg, "CPU Load Average", "Average Running Threads"))
    push!(d3r, DaggerWebDash.LinePlot(:core, :bytes, "Allocated Bytes", "Bytes"))
    push!(d3r, DaggerWebDash.LinePlot(:core, :mem, "Available Memory", "% Free"))

    # Show a graph rendering of compute tasks and data movement between them
    # Note: Profile events are ignored if absent from the log
    push!(d3r, DaggerWebDash.GraphPlot(:core, :id, :timeline, :profile, "DAG"))

    # TODO: Not yet functional
    #push!(d3r, DaggerWebDash.ProfileViewer(:core, :profile, "Profile Viewer"))
    # Add the D3Renderer as a consumer of special events generated by LogWindow
    push!(lw.creation_handlers, d3r)
    push!(lw.deletion_handlers, d3r)

    # D3Renderer is also an aggregator
    ml.aggregators[:d3r] = d3r

    ctx.log_sink = ml
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
