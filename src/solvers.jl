using OrdinaryDiffEq
using StochasticDiffEq

import OrdinaryDiffEq: ODEProblem
import StochasticDiffEq: SDEProblem

funcindex!(list, key, f, vals...) = setindex!(list, f(getindex(list, key),vals...), key)
valueat(x::Number, t) = x
valueat(f::Function, t) = f(t)

""" vectorfields(m::Model)

Convert a petri model into a differential equation function that can
be passed into DifferentialEquation.jl or OrdinaryDiffEq.jl solvers
"""
function vectorfields(m::Model)
    S = m.S
    T = m.Δ
    ϕ = Dict()
    f(du, u, p, t) = begin
        for k in keys(T)
          ins = first(T[k])
          ϕ[k] = reduce((x,y)->x*u[y]/ins[y], keys(ins); init=valueat(p[k],t))
        end
        for s in S
          du[s] = 0
        end
        for k in keys(T)
            ins = first(T[k])
            outs = last(T[k])
            for s in keys(ins)
              funcindex!(du, s, -, ϕ[k] * ins[s])
            end
            for s in keys(outs)
              funcindex!(du, s, +, ϕ[k] * outs[s])
            end
        end
        return du
    end
    return f
end

""" ODEProblem(m::Model, u0, tspan, β)

Generate an OrdinaryDiffEq ODEProblem
"""
ODEProblem(m::Model, u0, tspan, β) = ODEProblem(vectorfields(m), u0, tspan, β)

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
          ϕ[k] = reduce((x,y)->x*u[y]/(sum_u*ins[y]), keys(ins); init=valueat(p[k],t))
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
    return SDEProblem(vectorfields(m),noise,u0,tspan,β,noise_rate_prototype=nu),
           CallbackSet([statecb(s) for s in S]...)
end
