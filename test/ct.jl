using Test
using SemanticModels.ModelTools.PetriModels

# SIR  <- IR  -> SEIR
#  |       |      |
#  v       v      v
# SIRS <- IRS -> SEIRS

# +
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

rule = PetriModels.Span(sir, ir, seir)
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


@show "SIR"
Δ(l.model, :state)
# @show "IR"
# funckit(c, :state)
@show "SEIR"
# funckit(r, :state)

@show "SIRS"
# funckit(l′, :state)
# @show "IRS"
# funckit(c′, :state)
@show "SEIRS"
# funckit(seirs, :state)

exprs = Δ(sirs.model, :state)
m = Petri.Model([S, I, R], exprs, [
    quote
    λ_2(state) = state.γ * state.I
    end,
    quote
    λ_1(state) = state.β * state.S * state.I / +(state.S, state.I, state.R)
    end,
    quote
    λ_3(state) = state.μ * state.R
    end],
                [
                    quote b_2(state) = state.I > 0 end,
                    quote b_1(state) = state.S > 0 && state.I > 0 end,
                    quote b_3(state) = state.R > 0 end]
                )

# +
mutable struct SIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
end

mutable struct ParamSIR{T, P}
    S::T
    I::T
    R::T
    params::P
end
# -

p = Petri.Problem(eval(m), SIRState(100, 1, 0, 0.5, 0.15, 0.05), 150)
#@show Petri.solve(p)

# @show Petri.funckit(Petri.Problem(l, missing, 10), :state)
function test_1()
    no_transitions = Tuple{Operation, Operation}[]
    @variables A, B, C, D
    states = [A, B, C, D]
    l = model(PetriModel, Petri.Model(states, [(A, B)]))
    c = model(PetriModel, Petri.Model(states, no_transitions))
    r = model(PetriModel, Petri.Model(states, [(A, B + C)]))
    rule = PetriModels.Span(l, c, r)
    c′ = model(PetriModel, Petri.Model(states, [(B, A)]))
    r′ = PetriModels.solve(PetriModels.DPOProblem(rule, c′))
    @test r′.model.Δ == [(A, B+C), (B, A)]

    l′ = PetriModels.pushout(l, c′)
    @test l′.model.Δ == [(A, B), (B, A)]
    @test PetriModels.dropdown(l,c,l′).model.Δ == [(B, A)]
end

function test_2()
    no_transitions = Tuple{Operation, Operation}[]
    @variables A, B, C, D
    states = [A, B, C, D]
    l = model(PetriModel, Petri.Model(states, [(A, B), (B,C)]))
    c = model(PetriModel, Petri.Model(states, no_transitions))
    r = model(PetriModel, Petri.Model(states, [(A, C)]))
    rule = PetriModels.Span(l, c, r)
    c′ = model(PetriModel, Petri.Model(states, [(C, D)]))
    r′ = PetriModels.solve(PetriModels.DPOProblem(rule, c′))
    @test r′.model.Δ == [(A, C), (C, D)]

    l′ = PetriModels.pushout(l, c′)
    @test l′.model.Δ == [(A, B), (B, C), (C, D)]
    @test PetriModels.dropdown(l,c,l′).model.Δ == [(C, D)]
    @test PetriModels.pushout(rule.r, c′).model.Δ == [(A, C), (C, D)]
end
test_1()
test_2()

exprs2 = Δ(Petri.Model([S,I,R], [(2S+I, 3I)]))


# @code_native m′.Δ[1](ParamSIR(100, 1, 0, [ 0.15, 0.55/101, 0.15, 0.1 ]))
