"""
    Petri

Provides a modeling framework for representing and solving stochastic petri nets

"""
module Petri

export Model, NullPetri, EmptyPetri, vectorfield, Graph

include("types.jl")
include("solvers.jl")
include("visualization.jl")

end
