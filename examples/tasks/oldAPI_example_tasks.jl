using Distributed

@everywhere begin
    using Dagger
    using TimespanLogging
    using DaggerWebDash

    function print_arg_sleep(x)
        println("In print_arg_sleep, arg: " * string(x))
        sleep(x)
        return
    end

    function taskA()
        println("In taskA, worker id: " * string(myid()))

        for _ in 1:1
            sleep(1)
            println("Slept for 1 second in taskA")
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
        println("Finished in worker id: " * string(myid()))
        return length(x)
    end

    function task_setup() 
        a = Dagger.delayed(taskA)()
        b = Dagger.delayed(taskB)(a)
        c = Dagger.delayed(taskC)(a)
        d = Dagger.delayed(taskD)(b, c)
        e = Dagger.delayed(taskE)(b, c, d)
    
        return e
    end
end