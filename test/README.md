# FrameworkDemo tests

## Usage

Run the tests with:

- Pkg REPL (arguments not supported):
  ```julia
  ] test
  ```
- Pkg:
  ```julia
  import Pkg
  Pkg.test("FrameworkDemo")
  # or with arguments
  Pkg.test("FrameworkDemo"; test_args=<list of args>)
  ```
- Manually:
  ```
  julia --project test/runtests.jl <list of args>
  ```
- REPL:
  ```julia
  append!(ARGS, <list of args>)
  include("test/runtests.jl")
  ```

## Arguments

The tests support arguments:

- `no-fast` - don't skip algorithm CPU crunching
