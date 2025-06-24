# FrameworkDemo.jl

[![test](https://github.com/key4hep/key4hep-julia-fwk/actions/workflows/test.yml/badge.svg)](https://github.com/key4hep/key4hep-julia-fwk/actions/workflows/test.yml)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Demonstrator project for HEP event-processing application framework in Julia and using [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl)


## Getting started

Set-up the project:

```sh
git clone <path>
cd key4hep-julia-fwk
julia --project -e "import Pkg; Pkg.instantiate()"
```

## Usage

See options for running with an example data flow graph in `data/`:

```sh
julia --project bin/schedule.jl --help
```

## Preferences

The [Preferences](https://juliapackaging.github.io/Preferences.jl/stable/) are used to select whether [DistributedNext](https://github.com/JuliaParallel/DistributedNext.jl) (default) or [Distributed](https://github.com/JuliaLang/Distributed.jl) is used for distributed computing.
The preferences can be changed with:

```sh
julia --project -e "using FrameworkDemo; FrameworkDemo.set_distributed_package!(\"Distributed\")"
```

The changes will be stored in `LocalPreferences.toml` in the project directory which overwrites the default preferences in [`Project.toml`](Project.toml).
