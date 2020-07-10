![Petri.jl](assets/full-logo.png)

```@meta
CurrentModule = Petri
```

`Petri.jl` is a Petri net modeling framework for the Julia programming language.
`Petri` makes it easy to build complex reaction networks using a simple DSL.
Once a model is defined, `Petri.jl` has support to generate ODE solutions and
stochastic simulations using `DifferentialEquations.jl`.


## Goals

 This is related to the
 [DiffeqBiological](https://github.com/JuliaDiffEq/DiffEqBiological.jl) Reaction
 DSL, but takes a different implementation approach. Instead of building our
 framework around symbolic algebra and standard chemical notion, we are working
 off the Applied Category Theory approach to reaction networks [[Baez Pollard, 2017](http://math.ucr.edu/home/baez/RxNet.pdf)].

There are operations that are easy to do on the `Petri.Model` like "add a
transition from R to S" that require simultaneously changing multiple parts of
the algebraic formulation. Applied Category Theory gives a sound theoretical
framework for manipulating Petri Nets as a model in terms of the given domain.
`Petri` is a Julia package primarily intended to investigate how we can
operationalize this theory into practical scientific software.

See [AlgebraicPetri](https://github.com/AlgebraicJulia/AlgebraicPetri.jl) for
tools that work with Petri net models and manipulating them with higher level
APIs based on Applied Category Theory.
