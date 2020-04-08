# -*- coding: utf-8 -*-
using Petri
using OrdinaryDiffEq
using Plots
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph

@show "SIR"

S  = [:S,:I,:R]
Δ  = [
      (Dict(:S=>1, :I=>1), Dict(:I=>2)),
      (Dict(:I=>1),        Dict(:R=>1)),
     ]
m  = Petri.Model(S, Δ)
p  = Petri.Problem(m, Dict(:S=>100, :I=>1, :R=>0), 150)

u0 = [10.0, 1.0, 0.0]
tspan = (0.0,7.5)
β = [0.4, 0.4]

prob = ODEProblem(toODE(p.model), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

display(plot(sol,label=reshape(p.model.S,1,:)))
Graph(p.model)

@show "SEIR"

S2 = [:S,:E,:I,:R]
Δ2 = [
     (Dict(:S=>1, :I=>1), Dict(:I=>1, :E=>1)),
     (Dict(:E=>1),        Dict(:I=>1)),
     (Dict(:I=>1),        Dict(:R=>1)),
    ]
m2 = Petri.Model(S2, Δ2)
p2 = Petri.Problem(m2, Dict(:S=>100, :E=>1, :I=>0, :R=>0), 150)

u0 = [10.0, 1.0, 0.0, 0.0]
tspan = (0.0,15.0)
β = [0.9, 0.2, 0.5]

prob = ODEProblem(toODE(p2.model), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

display(plot(sol,label=reshape(p2.model.S,1,:)))
Graph(p2.model)

@show "SEIRD"

S3 = [:S,:E,:I,:R, :D]
Δ3 = [
     (Dict(:S=>1, :I=>1), Dict(:I=>1, :E=>1)),
     (Dict(:E=>1),        Dict(:I=>1)),
     (Dict(:I=>1),        Dict(:R=>1)),
     (Dict(:I=>1),        Dict(:D=>1)),
    ]
m3 = Petri.Model(S3, Δ3)
p3 = Petri.Problem(m3, Dict(:S=>100, :E=>1, :I=>0, :R=>0, :D=>0), 150)

u0 = [10.0, 1.0, 0.0, 0.0, 0.0]
tspan = (0.0,15.0)
β = [0.9, 0.2, 0.5, 0.1]

prob = ODEProblem(toODE(p3.model), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

display(plot(sol,label=reshape(p3.model.S,1,:)))
Graph(p3.model)
