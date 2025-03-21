using Dagger

function enable_tracing!()
    Dagger.enable_logging!(tasknames = true,
                           taskfuncnames = true,
                           taskdeps = true,
                           taskargs = true,
                           taskargmoves = true,
                           taskresult = true,
                           taskuidtotid = true,
                           tasktochunk = true)
end

function disable_tracing!()
    Dagger.disable_logging!()
end

function fetch_trace!()
    return Dagger.fetch_logs!()
end

function dispatch_begin_msg(index)
    "Dispatcher: scheduled graph $index"
end

function dispatch_end_msg(index)
    "Dispatcher: finished graph $index"
end
