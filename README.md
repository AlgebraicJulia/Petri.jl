# Petri.jl
A Petri net modeling framework for the Julia programming language. 

This package uses the ModelingToolkit framework for building embedded DSLs for mathematical computing. We represent Petri nets with `ModelingToolkit.Operation` expressions and then generate code for simulating these networks.

## Examples

We need to include our dependencies. Modeling Toolkit and Petri are required to build the models. LabelledArrays and OrdinaryDiffEq are required for simulating the network with and ordinary differential equation.

```julia
using ModelingToolkit
using Petri
import Petri: fluxes, odefunc
using LabelledArrays
using OrdinaryDiffEq
import OrdinaryDiffEq: solve
using Plots

N(x) = sum(x)
@variables S,E,I,R, β,γ,μ
```

The SIR model represents the epidemiological dynamics of an infectious disease that causes immunity in its victims. There are three *states:* `Suceptible ,Infected, Recovered`. These states interact through two *transitions*. Infection has the form `S+I -> 2I` where a susceptible person meets an infected person and results in two infected people. The second transition is recovery `I -> R` where an infected person recovers spontaneously.

```julia
# define the structure of the model
sir = Petri.Model([S,I,R],[(S+I, 2I), (I,R)])

# define the initial conditions
u0 = @LArray [100.0, 1, 0] (:S, :I, :R)

# define the parameters of the model, each rate corresponds to a transition
p = @LArray [0.35, 0.05] (:μ, :β)

# generate an expression for the right hand side of the ODE
fex = odefunc(sir, :sir)

# evaluate the expression to create a runnable function
f = eval(fex)

# this is regular OrdinaryDiffEq problem setup
prob = ODEProblem(f,u0,(0.0,365.0),p)
sol = DifferentialEquations.solve(prob,Tsit5())

# visualize the solution
plt = plot(sol, labels=LabelledArrays.symnames(typeof(sol[end]))|> collect)
```

![A solution to the SIR model system](./examples/img/sir_sol.pdf "SIR Solution")


Petri Nets are a simple language for describing reaction networks, you can make increasingly complex diseases. For example the `SEIR` model has an `Exposed` phase where people have the disease, but are not infectious yet.

```julia
seir = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R)])
u0 = @LArray [100.0, 1, 0, 0] (:S, :E, :I, :R)
p = @LArray [0.35, 0.05, 0.05] (:μ, :β, :γ)
fex = odefunc(seir, :seir)
f = eval(fex)
prob = ODEProblem(f,u0,(0.0,365.0),p)
sol = DifferentialEquations.solve(prob,Tsit5())
plt = plot(sol, labels=LabelledArrays.symnames(typeof(sol[end]))|> collect)
```

![A solution to the SEIR model system](./examples/img/seir_sol.pdf "SEIR Solution")

The previous models have transitory behavior, the infection spreads and then terminates as you end up with no infected people in the population. The following `SEIRS` model has a non-trivial steady state, because recovered people lose their immunity and become susceptible again.

```julia
seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])
u0 = @LArray [100.0, 1, 0, 0] (:S, :E, :I, :R)
p = @LArray [0.35, 0.05, 0.07, 0.3] (:μ, :β, :γ, :η)
fex = odefunc(seirs, :seirs)
f = eval(fex)
prob = ODEProblem(f,u0,(0.0,365.0),p)
sol = DifferentialEquations.solve(prob,Tsit5())
plt = plot(sol, labels=LabelledArrays.symnames(typeof(sol[end])) |> collect)
```

![A solution to the SEIRS model system](./examples/img/seirs_sol.pdf "SEIRS Solution")
