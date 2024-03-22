using BenchmarkTools: haskey
include("../src/GraphMLReader/GraphMLReader.jl")
using LightGraphs
using MetaGraphs
using JSON
using BenchmarkTools
using Test

# Empty for now