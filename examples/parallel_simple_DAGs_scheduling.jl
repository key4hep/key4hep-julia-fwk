using Distributed

# addprocs(4) # 4 is the arbitrary number

include("tasks/oldAPI_example_tasks.jl")


# Example function to launch multiple DAGs execution
function do_DAGs_task(graphs_number, nodes_in_graph=3)
    parallel_graphs_results = []
    
    # For the <graphs_number> of graphs
    for j in 1:graphs_number
        # Schedule new simple DAG
        graph_result = []
        for i in 1:nodes_in_graph
            if (i > 1)
                result = Dagger.@spawn print_func(graph_result...)
            else
                result = Dagger.@spawn print_func(i)
            end
            
            push!(graph_result, result)
        end

        # Store reference to the result
        push!(parallel_graphs_results, graph_result)
    end

    # Fetch and print results of each graph
    for (i, graph) in enumerate(parallel_graphs_results)
        println("Graph $i")
        for res in graph
            println(fetch(res))
        end
    end
end

do_DAGs_task(4, 3)

alive_workers = workers()
println("Workers list: ", alive_workers)
rmprocs(alive_workers) # TODO: fix rmprocs error
# alive_workers |> rmprocs

# println("Exiting Julia...")
exit()