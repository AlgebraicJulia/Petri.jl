# # [Lotka-Volterra Model](@id lotka_volterra_example)
#
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/examples/lotka-volterra.ipynb)

using Petri
using LabelledArrays
using Plots
using OrdinaryDiffEq

# **Step 1:** Define the states and transitions of the Petri Net
# 
# Here we have 2 states, wolves and rabbits, and transitions to
# model predation between the two species in the system

S  = [:rabbits, :wolves]
Δ  = LVector(
       birth=(LVector(rabbits=1), LVector(rabbits=2)),
       predation=(LVector(wolves=1, rabbits=1), LVector(wolves=2)),
       death=(LVector(wolves=1), LVector()),
     )
lotka = Petri.Model(S, Δ)

Graph(lotka)

# **Step 2:** Define the parameters and transition rates
#
# Once a model is defined, we can define out initial parameters `u0`, a time
# span `tspan`, and the transition rates of the interactions `β`

u0 = LVector(wolves=10.0, rabbits=100.0)
tspan = (0.0,100.0)
β = LVector(birth=.3, predation=.015, death=.7);

# **Step 3:** Generate a solver and solve
#
# Finally we can generate a solver and solve the simulation

prob = ODEProblem(lotka, u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

plot(sol)