#!/usr/bin/env julia

using key4hep_julia_fwk

function main()
    G = key4hep_julia_fwk.parse_graphml(["./data/sequencer_demo/df_sequencer_demo.graphml"])
    G_copy = deepcopy(G)
    key4hep_julia_fwk.show_graph(G_copy)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end