using AutoHashEquals

"""
    Model{S,D}

Structure for representing the petri net model

represented by states and transition functions
"""
@auto_hash_equals struct Model{S,D}
  S::S  # states
  Δ::D  # transition function
end

function ==(x::Petri.Model,y::Petri.Model)
  return x.S == y.S && x.Δ == y.Δ
end

abstract type AbstractProblem end

"""
    Problem{M<:Model, S, N}

Structure for representing a petri net problem

represented by a petri net model, initial state, and number of steps
"""
struct Problem{M<:Model, S, N} <: AbstractProblem
  model::M
  initial::S
  steps::N
end
