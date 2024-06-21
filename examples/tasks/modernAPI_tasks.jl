using Distributed

@everywhere begin
    using Dagger

    function taskA(time_to_sleep, id, x...)
        sleep(time_to_sleep)
        for (i, val) in enumerate(x)
            println("In task$id, arg $i: " * string(val))
        end

        return "Result of task$id"
    end

    function task_setup(time_to_sleep) 
        a = Dagger.@spawn taskA(time_to_sleep, 1)
        b = Dagger.@spawn taskA(time_to_sleep, 2, a)
        c = Dagger.@spawn taskA(time_to_sleep, 3, a, b)
        d = Dagger.@spawn taskA(time_to_sleep, 4, a, b, c)
        e = Dagger.@spawn taskA(time_to_sleep, 5, a, b, c, d)
    
        return e
    end
end