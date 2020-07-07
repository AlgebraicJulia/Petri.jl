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
