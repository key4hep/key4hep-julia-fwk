#!/usr/bin/env julia

using FrameworkDemo

function main()
    G = FrameworkDemo.parse_graphml("./data/demo/sequencer/df.graphml")
    G_copy = deepcopy(G)
    FrameworkDemo.show_graph(G_copy)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end