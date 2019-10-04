""" Model{G,S,D,L,P}

Structure for representing the petri net model

represented by grounding, states, transition function, transition rates, and predicates
"""
struct Model{G,S,D,L,P}
  g::G  # grounding
  S::S  # states
  Δ::D  # transition function
  Λ::L  # transition rate
  Φ::P  # if state should happen
end

""" Model(s::S, δ::D, λ::L, ϕ::P)

Constructor to initialize a Petri net
"""
Model(s::S, δ::D, λ::L, ϕ::P) where {S,D,L,P} = Model{Any,S,D,L,P}(missing, s, δ, λ, ϕ)

""" Model(s::S, δ::D)

Constructor to initialize a Petri net with just states and transition functions
"""
Model(s::S, δ::D) where {S<:Vector,D<:Vector{Tuple{Operation, Operation}}} = Model(s, δ, [],[])


abstract type AbstractProblem end

""" Problem{M<:Model, S, N}

Structure for representing a petri net problem

represented by a petri net model, initial state, and number of steps
"""
struct Problem{M<:Model, S, N} <: AbstractProblem
  m::M
  initial::S
  steps::N
end

struct ParamProblem{M<:Model, S, V, N} <: AbstractProblem
  m::M
  initial::S
  param::V
  steps::N
end
