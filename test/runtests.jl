using Test
using Petri
import Petri: stripnullterms, fluxes, odefunc, quotesplat
using ModelingToolkit
using MacroTools
import MacroTools: postwalk

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
    @show λ
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

@testset "Generation of ODE formulas" begin
    @variables S,E,I,R, β,γ,μ
    sir = Petri.Model([S,I,R],[(S+I, 2I), (I,R)])
    seir = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R)])
    seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])

    @show sirf = fluxes(sir)
    @test length(sirf) == 3

    @show seirf = fluxes(seir)
    @test length(seirf) == 4

    @show seirsf = fluxes(seirs)
    @test length(seirsf) == 4
end

using LabelledArrays
using DifferentialEquations

N(x) = sum(x)

@testset "Generation of ODE solutions" begin
    @variables S,E,I,R, β,γ,μ
    sir = Petri.Model([S,I,R],[(S+I, 2I), (I,R)])
    seir = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R)])
    seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])
    fex = odefunc(sir,:sir)
    f = eval(fex)
    u0 = @LArray [100.0, 1, 0] (:S, :I, :R)
    dusir = @LArray [0.0, 0.0, 0.0] (:S, :I, :R)
    p = @LArray [0.35, 0.05] (:μ, :β)
    @show f(dusir, u0, p, 0.0)
    @show dusir


    @testset "SIR Solving" begin
        u0 = @LArray [100.0, 1, 0] (:S, :I, :R)
        p = @LArray [0.35, 0.05] (:μ, :β)
        fex = odefunc(sir, :sir)
        f = eval(fex)
        prob = ODEProblem(f,u0,(0.0,365.0),p)
        sol = DifferentialEquations.solve(prob,Tsit5())
        @test sol[end].S < 1
        @test sol[end].I < 1
        @test sol[end].R > 99
    end

    @testset "SEIR Solving" begin
        u0 = @LArray [100.0, 1, 0, 0] (:S, :E, :I, :R)
        p = @LArray [0.35, 0.05, 0.05] (:μ, :β, :γ)
        fex = odefunc(seir, :seir)
        f = eval(fex)
        prob = ODEProblem(f,u0,(0.0,365.0),p)
        sol = DifferentialEquations.solve(prob,Tsit5())
        @test sol[end].S < 1
        @test sol[end].E < 1
        @test sol[end].I < 1
        @test sol[end].R > 99
    end

    @testset "SEIRS Solving" begin
        u0 = @LArray [100.0, 1, 0, 0] (:S, :E, :I, :R)
        p = @LArray [0.35, 0.05, 0.07, 0.3] (:μ, :β, :γ, :η)
        fex = odefunc(seirs, :seirs)
        f = eval(fex)
        prob = ODEProblem(f,u0,(0.0,365.0),p)
        sol = DifferentialEquations.solve(prob,Tsit5())
        @test sol[end].S > 5
        @test sol[end].E > 5
        @test sol[end].I > 5
        @test sol[end].R > 5
        @test sol[end].S < 95
        @test sol[end].E < 95
        @test sol[end].I < 95
        @test sol[end].R < 95
    end
end
