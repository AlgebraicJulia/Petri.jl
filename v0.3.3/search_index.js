var documenterSearchIndex = {"docs":
[{"location":"api/#Library-Reference","page":"Library Reference","title":"Library Reference","text":"","category":"section"},{"location":"api/","page":"Library Reference","title":"Library Reference","text":"Modules = [Petri]","category":"page"},{"location":"api/#Petri.Petri","page":"Library Reference","title":"Petri.Petri","text":"Petri\n\nProvides a modeling framework for representing and solving stochastic petri nets\n\n\n\n\n\n","category":"module"},{"location":"api/#Catlab.Graphics.Graphviz.Graph-Tuple{Model}","page":"Library Reference","title":"Catlab.Graphics.Graphviz.Graph","text":"Graph(model::Model)\n\nconvert a Model into a GraphViz Graph. Transition are green boxes and states are blue circles. Arrows go from the input states to the output states for each transition.\n\n\n\n\n\n","category":"method"},{"location":"api/#Petri.Model","page":"Library Reference","title":"Petri.Model","text":"Model{S,D}\n\nStructure for representing the petri net model\n\nrepresented by states and transition functions\n\n\n\n\n\n","category":"type"},{"location":"api/#Petri.Problem","page":"Library Reference","title":"Petri.Problem","text":"Problem{M<:Model, S, N}\n\nStructure for representing a petri net problem\n\nrepresented by a petri net model, initial state, and number of steps\n\n\n\n\n\n","category":"type"},{"location":"api/#Petri.NullPetri-Tuple{Int64}","page":"Library Reference","title":"Petri.NullPetri","text":"NullPetri(n::Int)\n\ncreate a Petri net of n states with no transitions\n\n\n\n\n\n","category":"method"},{"location":"api/#Petri.solve-Tuple{Petri.AbstractProblem}","page":"Library Reference","title":"Petri.solve","text":"solve(p::Problem)\n\nEvaluate petri net problem and return the final state\n\n\n\n\n\n","category":"method"},{"location":"api/#Petri.toODE-Tuple{Model}","page":"Library Reference","title":"Petri.toODE","text":"toODE(m::Model)\n\nConvert a petri model into a differential equation function that can be passed into DifferentialEquation.jl or OrdinaryDiffEq.jl solvers\n\n\n\n\n\n","category":"method"},{"location":"usage/#Basic-Usage","page":"Basic Usage","title":"Basic Usage","text":"","category":"section"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"We need to include our dependencies. Petri is the only requirement to build the models. OrdinaryDiffEq is required for simulating the network with and ordinary differential equation. Plots can be used to plot the solutions generated by OrdinaryDiffEq. LabelledArrays can be used to make things more readable, but is not necessary. Lastly, Catlab is required for visualizing the models as graphviz diagrams.","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"using Petri\nusing LabelledArrays\nusing OrdinaryDiffEq\nusing Plots\nusing Catlab.Graphics.Graphiz\nimport Catlab.Graphics.Graphviz: Graph","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"The SIR model represents the epidemiological dynamics of an infectious disease that causes immunity in its victims. There are three states: Suceptible ,Infected, Recovered. These states interact through two transitions. Infection has the form S+I -> 2I where a susceptible person meets an infected person and results in two infected people. The second transition is recovery I -> R where an infected person recovers spontaneously.","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"(Image: The SIR model system shown as a Petri net with ODE formulas)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"# define the structure of the model\nsir = Petri.Model([:S,:I,:R],LVector(\n                                inf=(LVector(S=1,I=1), LVector(I=2)),\n                                rec=(LVector(I=1),     LVector(R=1))))\n\n# define the initial conditions\nu0 = LVector(S=100.0, I=1, R=0)\n\n# define the parameters of the model, each rate corresponds to a transition\np = LVector(inf=0.05, rec=0.35)\n\n# evaluate the expression to create a runnable function\nf = toODE(sir)\n\n# this is regular OrdinaryDiffEq problem setup\nprob = ODEProblem(f,u0,(0.0,365.0),p)\nsol = OrdinaryDiffEq.solve(prob,Tsit5())\n\n# generate a graphviz visualization of the model\ngraph = Graph(sir)\n\n# visualize the solution\nplt = plot(sol)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"(Image: A solution to the SIR model system)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"Petri Nets are a simple language for describing reaction networks, you can make increasingly complex diseases. For example the SEIR model has an Exposed phase where people have the disease, but are not infectious yet.","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"(Image: The SEIR model system shown as a Petri net)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"seir = Petri.Model([:S,:E,:I,:R],LVector(\n                                    exp=(LVector(S=1,I=1), LVector(I=1,E=1)),\n                                    inf=(LVector(E=1),     LVector(I=1)),\n                                    rec=(LVector(I=1),     LVector(R=1))))\nu0 = LVector(S=100.0, E=1, I=0, R=0)\np = (exp=0.35, inf=0.05, rec=0.05)\nf = toODE(seir)\nprob = ODEProblem(f,u0,(0.0,365.0),p)\nsol = OrdinaryDiffEq.solve(prob,Tsit5())\nplt = plot(sol)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"(Image: A solution to the SEIR model system)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"The previous models have transitory behavior, the infection spreads and then terminates as you end up with no infected people in the population. The following SEIRS model has a non-trivial steady state, because recovered people lose their immunity and become susceptible again.","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"(Image: The SEIRS model system shown as a Petri net)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"seirs = Petri.Model([:S,:E,:I,:R],LVector(\n                                    exp=(LVector(S=1,I=1), LVector(I=1,E=1)),\n                                    inf=(LVector(E=1),     LVector(I=1)),\n                                    rec=(LVector(I=1),     LVector(R=1)),\n                                    deg=(LVector(R=1),     LVector(S=1))))\nu0 = LVector(S=100.0, E=1, I=0, R=0)\np = LVector(exp=0.35, inf=0.05, rec=0.07, deg=0.3)\nf = toODE(seirs)\nprob = ODEProblem(f,u0,(0.0,365.0),p)\nsol = OrdinaryDiffEq.solve(prob,Tsit5())\nplt = plot(sol)","category":"page"},{"location":"usage/","page":"Basic Usage","title":"Basic Usage","text":"(Image: A solution to the SEIRS model system)","category":"page"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"(Image: Petri.jl)","category":"page"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"CurrentModule = Petri","category":"page"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"Petri.jl is a Petri net modeling framework for the Julia programming language.","category":"page"},{"location":"#Goals","page":"Petri.jl","title":"Goals","text":"","category":"section"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"Petri makes it easy to build complex reaction networks using a simple DSL. This is related to theDiffeqBiological Reaction DSL, but takes a different implementation approach. Instead of building our framework around symbolic algebra and standard chemical notion, we are working off the Applied Category Theory approach to reaction networks [Baez Pollard, 2017].","category":"page"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"There are operations that are easy to do on the Petri.Model like \"add a transition from R to S\" that require simultaneously changing multiple parts of the algebraic formulation. Applied Category Theory gives a sound theoretical framework for manipulating Petri Nets as a model of chemical reactions. Petri is a Julia package primarily intended to investigate how we can operationalize this theory into practical scientific software.","category":"page"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"See SemanticModels for tools that work with Petri net models and manipulating them with higher level APIs based on ACT.","category":"page"},{"location":"#Table-of-Contents","page":"Petri.jl","title":"Table of Contents","text":"","category":"section"},{"location":"","page":"Petri.jl","title":"Petri.jl","text":"Pages = [\n    \"usage.md\",\n    \"api.md\"\n    ]\nDepth = 2","category":"page"}]
}
