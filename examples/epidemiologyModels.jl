# -*- coding: utf-8 -*-
using Petri
using LabelledArrays
using StochasticDiffEq
using OrdinaryDiffEq
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


prob, cb = SDEProblem(sir, u0, tspan, β)

sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)

plot(sol)

prob = ODEProblem(sir, u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

plot(sol)

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

prob, cb = SDEProblem(seir, u0, tspan, β)
sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)

plot(sol)

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

prob, cb = SDEProblem(seird, u0, tspan, β)
sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)

plot(sol)

Graph(seird)