###############################################################################
# The code below is essentially a fixed version of the one here: https://github.com/zhangliye/GraphMLReader.jl

###############################################################################
# some of the code is based on GraphML.jl

function str2value(t, v)
    if t=="string"
        return string(v)
    elseif t=="double" || t=="long"
        return parse(Float64, string(v))
    elseif t=="int"
        return parse(Int, string(v))
    else
        error( "Type error: type not found. " * t )
    end
end

""" 

extract the attribtes of current node at stream of `reader`, return the dict of {``:att_name`: `real value`}
"""
function get_attr(reader, node_attr_t)
    node_cur = expandtree(reader)
    attr = []
    for el in eachelement(node_cur)
        if el.name == "data"
            key = el["key"]
            v = nodecontent(el)
            # Get the content within an element.
            attr_t = node_attr_t[key][1]
            attr_name = node_attr_t[key][2]
            v_typed = str2value(attr_t, v)
            push!( attr, Symbol(attr_name)=>v_typed )
        end
    end
    return Dict{Symbol, Any}(attr)
end

function _graphml_read_one_graph(reader::EzXML.StreamReader, isdirected::Bool, node_attr_t, edge_attr_t)
    node_attr = Dict{Int, Any}()   # id: {name1:value, ...}
    edge_attr = Dict{Tuple{Int,Int}, Any}()   # id: {name1:value, ...}
    nodes = Dict{String,Int}()

    xedges = Vector{Graphs.SimpleDiGraphEdge}()
    nodeid = 1
    for typ in reader
        if typ == EzXML.READER_ELEMENT
            elname = EzXML.nodename(reader)
            if elname == "node"
                nodes[reader["id"]] = nodeid
                att = get_attr(reader, node_attr_t)
                att[ :original_id ] = reader["id"]    # record the original id 
                node_attr[nodeid] = att
                nodeid += 1
                
            elseif elname == "edge"
                src = reader["source"]
                tar = reader["target"]
                push!(xedges, Graphs.SimpleDiGraphEdge(nodes[src], nodes[tar]))

                att = get_attr(reader, edge_attr_t)
                if length(att) > 0
                    edge_attr[(nodes[src], nodes[tar])] = att
                end
            else
                @warn "Skipping unknown node '$(elname)' - further warnings will be suppressed" maxlog=1 _id=:unknode
            end
        end
    end

    g = (isdirected ? MetaGraphs.MetaDiGraph : MetaGraphs.MetaGraph)(length(nodes))
    for (id, att) in node_attr
        set_props!(g, id, att)
    end

    for edge in xedges
        Graphs.add_edge!(g.graph, edge)
    end
    for (k, att) in edge_attr
        set_props!(g, k[1], k[2], att)
    end
    return g
end

""" loadgraphml(file::String, gname::String)

Read graphxml from full path `file`, set graph name in xml `<graph id="G">/`, if no `id` property is 
not found, set `gname` to empty string. 
Retun: the MetaGraph or MetaDiGraph object depending on <graph edgedefault="undirected">;
        vertex attributes - :original_id from xml file
        edge attributes - :weight will be used for shortest path calculation
"""
function loadgraphml(file::String, gname::String="")
    node_attr_t = Dict{String, Tuple{String, String}}()  #id: (type, name)
    edge_attr_t = Dict{String, Tuple{String, String}}()  #id: (type, name)

    reader = EzXML.StreamReader( open(file) )
    for typ in reader
        if typ == EzXML.READER_ELEMENT
            elname = EzXML.nodename(reader)
            if elname == "key"
                attr_name = reader["attr.name"]
                attr_type = reader["attr.type"]
                attr_for = reader["for"]
                attr_id = reader["id"]
                if attr_for == "node"
                    node_attr_t[attr_id] = (attr_type, attr_name)
                elseif attr_for == "edge"
                    edge_attr_t[attr_id] = (attr_type, attr_name)
                end
            elseif elname == "graph"
                edgedefault = reader["edgedefault"]
                directed = edgedefault == "directed"   ? true :
                           edgedefault == "undirected" ? false :
                           error("Unknown value of edgedefault: $edgedefault")
                if haskey(reader, "id")
                    graphname = reader["id"]
                else
                    graphname = ""
                end
                if gname == graphname
                    return _graphml_read_one_graph(reader, directed, node_attr_t, edge_attr_t)
                end
            elseif elname == "node" || elname == "edge"
                # ok
            else
                @warn "Skipping unknown XML element '$(elname)' - further warnings will be suppressed" maxlog=1 _id=:unkel
            end
        end
    end
    error("Graph name $graphname is missed from the input parameter. Please set.")
end
