# # [Basic Epidemiology Models](@id epidemiology_example)
#
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/examples/epidemiology.ipynb)

using Petri
using LabelledArrays
using Plots
using JumpProcesses
using StochasticDiffEq
using OrdinaryDiffEq

# ### SIR Model
#
# The SIR model represents the epidemiological dynamics of an infectious disease
# that causes immunity in its victims. There are three *states:* `Suceptible
# ,Infected, Recovered`. These states interact through two *transitions*.
# Infection has the form `S+I -> 2I` where a susceptible person meets an
# infected person and results in two infected people. The second transition is
# recovery `I -> R` where an infected person recovers spontaneously.

S  = [:S,:I,:R]
Δ  = LVector(
       inf=(LVector(S=1, I=1), LVector(I=2)),
       rec=(LVector(I=1),      LVector(R=1)),
     )
sir = Petri.Model(S, Δ)

Graph(sir)

# Once a model is defined, we can define out initial parameters `u0`, a time
# span `tspan`, and the transition rates of the interactions `β`

u0 = LVector(S=990.0, I=10.0, R=0.0)
tspan = (0.0,40.0)
# add a dynamic transition rate for infection
# where the rate of infection decreases over time
# as is dependent on the current state of the system
β = LVector(inf=((u,t)->((3/sum(u))/(t+1))), rec=0.25);

# each transition rates can one of three options:
#
# - constant: `β = [.25]`
#   - where the rate is specified by a value of type `Number`
# - time dependent: `β = [t->((3/1000)/(t+1))]`
#   - where `t` is the current time step
# - state and time dependent: `β = [(u,t)->((3/sum(u))/(t+1))]`
#   - where `u` is the current state of `u0` and `t` is the current time step

# Petri.jl provides interfaces to StochasticDiffEq.jl, JumpProcesses.jl, and
# OrdinaryDiffEq.jl Here, we call the `JumpProblem` function that returns an
# JumpProcesses problem object that can be passed to the JumpProcesses solver which
# can then be plotted and visualized

prob = JumpProblem(sir, u0, tspan, β)
sol = JumpProcesses.solve(prob,SSAStepper())

plot(sol)

# Similarly, we can generated `SDEProblem` statements that can be used with
# StochasticDiffEq solvers

prob, cb = SDEProblem(sir, u0, tspan, β)
sol = StochasticDiffEq.solve(prob,LambaEM(),callback=cb)

plot(sol)

# Lastly, we can generated `ODEProblem` statements that can be used with
# OrdinOrdinaryDiffEq solvers

prob = ODEProblem(sir, u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

plot(sol)

# ### SEIR Model

S = [:S,:E,:I,:R]
Δ = LVector(
      exp=(LVector(S=1, I=1), LVector(I=1, E=1)),
      inf=(LVector(E=1),      LVector(I=1)),
      rec=(LVector(I=1),      LVector(R=1)),
    )
seir = Petri.Model(S, Δ)

Graph(seir)
#-
u0 = LVector(S=990.0, E=10.0, I=0.0, R=0.0)
tspan = (0.0,40.0)
β = LVector(exp=0.7/sum(u0), inf=0.5, rec=0.25)

prob, cb = SDEProblem(seir, u0, tspan, β)
sol = StochasticDiffEq.solve(prob,LambaEM(),callback=cb)

plot(sol)

# ### SEIRD Model

S = [:S,:E,:I,:R, :D]
Δ = LVector(
      exp=(LVector(S=1, I=1), LVector(I=1, E=1)),
      inf=(LVector(E=1),      LVector(I=1)),
      rec=(LVector(I=1),      LVector(R=1)),
      die=(LVector(I=1),      LVector(D=1)),
    )
seird = Petri.Model(S, Δ)

Graph(seird)
#-
u0 = LVector(S=990.0, E=10.0, I=0.0, R=0.0, D=0.0)
tspan = (0.0,40.0)
β = LVector(exp=0.9/sum(u0), inf=0.9, rec=0.25, die=0.03)

prob, cb = SDEProblem(seird, u0, tspan, β)
sol = StochasticDiffEq.solve(prob,LambaEM(),callback=cb)

plot(sol)
