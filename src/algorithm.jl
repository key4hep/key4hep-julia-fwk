function find_nth_prime(n::Int)
    primes = [2]
    x = 3

    while length(primes) < n
        isPrime = true

        for y in primes
            if x % y == 0
                isPrime = false
                break
            end
        end

        if isPrime
            push!(primes, x)
        end

        x += 2
    end

    return primes[n]
end

function benchmark_prime(n::Int)
    t0 = time()
    find_nth_prime(n)
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
