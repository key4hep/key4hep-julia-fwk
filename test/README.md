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
  import TestEnv
  TestEnv.activate()
  include("test/runtests.jl")
  # or run only specific set of tests
  include("test/parsing.jl")
  ```

## Arguments

The tests support arguments:

- `no-fast` - don't skip algorithm CPU crunching
- `all` - run all the tests including tests that are skipped by default (QA)
