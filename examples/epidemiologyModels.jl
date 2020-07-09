# -*- coding: utf-8 -*-
using Petri
using LabelledArrays
using OrdinaryDiffEq
using StochasticDiffEq
using Plots
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph

@show "SIR"

S  = [:S,:I,:R]
Δ  = LVector(
      inf=(LVector(S=1, I=1), LVector(I=2)),
      rec=(LVector(I=1),      LVector(R=1)),
     )
sir = Petri.Model(S, Δ)

u0 = LVector(S=10.0, I=1.0, R=0.0)
tspan = (0.0,7.5)
β = LVector(inf=0.4, rec=0.4)


nu, noise = stochasticmodel(sir)
prob_sde = SDEProblem(vectorfields(sir),noise,u0,tspan,β,noise_rate_prototype=nu)

function condition(u,t,integrator) # Event when event_f(u,t) == 0
     u[2]
end
function affect!(integrator)
     integrator.u[2] = 0.0
end
cb = ContinuousCallback(condition,affect!)

sol_sde = StochasticDiffEq.solve(prob_sde,SRA1(),callback=cb)

plot(sol_sde)



prob = ODEProblem(vectorfields(sir), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

display(plot(sol))
Graph(sir)

@show "SEIR"

S2 = [:S,:E,:I,:R]
Δ2 = LVector(
     exp=(LVector(S=1, I=1), LVector(I=1, E=1)),
     inf=(LVector(E=1),      LVector(I=1)),
     rec=(LVector(I=1),      LVector(R=1)),
    )
seir = Petri.Model(S2, Δ2)

u0 = LVector(S=10.0, E=1.0, I=0.0, R=0.0)
tspan = (0.0,15.0)
β = LVector(exp=0.9, inf=0.2, rec=0.5)

prob = ODEProblem(vectorfields(seir), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

display(plot(sol))
Graph(seir)

@show "SEIRD"

S3 = [:S,:E,:I,:R, :D]
Δ3 = LVector(
     exp=(LVector(S=1, I=1), LVector(I=1, E=1)),
     inf=(LVector(E=1),      LVector(I=1)),
     rec=(LVector(I=1),      LVector(R=1)),
     die=(LVector(I=1),      LVector(D=1)),
    )
seird = Petri.Model(S3, Δ3)

u0 = LVector(S=10.0, E=1.0, I=0.0, R=0.0, D=0.0)
tspan = (0.0,15.0)
β = LVector(exp=0.9, inf=0.2, rec=0.5, die=0.1)

prob = ODEProblem(vectorfields(seird), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

display(plot(sol))
Graph(seird)