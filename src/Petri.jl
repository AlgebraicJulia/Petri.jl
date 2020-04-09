"""
    Petri

Provides a modeling framework for representing and solving stochastic petri nets

"""
module Petri

export Model, Problem, NullPetri, solve, toODE, NullPetri

function funcindex!(list, key, f, vals...)
  setindex!(list, f(getindex(list, key),vals...), key)
end

include("types.jl")

"""
    NullPetri(n::Int)

create a Petri net of ``n`` states with no transitions
"""
NullPetri(n::Int) = Model(collect(1:n), Vector{Tuple{Dict{Int, Int},Dict{Int, Int}}}())

"""
    solve(p::Problem)

Evaluate petri net problem and return the final state
"""
function solve(p::AbstractProblem)
  state = p.initial
  for i in 1:p.steps
    state = step(p, state)
  end
  return state
end

function validTransition(state, δ)
  ins = first(δ)
  all(s->getindex(state,s) >= getindex(ins,s), keys(ins))
end

function step(p::Problem, state)
  ks = keys(p.model.Δ)
  i = rand(1:length(ks))
  δ = getindex(p.model.Δ, getindex(ks, i))
  if validTransition(state, δ)
    return apply(state, δ)
  else
    return state
  end
end

function apply(state, δ)
  ins = first(δ)
  outs = last(δ)
  out = deepcopy(state)
  for k in keys(ins)
    funcindex!(out, k, -, getindex(ins, k))
  end
  for k in keys(outs)
    funcindex!(out, k, +, getindex(outs, k))
  end
  return out
end

include("ode.jl")
include("visualization.jl")

end #Module
