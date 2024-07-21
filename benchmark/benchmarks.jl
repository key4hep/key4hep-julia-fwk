using FrameworkDemo
using BenchmarkTools
using Plots
suite = BenchmarkGroup()
result_processors = []
include("cpu_crunching.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    @info "tuning benchmark suite"
    tune!(suite)
    @info "running benchmark suite"
    results = run(suite)
    println(results)
    for processor in result_processors
        processor(results)
    end
end