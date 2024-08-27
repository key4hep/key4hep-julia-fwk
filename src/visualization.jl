import Colors

function save_logs_dot(logs, path::String)
    open(path, "w") do io
        ModGraphVizSimple.show_logs(io, logs, :graphviz_simple)
        @info "Written logs dot graph to $path"
    end
end
