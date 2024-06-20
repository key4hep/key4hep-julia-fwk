# How to start?

```
git clone <path>
cd key4hep-julia-fwk
git submodule update --init --recursive
julia --project=.
julia> using Pkg
julia> Pkg.instantiate()
julia> include("./graphs_scheduling/src/main.jl")
```