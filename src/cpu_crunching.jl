# meant to be consistently inefficient for crunching purposes.
# just returns the largest prime less than `n_max`
function find_primes(n_max::Int)
    largest_prime = 2

    for n in 3:n_max
        isPrime = true

        for y in 2:(n ÷ 2)
            if n % y == 0
                isPrime = false
                break
            end
        end

        if isPrime
            largest_prime = n
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

function calculate_coefficients(min = 1000, max = 200_000)::Vector{Float64}
    n_max = [min, max]
    t_average = benchmark_prime.(n_max)

    coefficients = inv([n_max[i]^j for i in 1:2, j in 1:2]) * t_average
    @info "Calibrated crunching coefficients: $coefficients"
    return coefficients
end

function crunch_for_seconds(t::Float64, coefficients::Vector{Float64})
    (b, a) = coefficients
    n = ceil(Int, (-b + sqrt(abs(b^2 + 4a * t))) / 2a)
    find_primes(n)
end
