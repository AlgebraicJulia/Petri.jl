using Test
using Petri
import Petri: fluxes, odefunc
using ModelingToolkit
using LabelledArrays
using OrdinaryDiffEq
import OrdinaryDiffEq: solve

@testset "Generation of ODE formulas" begin
    @variables S,E,I,R, β,γ,μ
    sir = Petri.Model([S,I,R],[(S+I, 2I), (I,R)])
    seir = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R)])
    seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])

    sirf = fluxes(sir)
    @test length(sirf) == 3

    seirf = fluxes(seir)
    @test length(seirf) == 4

    seirsf = fluxes(seirs)
    @test length(seirsf) == 4
end


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
    f(dusir, u0, p, 0.0)
    @show dusir


    @testset "SIR Solving" begin
        u0 = @LArray [100.0, 1, 0] (:S, :I, :R)
        p = @LArray [0.35, 0.05] (:μ, :β)
        fex = odefunc(sir, :sir)
        f = eval(fex)
        prob = ODEProblem(f,u0,(0.0,365.0),p)
        sol = solve(prob,Tsit5())
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
        sol = solve(prob,Tsit5())
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
        sol = solve(prob,Tsit5())
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
