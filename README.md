# FrameworkDemo.jl

[![test](https://github.com/key4hep/key4hep-julia-fwk/actions/workflows/test.yml/badge.svg)](https://github.com/key4hep/key4hep-julia-fwk/actions/workflows/test.yml)

Demonstrator project for HEP data-processing framework in Julia


## Getting started

Set-up the project:

```
git clone <path>
cd key4hep-julia-fwk
git submodule update --init --recursive
julia --project -e "import Pkg; Pkg.instantiate()"
```

## Usage

Run an example:

```
julia --project examples/schedule.jl
```

or use with REPL:

```julia
using FrameworkDemo
```
