using FrameworkDemo
using Graphs
using MetaGraphs

@testset "Parsing" begin
    path = joinpath(pkgdir(FrameworkDemo), "data/demo/sequencer/df.graphml")
    graph = FrameworkDemo.parse_graphml(path)
    set_indexing_prop!(graph, :original_id)

    # Test the general structure of the graph
    @test nv(graph) == 14
    @test ne(graph) == 13

    # Properties of vertex 0
    id = graph["0", :original_id]
    vertex = graph.vprops[id]
    @test vertex[:type] == "Algorithm"
    @test vertex[:runtime_average_s] ≈ 9.3027e-05
    @test vertex[:node_id] == "ProducerA"

    # Properties of vertex 7
    id = graph["7", :original_id]
    vertex = graph.vprops[id]
    @test vertex[:type] == "DataObject"
    @test vertex[:class] == "AnyDataWrapper<int>"
    @test vertex[:size_average_B] ≈ 8.0
    @test vertex[:node_id] == "A"

    # Test edges
    @test has_edge(graph, graph["0", :original_id], graph["7", :original_id])
    @test has_edge(graph, graph["1", :original_id], graph["8", :original_id])
    @test has_edge(graph, graph["2", :original_id], graph["9", :original_id])
    @test has_edge(graph, graph["3", :original_id], graph["10", :original_id])
    @test has_edge(graph, graph["4", :original_id], graph["11", :original_id])
    @test has_edge(graph, graph["5", :original_id], graph["12", :original_id])
    @test has_edge(graph, graph["6", :original_id], graph["13", :original_id])
    @test has_edge(graph, graph["7", :original_id], graph["1", :original_id])
    @test has_edge(graph, graph["8", :original_id], graph["2", :original_id])
    @test has_edge(graph, graph["8", :original_id], graph["6", :original_id])
    @test has_edge(graph, graph["9", :original_id], graph["3", :original_id])
    @test has_edge(graph, graph["10", :original_id], graph["4", :original_id])
    @test has_edge(graph, graph["11", :original_id], graph["5", :original_id])
end