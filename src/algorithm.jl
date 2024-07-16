# meant to be consistently inefficient for crunching purposes.
# just returns the largest prime less than `n_max`
function find_primes(n_max::Int)
    primes = [2]
    x = 3

    for n in 3:n_max
        isPrime = true

        for y in 2:n÷2
            if n % y == 0
                isPrime = false
                break
            end
        end

        if isPrime
            push!(primes, n)
        end
    end

    return primes[end]
end

function benchmark_prime(n::Int)
    t0 = time()
    find_primes(n)
    Δt = time() - t0

    return Δt
end

function calculate_coefficient()
    return sum(benchmark_prime(10000) for _ in 1:10) / 1e9
end

function crunch_for_seconds(t::Float64, coefficient::Float64)
    n = ceil(Int, sqrt(t/coefficient))
    find_nth_prime(n)
end
