"""
    toODE(m::Model)

Convert a petri model into a differential equation function that can
be passed into DifferentialEquation.jl or OrdinaryDiffEq.jl solvers
"""
function toODE(m::Model)
    S = m.S
    T = m.Δ
    ϕ = zeros(Float64, length(T))
    statepos = Dict(map(i->last(i)=>first(i),enumerate(S)))
    f(du, u, p, t) = begin
        for (i, δ) in enumerate(T)
            ins = first(δ)
            ϕ[i] = reduce((x,y)->x*u[statepos[y]]/ins[y], keys(ins); init=p[i])
        end
        for (s,i) in statepos
            du[i] = 0
        end
        for (i, δ) in enumerate(T)
            ins = first(δ)
            outs = last(δ)
            for s in keys(ins)
                du[statepos[s]] -= ϕ[i] * ins[s]
            end
            for s in keys(outs)
                du[statepos[s]] += ϕ[i] * outs[s]
            end
        end
        return du
    end
    return f
end
