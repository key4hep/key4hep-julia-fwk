@everywhere begin
    using DaggerWebDash
    using Dagger
    # Algorithms
    function mock_Gaudi_algorithm(id, data...)
        println("Gaudi algorithm for vertex $id !")
        sleep(1)
        println("Previous vertices: $data")
        
        return id
    end

    function dataobject_algorithm(id, data...)
        sleep(0.1)
        return "dataobject"
    end

    function mock_func()
        sleep(1)
        return
    end
end

function schedule_graph(G::MetaDiGraph)
    inc_e_src_map = get_ine_map(G)

    for vertex_id in MetaGraphs.topological_sort(G)
        incoming_data = get_deps_promises(vertex_id, inc_e_src_map, G)
        set_prop!(G, vertex_id, :res_data, Dagger.@spawn AVAILABLE_TRANSFORMS[get_prop(G, vertex_id, :type)](vertex_id, incoming_data...))
    end
end

function flush_logs_to_file()
    # Dagger doesn't write logs into a file without calling collect() - to be fixed (find another way?)
    res = Dagger.delayed(mock_func)()
    ctx = Dagger.Sch.eager_context()
    a = collect(ctx, res)
end


AVAILABLE_TRANSFORMS = Dict{String, Function}("GaudiAlgorithm" => mock_Gaudi_algorithm, "DataObject" => dataobject_algorithm)
