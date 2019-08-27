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
import Base: eval

export Model, solve, funckit

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

""" Problem{M<:Model, S, N}

Structure for representing a petri net problem

represented by a petri net model, initial state, and number of steps
"""
struct Problem{M<:Model, S, N}
  m::M
  initial::S
  steps::N
end

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
function solve(p::Problem)
  state = p.initial
  for i in 1:p.steps
    state = step(p, state)
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

""" eval(m::Model)

evaluate all functions of petri model m
"""
Base.eval(m::Model) = Model(m.g, m.S, eval.(m.Δ), eval.(m.Λ), eval.(m.Φ))

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

function step(p::Petri.Problem{Petri.Model{T,
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

function funcbody(ex::Equation, ctx=:state)
  return ex.lhs.op.name => funcbody(ex.rhs, ctx)
end

function funcbody(ex::Operation, ctx=:state)
  args = Symbol[]
  body = postwalk(convert(Expr, ex)) do x
    # @show x, typeof(x);
    if typeof(x) == Expr && x.head == :call
      if length(x.args) == 1
        var = x.args[1]
        push!(args, var)
        return :($ctx.$var)
      end
    end
    return x
  end
  return body, Set(args)
end

funckit(fname, args, body) = quote $fname($(collect(args)...)) = $body end
funckit(fname::Symbol, arg::Symbol, body) = quote $fname($arg) = $body end

""" funckit(p::Petri.Problem, ctx=:state)

Compile petri net problem to native Julia expressions for faster solving
"""
function funckit(p::Petri.Problem, ctx=:state)
  # @show "Λs"
  λf = map(p.m.Λ) do λ
    body, args = funcbody(λ, ctx)
    fname = gensym("λ")
    q = funckit(fname, ctx, body)
    return q
  end
  # @show "Δs"
  δf = map(p.m.Δ) do δ
    q = quote end
    map(δ) do f
      vname, vfunc = funcbody(f, ctx)
      body, args = vfunc
      qi = :(state.$vname = $body)
      push!(q.args, qi)
    end
    sym = gensym("δ")
    :($sym(state) = $(q) )
  end

  # @show "Φs"
  ϕf = map(p.m.Φ) do ϕ
    body, args = funcbody(ϕ, ctx)
    fname = gensym("ϕ")
    q = funckit(fname, ctx, body)
  end
  return Model(p.m.S, δf, λf, ϕf)
end

end
