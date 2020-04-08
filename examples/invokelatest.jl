using Petri
import Petri: toODE
using OrdinaryDiffEq
import OrdinaryDiffEq: solve
using Test
using Plots

function solver1(f, u0, p, t)
    prob = ODEProblem(f,u0,(0.0,365.0),p)
    soln = solve(prob,Tsit5())
    return prob, soln
end


# the following approach works
S   = [:S,:I,:R]
Δ   = [
       (Dict(:S=>1, :I=>1), Dict(:I=>2)),
       (Dict(:I=>1),        Dict(:R=>1)),
      ]
sir = Petri.Model(S, Δ)

u0  = [100.0, 1, 0]
p   = [0.35, 0.05]
t   = (0, 365.0)

@info "SIR Solving"
f = toODE(sir)
@time prob, soln = solver1(f, u0, p, t)
@time prob, soln = solver1(f, u0, p, t)

@info "successfully ran global eval passed to function"


function makesolve(m, name, u0, p, t)
    u0 = [100.0, 1, 0]
    p = [0.35, 0.05]
    f = toODE(m)
    prob, soln = Base.invokelatest(solver1, f, u0, p, (0, 365.0))
end

@time prob2, soln2 = makesolve(sir, :sir, u0, p, t)
@time prob2, soln2 = makesolve(sir, :sir, u0, p, t)
@info "makesolve approach worked but was slow."

norm(x)= sqrt(sum(map(y->y*y, x)))

@show  norm(soln(360.0) - soln2(360.0))

#= @info "Running GG version" =#


#= function ggsolve(m, name, u0, p, t) =#
#=     u0 = [100.0, 1, 0] =#
#=     p = [0.35, 0.05] =#
#=     f = toODE(m) =#
#=     f = mk_function(m) =#
#=     du = similar(u0) =#
#=     f(du, u0, p, 0) =#
#=     prob = ODEProblem(f, u0, t, p) =#
#=     soln = solve(prob, Tsit5()) =#
#=     return prob, soln =#
#= end =#

#= @time prob3, soln3 = ggsolve(sir, :sir, u0, p, t) =#
#= @time prob3, soln3 = ggsolve(sir, :sir, u0, p, t) =#
#= @info "gg approach worked and is fast." =#

#= @show  norm(soln(360.0) - soln3(360.0)) =#
