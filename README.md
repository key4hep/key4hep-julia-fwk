# FrameworkDemo.jl

[![test](https://github.com/key4hep/key4hep-julia-fwk/actions/workflows/test.yml/badge.svg)](https://github.com/key4hep/key4hep-julia-fwk/actions/workflows/test.yml)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Demonstrator project for HEP event-processing application framework in Julia


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

or use with REPL:

```julia
using FrameworkDemo
```

## Compilation

The runner can be statically compiled with Julia 1.12 and later:

```
julia make.jl
```

and then run:

```
JULIA_NUM_THREADS=<threads> ./frameworkdemo_schedule <options>
```
