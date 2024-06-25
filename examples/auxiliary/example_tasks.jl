using Distributed

@everywhere begin
    import Dagger

    function taskA(time_to_sleep, id, x...)
        println("In taskA!")
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("From taskA, with id: $id, arg $i: " * string(val))
        end
        
        return "Result of task A with id: $id"
    end
    
    function taskB(time_to_sleep, id, x...)
        println("In taskB!")
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("From taskB, with id: $id, arg $i: " * string(val))
        end

        return "Result of task B with id: $id"
    end
    
    function taskC(time_to_sleep, id, x...)
        println("In taskC!")
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("From taskC, with id: $id, arg $i: " * string(val))
        end

        return "Result of task C with id: $id"
    end
    
    function taskD(time_to_sleep, id, x...)
        println("In taskD!")
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("From taskD, with id: $id, arg $i: " * string(val))
        end

        return "Result of task D with id: $id"
    end

    function taskE(time_to_sleep, id, x...)
        println("In taskE!")
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("From taskE, with id: $id, arg $i: " * string(val))
        end

        return "Result of task E with id: $id"
    end

    function taskF(time_to_sleep, id, x...)
        println("In taskF!")
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("From taskF, with id: $id, arg $i: " * string(val))
        end

        return "Result of task F with id: $id"
    end

    function oldAPI_graph_setup(time_to_sleep) 
        a = Dagger.delayed(taskA)(time_to_sleep, 1)
        b = Dagger.delayed(taskB)(time_to_sleep, 2, a)
        c = Dagger.delayed(taskC)(time_to_sleep, 3, a, b)
        d = Dagger.delayed(taskD)(time_to_sleep, 4, a, b, c)
        e = Dagger.delayed(taskE)(time_to_sleep, 5, a)
        f = Dagger.delayed(taskF)(time_to_sleep, 6, a, b, c, d, e)
    
        return f
    end

    function modernAPI_graph_setup(time_to_sleep) 
        a = Dagger.@spawn (taskA)(time_to_sleep, 1)
        b = Dagger.@spawn (taskB)(time_to_sleep, 2, a)
        c = Dagger.@spawn (taskC)(time_to_sleep, 3, a, b)
        d = Dagger.@spawn (taskD)(time_to_sleep, 4, a, b, c)
        e = Dagger.@spawn (taskE)(time_to_sleep, 5, a)
        f = Dagger.@spawn (taskF)(time_to_sleep, 6, a, b, c, d, e)
    
        return f
    end
end
