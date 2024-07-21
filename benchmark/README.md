# FrameworkDemo benchmarks

Run benchmarks from the project's main directory

## Usage

Run benchmark script

```
julia --project benchmark/benchmarks
```

or benchmark with [PkgBenchmark](https://github.com/JuliaCI/PkgBenchmark.jl)

```julia
using PkgBenchmark
import FrameworkDemo

benchmarkpkg(FrameworkDemo)
```


## Developing benchmarks

The benchmarks are based on [BenchmarkTools](https://github.com/JuliaCi/BenchmarkTools.jl) and try to follow a standard benchmark structure with `BenchmarkTools::BenchmarkGroups`

Add new benchmarks:

```julia
SUITE["new_benchmark"] = BenchmarkGroup(["tag1", "tag2", "etc"])
SUITE["new_benchmark"]["foo"] = @benchmarkable foo($bar)
```

Add result processing function (e.g. for visualization)

```julia
function plot_foo(results::BenchmarkGroup)
    foo_results = results["new_benchmark"]["foo"]
    do_something(foo_results)
end

push!(result_processors, plot_foo) # register function
```

The functions added to `results_processors` will be called automatically when executing `benchmark/benchmarks.jl` script. Alternatively the functions can be added with `postprocess`argument of `PkgBenchmark.benchmarkpkg`. 
