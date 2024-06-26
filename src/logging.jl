using Dagger
using DaggerWebDash
using TimespanLogging
using Dates

function configure_webdash_multievent()
    ctx = Dagger.Sch.eager_context()
    ml = Dagger.TimespanLogging.MultiEventLog()

    TimespanLogging = Dagger.TimespanLogging
    ## Add some logging events of interest

    ml[:core] = TimespanLogging.Events.CoreMetrics()
    ml[:id] = TimespanLogging.Events.IDMetrics()
    ml[:timeline] = TimespanLogging.Events.TimelineMetrics()
    # ...

    # (Optional) Enable profile flamegraph generation with ProfileSVG
    ml[:profile] = DaggerWebDash.ProfileMetrics()
    ctx.profile = true

    # Create a LogWindow; necessary for real-time event updates
    lw = TimespanLogging.Events.LogWindow(20*10^9, :core)
    ml.aggregators[:logwindow] = lw

    # Create the D3Renderer server on port 8080
    d3r = DaggerWebDash.D3Renderer(8080)

    ## Add some plots! Rendered top-down in order

    # Show an overview of all generated events as a Gantt chart
    push!(d3r, DaggerWebDash.GanttPlot(:core, :id, :esat, :psat; title="Overview"))

    # Show various numerical events as line plots over time
    push!(d3r, DaggerWebDash.LinePlot(:core, :wsat, "Worker Saturation", "Running Tasks"))
    push!(d3r, DaggerWebDash.LinePlot(:core, :loadavg, "CPU Load Average", "Average Running Threads"))
    push!(d3r, DaggerWebDash.LinePlot(:core, :bytes, "Allocated Bytes", "Bytes"))
    push!(d3r, DaggerWebDash.LinePlot(:core, :mem, "Available Memory", "% Free"))

    # Show a graph rendering of compute tasks and data movement between them
    # Note: Profile events are ignored if absent from the log
    push!(d3r, DaggerWebDash.GraphPlot(:core, :id, :timeline, :profile, "DAG"))

    # TODO: Not yet functional
    #push!(d3r, DaggerWebDash.ProfileViewer(:core, :profile, "Profile Viewer"))
    # Add the D3Renderer as a consumer of special events generated by LogWindow
    push!(lw.creation_handlers, d3r)
    push!(lw.deletion_handlers, d3r)

    # D3Renderer is also an aggregator
    ml.aggregators[:d3r] = d3r

    ctx.log_sink = ml
end

function configure_LocalEventLog()
    TimespanLogging = Dagger.TimespanLogging
    ctx = Dagger.Sch.eager_context()
    log = TimespanLogging.LocalEventLog()
    ctx.log_sink = log
end

function timestamp_string(str)
    dt = Dates.now()
    timestamp = Dates.format(dt, "yyyy-mm-dd HH-MM-SS")
    return str * " " * timestamp
end

function fetch_LocalEventLog()
    ctx = Dagger.Sch.eager_context()
    logs = Dagger.TimespanLogging.get_logs!(ctx.log_sink)
    # str = Dagger.show_plan() - doesn't work (exist)   
    return logs 
end

function my_show_plan(io::IO, logs::Vector{Dagger.TimespanLogging.Timespan}, t=nothing)
    println(io, """strict digraph {
    graph [layout=dot,rankdir=LR];""")
    ModGraphVizSimple.write_dag(io, t, logs)
    println(io, "}")
end

function flush_logs_to_file(log_file)
    open(log_file, "w") do io
        my_show_plan(io, Dagger.fetch_logs!(), nothing) # Writes graph to a file
    end
end

function flush_logs_to_file(log_file, t::Thunk)
    open(log_file, "w") do io
        Dagger.show_logs(io, t, Dagger.fetch_logs!(), :graphviz_simple) # Writes graph to a file
    end
end

function save_logs(log_file, logs)
    open(log_file, "w") do io
        write(io, logs)
    end
end