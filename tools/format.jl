#!/usr/bin/env julia

using JuliaFormatter

if isempty(ARGS)
    format(".")
else
    format(ARGS)
end
