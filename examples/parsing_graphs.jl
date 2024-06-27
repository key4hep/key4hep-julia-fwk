#!/usr/bin/env julia

using FrameworkDemo

function main()
    G = FrameworkDemo.parse_graphml(["./data/sequencer_demo/df_sequencer_demo.graphml"])
    G_copy = deepcopy(G)
    FrameworkDemo.show_graph(G_copy)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end