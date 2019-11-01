# -*- coding: utf-8 -*-
# + {}
""" Petri

Provides a modeling framework for representing and solving stochastic petri nets

"""
module Petri

using ModelingToolkit
import ModelingToolkit: Constant, Variable
using MacroTools
import MacroTools: postwalk
import Base: collect, ==
import Base.Iterators: flatten
# used to avoid eval
import GeneralizedGenerated: mk_function

export Model, Problem, ParamProblem, solve, funckit, evaluate, odefunc, mk_function, symbolic_symplify, NullPetri

include("types.jl")

NullPetri(n::Int) = Model(collect(1:n), Vector{Tuple{Operation,Operation}}())

sample(rates) = begin
  s = cumsum(rates)
  #@show s
  #@show s[end]
  r = rand()*s[end]
  #@show r
  nexti = findfirst(s) do x
    x >= r
  end
  return nexti
end

""" rewrite!(m::Model, m2::Model, f::Dict)

Add or update states from model m2 to model m using function f to map states from m to m2
"""
function rewrite!(m::Model, m2::Model, f::Dict)
  vars = map(m.S) do s
      s.op
  end
  for i in 1:length(m2.S)
    s = m2.S[i]
    found = findfirst(vars .== (haskey(f, s) ? f[s].op : s.op))
    if typeof(found) == Nothing
      push!(m.S, s)
      push!(m.Δ, m2.Δ[i])
      push!(m.Λ, m2.Λ[i])
      push!(m.Φ, m2.Φ[i])
    else
      m.Δ[found] = m2.Δ[i] == Nothing ? m.Δ[found] : m2.Δ[i]
      m.Λ[found] = m2.Λ[i] == Nothing ? m.Λ[found] : m2.Λ[i]
      m.Φ[found] = m2.Φ[i] == Nothing ? m.Φ[found] : m2.Φ[i]
    end
  end
end

""" rewrite!(m::Model, m2::Model)

Add or update states from model m2 to model m using the identity function to map states
"""
function rewrite!(m::Model, m2::Model)
    rewrite!(m, m2, Dict())
end

""" solve(p::Problem)

Evaluate petri net problem and return the final state
"""
function solve(p::AbstractProblem)
  state = p.initial
  for i in 1:p.steps
    state = step(p, state)
  end
  state
end

function solve(p::AbstractProblem, step)
  state = p.initial
  for i in 1:p.steps
      s = step(p, state)
      if s != nothing
          state = s
      end
  end
  state
end

function step(p::Problem, state)
  #@show state
  n = length(p.m.Δ)
  rates = map(p.m.Λ) do λ
    apply(λ, state)
  end
  #@show rates
  nexti = sample(rates)
  #@show nexti
  if apply(p.m.Φ[nexti], state)
    newval = apply(p.m.Δ[nexti], state)
    eqns = p.m.Δ[nexti]
    for i in 1:length(eqns)
      lhs = eqns[i].lhs
      # rhs = eqns[i].rhs
      setproperty!(state, lhs.op.name, newval[i])
    end
  end
  state
end

""" evaluate(m::Model)

evaluate all functions of petri model m
"""
evaluate(m::Model) = Model(m.g, m.S, eval.(m.Δ), eval.(m.Λ), eval.(m.Φ))

function step(p::Problem{Model{T,
              Array{Operation,1},
              Array{Function,1},
              Array{Function,1},
              Array{Function,1}},
              S, N} where {T,S,N},
              state)
  # @show state
  n = length(p.m.Δ)
  rates = map(p.m.Λ) do λ
    λ(state)
  end
  # @show rates
  nexti = sample(rates)
  if nexti == nothing
    return state
  end
  # @show nexti
  if p.m.Φ[nexti](state)
    p.m.Δ[nexti](state)
  end
  state
end

function step(p::Problem{Model{T,
              Array{Operation,1},
              Array{Function,1},
              Array{Function,1},
              Missing},
              S, N} where {T,S,N},
              state)
  # @show state
  n = length(p.m.Δ)
  rates = map(p.m.Λ) do λ
    λ(state)
  end
  # @show rates
  nexti = sample(rates)
  if nexti == nothing
    return state
  end
  # @show nexti
  p.m.Δ[nexti](state)
  state
end
function step(p::ParamProblem{Model{T,
              Array{Operation,1},
              Array{Function,1},
              Array{Function,1},
              Missing},
              S, N} where {T,S,N},
              state)
  # @show state
  n = length(p.m.Δ)
  rates = map(p.m.Λ) do λ
    λ(state, p.param)
  end
  # @show rates
  nexti = sample(rates)
  if nexti == nothing
    return state
  end
  # @show nexti
  p.m.Δ[nexti](state)
  state
end

function apply(expr::Equation, data)
  rhs = expr.rhs
  apply(rhs, data)
end

function apply(expr::Constant, data)
  # constants don't have an op field they are just a value.
  return expr.value
end

function apply(expr::Tuple, data)
  # this method only exists to harmonize the API for Equation, Constant, and Operation
  # all the real work is happening in the three argument version below.
  vals = map(expr) do ex
    apply(ex, data)
  end
  return tuple(vals...)
end

function apply(expr::Operation, data)
  # this method only exists to harmonize the API for Equation, Constant, and Operation
  # all the real work is happening in the three argument version below.
  apply(expr.op, expr, data)
end

# this uses the operation function as a trait, so that we can dispatch on it;
# allowing client code to extend the language using Multiple Dispatch.
function apply(op::Function, expr::Operation, data)
  # handles the case where there are no more arguments to find.
  # we assume this is a leaf node in the expression, which refers to a field in the data
  if length(expr.args) == 0
      return getproperty(data, expr.op.name)
  end
  anses = map(expr.args) do a
    apply(a, data)
  end
  return op(anses...)
end

function collect(d::Dict, seq)
    for p in seq
        if p[1] in keys(d)
            push!(d[p[1]], p[2])
        else
            d[p[1]] = [p[2]]
        end
    end
    return d
end

coeffvalue(coeff::ModelingToolkit.Constant) = coeff.value
coeffvalue(coeff::Any) = coeff

include("metaprogramming.jl")
include("stochastic.jl")
include("ode.jl")
# STATELOOKUP = OpenModels.STATELOOKUP
include("visualization.jl")
end #Module
