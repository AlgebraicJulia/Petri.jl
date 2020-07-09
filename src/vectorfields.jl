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

function stochasticmodel(m::Model)
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
        for k in keys(T)
          ins = first(getindex(T, k))
          ϕ[k] = reduce((x,y)->x*getindex(u,y)/getindex(ins,y), keys(ins); init=valueat(getindex(p, k),t))
        end

        for k in keys(T)
          l,r = getindex(T, k)
          rate = getindex(ϕ, k)
          rate = rate < 0 ? 0 : sqrt(rate)
          for i in keys(l)
            du[Spos[i],Tpos[k]] = -rate
          end
          for i in keys(r)
            du[Spos[i],Tpos[k]] = rate
          end
        end
        return du
    end
    return nu, noise
end
