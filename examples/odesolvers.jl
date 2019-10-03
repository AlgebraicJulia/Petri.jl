using LabelledArrays
using OrdinaryDiffEq
import OrdinaryDiffEq: solve
using ModelingToolkit
using Petri
import Petri: stripnullterms, fluxes, odefunc, quotesplat
using Test
using Plots

N(x) = sum(x)

@variables S,E,I,R, β,γ,μ
sir = Petri.Model([S,I,R],[(S+I, 2I), (I,R)])
seir = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R)])
seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])

@info "SIR Solving"
u0 = @LArray [100.0, 1, 0] (:S, :I, :R)
p = @LArray [0.35, 0.05] (:μ, :β)
fex = odefunc(sir, :sir)
f = eval(fex)
prob = ODEProblem(f,u0,(0.0,365.0),p)
sol = solve(prob,Tsit5())
plt = plot(sol, labels=LabelledArrays.symnames(typeof(sol[end]))|> collect)
savefig(plt, "img/sir_sol.png")
@test sol[end].S < 1
@test sol[end].I < 1
@test sol[end].R > 99

@info "SEIR Solving"
u0 = @LArray [100.0, 1, 0, 0] (:S, :E, :I, :R)
p = @LArray [0.35, 0.05, 0.05] (:μ, :β, :γ)
fex = odefunc(seir, :seir)
f = eval(fex)
prob = ODEProblem(f,u0,(0.0,365.0),p)
sol = solve(prob,Tsit5())
plt = plot(sol, labels=LabelledArrays.symnames(typeof(sol[end]))|> collect)
savefig(plt, "img/seir_sol.png")
@test sol[end].S < 1
@test sol[end].E < 1
@test sol[end].I < 1
@test sol[end].R > 99

@info "SEIRS Solving"
u0 = @LArray [100.0, 1, 0, 0] (:S, :E, :I, :R)
p = @LArray [0.35, 0.05, 0.07, 0.3] (:μ, :β, :γ, :η)
fex = odefunc(seirs, :seirs)
f = eval(fex)
prob = ODEProblem(f,u0,(0.0,365.0),p)
sol = solve(prob,Tsit5())
plt = plot(sol, labels=LabelledArrays.symnames(typeof(sol[end])) |> collect)
savefig(plt, "img/seirs_sol.png")
@test sol[end].S > 5
@test sol[end].E > 5
@test sol[end].I > 5
@test sol[end].R > 5
@test sol[end].S < 95
@test sol[end].E < 95
@test sol[end].I < 95
@test sol[end].R < 95
