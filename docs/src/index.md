![Petri.jl](assets/full-logo.png)

```@meta
CurrentModule = Petri
```

`Petri.jl` is a Petri net modeling framework for the Julia programming language.

## Goals

`Petri` makes it easy to build complex reaction networks using a simple DSL. This is related to the[DiffeqBiological](https://github.com/JuliaDiffEq/DiffEqBiological.jl "DiffEqBiological") Reaction DSL, but takes a different implementation approach. Instead of building our framework around symbolic algebra and standard chemical notion, we are working off the Applied Category Theory approach to reaction networks [[Baez Pollard, 2017](http://math.ucr.edu/home/baez/RxNet.pdf "baezpollard2017")].

There are operations that are easy to do on the `Petri.Model` like "add a transition from R to S" that require simultaneously changing multiple parts of the algebraic formulation. Applied Category Theory gives a sound theoretical framework for manipulating Petri Nets as a model of chemical reactions. `Petri` is a Julia package primarily intended to investigate how we can operationalize this theory into practical scientific software.

See [AlgebraicPetri.jl](https://github.com/AlgebraicJulia/AlgebraicPetri.jl) for tools that work with Petri net models and manipulating them with higher level APIs based on ACT.
