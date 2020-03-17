using Test
using SemanticModels.ModelTools.PetriModels

# SIR  <- IR  -> SEIR
#  |       |      |
#  v       v      v
# SIRS <- IRS -> SEIRS

# +
using Petri
using ModelingToolkit
import ModelingToolkit: Constant, Variable
using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz
import Catlab.Graphics.Graphviz: run_graphviz
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a
S, E, I, R, D= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)

inf  = to_wiring_diagram(Hom(:infection, S ⊗ I, I⊗I))
expo = to_wiring_diagram(Hom(:exposure, S⊗I, E⊗I))
rec  = to_wiring_diagram(Hom(:recovery, I,   R))
wan  = to_wiring_diagram(Hom(:waning,   R,   S))

sir_wire  = inf ⊚ (rec ⊗ rec)

sir = model(PetriModel, sir_wire)

dump(sir)

# +
@variables S, E, I, R

dump(S)
# -

sir = model(PetriModel, Petri.Model([S, I, R],
                 [(I, R), (S+I, 2I)],
                 ))

ir = model(PetriModel, Petri.Model([S, I, R],
                 [(I, R)]))

seir = model(PetriModel, Petri.Model([S, I, R],
                 [(I, R), (S+I, I+E), (E, I)],
                 ))

# +
irs = model(PetriModel, Petri.Model([S, I, R],
                 [(I, R), (R, S)],
                 ))

dump(sir)
dump(irs)
# -

sirs = model(PetriModel, Petri.Model([S, I, R],
                 [(I, R), (S+I, 2*I), (R, S)],
                 ))

rule = PetriModels.PetriSpan(sir, ir, seir)
sirs′ = PetriModels.pushout(irs, sir)
@test sirs′.model.Δ == sirs.model.Δ
seirs = PetriModels.solve(PetriModels.DPOProblem(rule, irs))
@test all(Set(seirs.model.Δ) .== Set([(S+I, I+E),
                             (E, I),
                             (I, R),
                             (R, S)]))
l = sir
c = ir
r = seir
c′ = irs

l′ = PetriModels.pushout(l, c′)
@test l′.model.Δ == sirs.model.Δ
@test PetriModels.dropdown(l,c,l′).model.Δ == c′.model.Δ
@test PetriModels.pushout(r, c′).model.Δ == seirs.model.Δ
