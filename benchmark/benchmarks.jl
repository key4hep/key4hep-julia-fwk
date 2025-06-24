using FrameworkDemo
using BenchmarkTools
using Plots

const SUITE = BenchmarkGroup()
const result_processors = Function[]

include("suite/cpu_crunching.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    @info "tuning benchmark suite"
    tune!(SUITE, verbose = true)
    @info "running benchmark suite"
    results = run(SUITE, verbose = true)
    @info "running benchmark suite" results
    for processor in result_processors
        processor(results)
    end
end
