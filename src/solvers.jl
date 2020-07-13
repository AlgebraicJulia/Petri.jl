using DiffEqBase
using OrdinaryDiffEq
using SteadyStateDiffEq
using StochasticDiffEq
using DiffEqJump

import OrdinaryDiffEq: ODEProblem
import SteadyStateDiffEq: SteadyStateProblem
import StochasticDiffEq: SDEProblem
import DiffEqJump: JumpProblem

funcindex!(list, key, f, vals...) = list[key] = f(list[key],vals...)
valueat(x::Number, t) = x
valueat(f::Function, t) = f(t)
transitionrate(S, T, k, rate, t) = exp(reduce((x,y)->x+log(S[y] <= 0 ? 0 : S[y]),
                                       keys(first(T[k]));
                                       init=log(valueat(rate[k],t))))

""" vectorfield(m::Model)

Convert a petri model into a differential equation function that can
be passed into DifferentialEquation.jl or OrdinaryDiffEq.jl solvers
"""
function vectorfield(m::Model)
    S = m.S
    T = m.Δ
    ϕ = Dict()
    f(du, u, p, t) = begin
        for k in keys(T)
          ϕ[k] = transitionrate(u, T, k, p, t)
        end
        for s in S
          du[s] = 0
        end
        for k in keys(T)
            l,r = T[k]
            for s in keys(l)
              funcindex!(du, s, -, ϕ[k] * l[s])
            end
            for s in keys(r)
              funcindex!(du, s, +, ϕ[k] * r[s])
            end
        end
        return du
    end
    return f
end

""" ODEProblem(m::Model, u0, tspan, β)

Generate an OrdinaryDiffEq ODEProblem
"""
ODEProblem(m::Model, u0, tspan, β) = ODEProblem(vectorfield(m), u0, tspan, β)

""" SteadyStateProblem(m::Model, u0, tspan, β)

Generate an SteadyStateDiffEq SteadyStateProblem
"""
SteadyStateProblem(m::Model, u0, tspan, β) = SteadyStateProblem(ODEProblem(m, u0, tspan, β))

function statecb(s)
     cond = (u,t,integrator) -> u[s]
     aff = (integrator) -> integrator.u[s] = 0.0
     return ContinuousCallback(cond, aff)
end

""" SDEProblem(m::Model, u0, tspan, β)

Generate an StochasticDiffEq SDEProblem and an appropriate CallbackSet
"""
function SDEProblem(m::Model, u0, tspan, β)
    S = m.S
    T = m.Δ
    ϕ = Dict()
    Spos = Dict(S[k]=>k for k in keys(S))
    Tpos = Dict(keys(T)[k]=>k for k in keys(keys(T)))
    nu = zeros(Float64, length(S), length(T))
    for k in keys(T)
      l,r = T[k]
      for i in keys(l)
        nu[Spos[i],Tpos[k]] -= l[i]
      end
      for i in keys(r)
        nu[Spos[i],Tpos[k]] += r[i]
      end
    end
    noise(du, u, p, t) = begin
        sum_u = sum(u)
        for k in keys(T)
          ins = first(T[k])
          ϕ[k] = transitionrate(u, T, k, p, t)
        end

        for k in keys(T)
          l,r = T[k]
          rate = sqrt(abs(ϕ[k]))
          for i in keys(l)
            du[Spos[i],Tpos[k]] = -rate
          end
          for i in keys(r)
            du[Spos[i],Tpos[k]] = rate
          end
        end
        return du
    end
    return SDEProblem(vectorfield(m),noise,u0,tspan,β,noise_rate_prototype=nu),
           CallbackSet([statecb(s) for s in S]...)
end

jumpTransitionRate(T, k) = (u,p,t) -> transitionrate(u, T, k, p, t)

function jumpTransitionFunction(t)
  return (integrator) -> begin
    l,r = t
    for i in keys(l)
      integrator.u[i] -= l[i]
    end
    for i in keys(r)
      integrator.u[i] += r[i]
    end
  end
end

""" JumpProblem(m::Model, u0, tspan, β)

Generate an DiffEqJump JumpProblem
"""
function JumpProblem(m::Model, u0, tspan, β)
  T = m.Δ
  prob = DiscreteProblem(u0, tspan, β)
  return JumpProblem(prob, Direct(), [ConstantRateJump(jumpTransitionRate(T, k),
                                                       jumpTransitionFunction(T[k])
                                                      ) for k in keys(T)]...)
end
