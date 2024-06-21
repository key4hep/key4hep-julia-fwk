using Distributed

ps1 = addprocs(2)

using Dagger

# Old Dagger API - rmprocs works normally

# argument = delayed(sum)([12, 12, 12])
# ts = delayed(sum)(argument)
# ctx = Context()
# res = @async collect(ctx, ts)

# OR

# Modern Dagger API - rmprocs throws errors

argument = [1,2,3,4,5,6,7,8]
res = Dagger.@spawn sum(argument)

@show fetch(res) |> unique

# println(res)

workers() |> rmprocs