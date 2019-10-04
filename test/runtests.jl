using Test
using Petri
import Petri: stripnullterms, fluxes, odefunc, quotesplat
using ModelingToolkit
using MacroTools
import MacroTools: postwalk

include("stochastic.jl")

mutable struct SIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
end

function test1()
    @variables S, I, R, β, γ, μ
    N = +(S,I,R)
    ϕ = [(S > 0) * (I > 0),
         I > 0,
         R > 0]

    Δ = [(S~S-1, I~I+1),
         (I~I-1, R~R+1),
         (R~R-1, S~S+1)]

    Λ = [β*S*I/N,
         γ*I,
         μ*R]

    m = Model([S,I,R], Δ, Λ, ϕ)
    p = Problem(m, SIRState(100, 1, 0, 0.5, 0.15, 0.05), 150)
end

p1 = test1()

m = p1.m
map(m.Λ) do λ
    body, args = @show Petri.funcbody(λ)
end

S, I, R = m.S

Δin  = [S+I, I, R]
Δout = [2I, R, S]

Δinm = [1 1 0;
        0 1 0;
        0 0 1]

Δoutm = [0 2 0;
         0 0 1;
         1 0 0]

du = (Δoutm - Δinm)'m.Λ


answer = map(enumerate(du)) do (i, ex)
    body, args = Petri.funcbody(ex)
    body′ = stripnullterms(body)
    state = m.S[i].op.name
    :(du.$(state) = $body′)
end
f = Petri.funckit(:f, (:du, :state, :p, :t), quote $(answer...)end )

include("ode.jl")
