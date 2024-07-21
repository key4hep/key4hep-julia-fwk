using FrameworkDemo
using BenchmarkTools
using Plots
SUITE = BenchmarkGroup()
result_processors = Function[]

include("cpu_crunching.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    @info "tuning benchmark SUITE"
    tune!(SUITE, verbose = true)
    @info "running benchmark SUITE"
    results = run(SUITE, verbose = true)
    println(results)
    for processor in result_processors
        processor(results)
    end
end