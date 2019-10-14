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


![The SIR model system shown as a Petri net with ODE formulas](/doc/img/sir_petri+ode.png?raw=true "SIR Model")

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

![A solution to the SIR model system](/examples/img/sir_sol.png?raw=true "SIR Solution")


Petri Nets are a simple language for describing reaction networks, you can make increasingly complex diseases. For example the `SEIR` model has an `Exposed` phase where people have the disease, but are not infectious yet.

![The SEIR model system shown as a Petri net](/doc/img/seir.png?raw=true "SEIR Model")

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

![A solution to the SEIR model system](/examples/img/seir_sol.png?raw=true "SEIR Solution")

The previous models have transitory behavior, the infection spreads and then terminates as you end up with no infected people in the population. The following `SEIRS` model has a non-trivial steady state, because recovered people lose their immunity and become susceptible again.

![The SEIRS model system shown as a Petri net](/doc/img/seirs.png?raw=true "SEIR Model")

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

![A solution to the SEIRS model system](/examples/img/seirs_sol.png?raw=true "SEIRS Solution")

## Goals

`Petri` makes it easy to build complex reaction networks using a simple DSL. This is related to the[DiffeqBiological](https://github.com/JuliaDiffEq/DiffEqBiological.jl "DiffEqBiological") Reaction DSL, but takes a different implementation approach. Instead of building our framework around symbolic algebra and standard chemical notion, we are working off the Applied Category Theory approach to reaction networks [[Baez Pollard, 2017](http://math.ucr.edu/home/baez/RxNet.pdf "baezpollard2017")].

There are operations that are easy to do on the `Petri.Model` like "add a transition from R to S" that require simultaneously changing multiple parts of the algebraic formulation. Applied Category Theory gives a sound theoretical framework for manipulating Petri Nets as a model of chemical reactions. `Petri` is a Julia package primarily intended to investigate how we can operationalize this theory into practical scientific software.

See [SemanticModels.ModelTools](https://github.com/jpfairbanks/SemanticModels.jl/blob/master/src/modeltools/PetriModels.jl "PetriModel") for tools that work with Petri net models and manipulating them with higher level APIs based on ACT.

## Visualization

You can draw `Petri.Model` objects with Graphviz using a bipartite graph representation. See the `Petri.Graph(m::Petri.Model)` function.

## Open Petri Nets

An open Petri Net can be used to model a system that interacts with the outside world. For example a chemical reaction that has inflows and outflows of concentration for certain species, can be represented as an `OpenModel` where the inflows occur on the `dom` and the outflows on the `codom` of the `OpenModel`. This allows you to represent interacting systems from an algebraic perspective. These systems an be combined with composition and combination operators to make complex models out of simple building blocks.
