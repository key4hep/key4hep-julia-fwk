using Distributed
addprocs(10)

println("Started processes!")
# Some "expensive" functions that complete at different speeds

@everywhere begin
    using Dagger
    using Distributed
    using Random
    Random.seed!(0)

    crn = [i for i in 1:6, j in 1:10] 
    function f(i)
        println("Starting f")
        sleep(crn[i, 1])
        println("Executed f: ")
        println("Time: ", crn[i, 1])
        println("Process id: ", myid())
        println(myid())
        println("End of f")
        return myid()
    end

    function g(i, j, y)
        println("Starting g")
        sleep(crn[i, j])
        println("Executed g: ")
        println("Time: ", crn[i, j])
        println("Process id: ", myid())
        println(myid())
        println("End of g")
        return myid()
    end
end

function nested_dagger()
    println("Starting nested_dagger")

    f_thunks = Vector{Dagger.EagerThunk}()
    g_thunks = Vector{Dagger.EagerThunk}()

    @sync for i in 1:6
        y = Dagger.@spawn f(i)
        push!(f_thunks, y)
        for j in 1:10
            z = Dagger.@spawn g(i, j, y)
            push!(g_thunks, z)
        end
    end

    for y in f_thunks
        println(Dagger.fetch(y))
    end

    for z in g_thunks
        println(Dagger.fetch(z))
    end
end


println("crn: ", crn)

@time nested_dagger()