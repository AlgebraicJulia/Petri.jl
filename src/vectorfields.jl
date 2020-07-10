using OrdinaryDiffEq
using StochasticDiffEq

import OrdinaryDiffEq: ODEProblem
import StochasticDiffEq: SDEProblem

valueat(x::Number, t) = x
valueat(f::Function, t) = f(t)

"""
    vectorfields(m::Model)

Convert a petri model into a differential equation function that can
be passed into DifferentialEquation.jl or OrdinaryDiffEq.jl solvers
"""
function vectorfields(m::Model)
    S = m.S
    T = m.Δ
    ϕ = Dict()
    f(du, u, p, t) = begin
        for k in keys(T)
          ins = first(getindex(T, k))
          setindex!(ϕ, reduce((x,y)->x*getindex(u,y)/getindex(ins,y), keys(ins); init=valueat(getindex(p, k),t)), k)
        end
        for s in S
            setindex!(du, 0, s)
        end
        for k in keys(T)
            ins = first(getindex(T, k))
            outs = last(getindex(T, k))
            for s in keys(ins)
              funcindex!(du, s, -, getindex(ϕ, k) * getindex(ins, s))
            end
            for s in keys(outs)
              funcindex!(du, s, +, getindex(ϕ, k) * getindex(outs, s))
            end
        end
        return du
    end
    return f
end

function ODEProblem(m::Model,u0,tspan,β)
  return ODEProblem(vectorfields(m), u0, tspan, β)
end

function statecb(s)
     cond = (u,t,integrator) -> u[s]
     aff = (integrator) -> integrator.u[s] = 0.0
     return ContinuousCallback(cond, aff)
end

function SDEProblem(m::Model,u0,tspan,β)
    S = m.S
    T = m.Δ
    ϕ = Dict()
    Spos = Dict(S[k]=>k for k in keys(S))
    Tpos = Dict(keys(T)[k]=>k for k in keys(keys(T)))
    nu = zeros(Float64, length(S), length(T))
    for k in keys(T)
      l,r = getindex(T, k)
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
          ins = first(getindex(T, k))
          ϕ[k] = reduce((x,y)->x*getindex(u,y)/(sum_u*getindex(ins,y)), keys(ins); init=valueat(getindex(p, k),t))
        end

        for k in keys(T)
          l,r = getindex(T, k)
          rate = sqrt(abs(getindex(ϕ, k)))
          for i in keys(l)
            du[Spos[i],Tpos[k]] = -rate
          end
          for i in keys(r)
            du[Spos[i],Tpos[k]] = rate
          end
        end
        return du
    end
    prob_sde = SDEProblem(vectorfields(m),noise,u0,tspan,β,noise_rate_prototype=nu)
    cb = CallbackSet([statecb(s) for s in S]...)
    return prob_sde, cb
end
