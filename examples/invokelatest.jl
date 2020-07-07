using Petri
import Petri: vectorfields
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
Δ   = LVector(
       inf=(LVector(S=1, I=1), LVector(I=2)),
       rec=(LVector(I=1),      LVector(R=1)),
      )
sir = Petri.Model(S, Δ)

u0  = LVector(S=100.0, I=1.0, R=0.0)
p   = LVector(inf=0.35, rec=0.05)
t   = (0, 365.0)

@info "SIR Solving"
f = vectorfields(sir)
@time prob, soln = solver1(f, u0, p, t)
@time prob, soln = solver1(f, u0, p, t)

@info "successfully ran global eval passed to function"


function makesolve(m, name, u0, p, t)
    u0 = LVector(S=100.0, I=1.0, R=0.0)
    p = LVector(inf=0.35, rec=0.05)
    f = vectorfields(m)
    prob, soln = Base.invokelatest(solver1, f, u0, p, (0, 365.0))
end

@time prob2, soln2 = makesolve(sir, :sir, u0, p, t)
@time prob2, soln2 = makesolve(sir, :sir, u0, p, t)
@info "makesolve approach worked but was slow."

norm(x)= sqrt(sum(map(y->y*y, x)))

@show  norm(soln(360.0) - soln2(360.0))
