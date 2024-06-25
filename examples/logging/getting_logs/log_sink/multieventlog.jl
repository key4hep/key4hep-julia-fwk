include("../../../dummy_tasks.jl") # here Dagger is imported as well

TimespanLogging = Dagger.TimespanLogging
ctx = Dagger.Sch.eager_context()
ml = TimespanLogging.MultiEventLog() # By default, NoOpLog, which does nothing, is set
ctx.log_sink = ml

# For now, MultiEventLog is unconfigured and will not log anything useful.
# Let's configure it:
ml[:core] = TimespanLogging.Events.CoreMetrics()
ml[:id] = TimespanLogging.Events.IDMetrics()
# ml[:profile] = DaggerWebDash.ProfileMetrics()
ml[:wsat] = Dagger.Events.WorkerSaturation()
ml[:loadavg] = TimespanLogging.Events.CPULoadAverages()
ml[:bytes] = Dagger.Events.BytesAllocd()
ml[:mem] = TimespanLogging.Events.MemoryFree()
ml[:esat] = TimespanLogging.Events.EventSaturation()
ml[:psat] = Dagger.Events.ProcessorSaturation()
ml[:timeline] = TimespanLogging.Events.TimelineMetrics()
# There may be other consumers. In general, they can be defined by user as well to create some custom metrics.

t = modernAPI_graph_setup(1) # Can also be the old API
fetch(t)

logs = Dagger.TimespanLogging.get_logs!(ctx)
println("\n\nRaw logs:")
println(logs) # <- That should be a Dictionary of the form: {worker_id -> {consumer_symbol -> [list of the events on that worker after being processed by a consumer corresponding to this symbol]}}
