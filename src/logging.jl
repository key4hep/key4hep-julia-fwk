using Dagger

function configure_LocalEventLog()
    ctx = Dagger.Sch.eager_context()
    log = Dagger.TimespanLogging.LocalEventLog()
    ctx.log_sink = log
end

function fetch_logs!()
    return Dagger.fetch_logs!()
end

function dispatch_begin_msg(index)
    "Dispatcher: scheduled graph $index"
end

function dispatch_end_msg(index)
    "Dispatcher: finished graph $index"
end
