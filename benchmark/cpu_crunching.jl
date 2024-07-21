import Printf

suite["cpu_crunching"] = BenchmarkGroup(["cpu_crunching"])

suite["cpu_crunching"]["find_primes"] = BenchmarkGroup(["find_primes"])
for i in exp10.(range(0, stop=6, length=10))
    n = ceil(Int, i)
    suite["cpu_crunching"]["find_primes"][n] = @benchmarkable FrameworkDemo.find_primes($n) evals = 1 samples = 1
end

suite["cpu_crunching"]["crunch_for_seconds"] = BenchmarkGroup(["crunch_for_seconds"])
coef = FrameworkDemo.calculate_coefficients()
for i in exp10.(range(-6, stop=1.5, length=10))
    suite["cpu_crunching"]["crunch_for_seconds"][i] = @benchmarkable FrameworkDemo.crunch_for_seconds($i, $coef) evals = 1 samples = 1
end

function plot_find_primes(results::BenchmarkGroup)
    primes_r = sort(collect(results["cpu_crunching"]["find_primes"]), by=first)
    x = first.(primes_r)
    y = primes_r .|> last .|> minimum .|> time |> x -> x * 1e-9
    p = plot(x, y, xaxis=:log10, yaxis=:log10, xlabel="n", ylabel="time [s]",
        title="find_primes(n)", label="find_primes",
        marker=(:circle, 5), linewidth=3,
        xguidefonthalign=:right, yguidefontvalign=:top, legend=:topleft)
    filename = "bench_find_primes.png"
    savefig(p, filename)
    @info "Results of benchmark cpu_crunching/find_primes written to $filename"
end

push!(result_processors, plot_find_primes)

function plot_crunch_for_seconds(results::BenchmarkGroup)
    crunch_r = sort(collect(results["cpu_crunching"]["crunch_for_seconds"]), by=first)
    x = first.(crunch_r)
    y = crunch_r .|> last .|> minimum .|> time |> x -> x * 1e-9
    p = plot(x, (y - x) ./ x, xaxis=:log10, xlabel="t [s]", ylabel="Time relative error",
        yformatter=x -> Printf.@sprintf("%.2f%%", 100 * x),
        title="crunch_for_seconds(t)", label="crunch_for_seconds",
        marker=(:circle, 5), linewidth=3,
        xguidefonthalign=:right, yguidefontvalign=:top, legend=:bottomright)
    filename = "bench_crunch_for_seconds.png"
    savefig(p, filename)
    @info "Results of benchmark cpu_crunching/crunch_for_seconds written to $filename"
end

push!(result_processors, plot_crunch_for_seconds)
