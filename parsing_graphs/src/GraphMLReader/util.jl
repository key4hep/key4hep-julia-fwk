###############################################################################
# The code below is essentially a fixed version of the one here: https://github.com/zhangliye/GraphMLReader.jl

function check_node_fields(G)
    fields = node_fields(G)
    
    for v in Graphs.vertices(G)
        att = props(G, v)
        if length(att) != length(fields)
            @warn att, " Field number is different. ", fields
            return false
        end
        for (name,val) in att
            if !in(name, fields)
                @warn name, " not found in ", fields
                return false
            end
        end
    end
    return true
end

function check_edge_fields(G)
    fields = edge_fields(G)

    for e in Graphs.edges(G)
        att = props(G, e)
        if length(att) != length(fields)
            @warn att, " Field number is different. ", fields
            return false
        end
        for (name,val) in att
            if !in(name, fields)
                @warn name, " not found in ", fields
                return false
            end
        end
    end
    return true
end

function node_fields(G)
    fields = Set{Symbol}()
    for v in Graphs.vertices(G)
        for (name,val) in props(G, v)
            push!(fields, name)
        end
    end
    return fields 
end

function edge_fields(G)
    fields = Set{Symbol}()
    for e in Graphs.edges(G)
        for (name,val) in props(G, e)
            push!(fields, name)
        end
    end
    return fields 
end

""" 

get dict of {:orginal_id=>current_id}.
"""
function gmlid2metaid(G) 
    ids = Dict{String, Int}()
    for v in Graphs.vertices(G)
        ids[ props(G, v)[:original_id] ] = v
    end
    return ids
end
