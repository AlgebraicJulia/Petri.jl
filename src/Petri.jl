# -*- coding: utf-8 -*-
# + {}
""" Petri

Provides a modeling framework for representing and solving stochastic petri nets

"""
module Petri

export Model, Problem, NullPetri, solve, toODE, NullPetri

include("types.jl")

NullPetri(n::Int) = Model(collect(1:n), Vector{Tuple{Dict{Int, Int},Dict{Int, Int}}}())

""" solve(p::Problem)

Evaluate petri net problem and return the final state
"""
function solve(p::AbstractProblem)
  state = p.initial
  for i in 1:p.steps
    state = step(p, state)
  end
  return state
end

function solve(p::AbstractProblem, step)
  state = p.initial
  for i in 1:p.steps
      s = step(p, state)
      if s != nothing
          state = s
      end
  end
  return state
end

function validTransition(state, δ)
  all(state[s] >= v for (s,v) in first(δ))
end

function step(p::Problem, state)
  i = rand(1:length(p.model.Δ))
  if validTransition(state, p.model.Δ[i])
    return apply(state, p.model.Δ[i])
  else
    return state
  end
end

function apply(state, δ)
  out = deepcopy(state)
  map(k->out[first(k)] -= last(k), collect(first(δ)))
  map(k->out[first(k)] += last(k), collect(last(δ)))
  return out
end

include("ode.jl")
include("visualization.jl")

end #Module
