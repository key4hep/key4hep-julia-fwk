# AOT compile bin/schedule to standalone application
# julia make.jl

function (@main)(args)
    source_dir = @__DIR__
    source = joinpath(source_dir, "bin", "schedule.jl")
    target = "frameworkdemo_schedule"
    @info "Compiling $(source) to $(target)"
    julia_path = joinpath(Sys.BINDIR, Base.julia_exename())
    juliac_path = joinpath(Sys.BINDIR, "..", "share", "julia", "juliac", "juliac.jl")
    cmd = "$(julia_path) --project=$(source_dir) $(juliac_path) --experimental --trim=no --output-exe $(target) $(source)"
    @info "Running command: $(cmd)"
    compilation_time = @elapsed run(`$(split(cmd))`)
    @info "Compiled in $(compilation_time) seconds"
    return 0
end
