using Graphs
import Dates

function mockup_function(data::Vector)
    push!(data, 0) # so data is never empty
    result = sum(fetch, data)
    result += 1
    return result
end

function wrapper(data::Vector, vertex_id)
    resulting_data = mockup_function(data)
    # println("Vertex $vertex_id processed with resulting_data: $resulting_data")
    return resulting_data
end
