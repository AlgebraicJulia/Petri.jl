using Test
using Petri
import Petri: toODE
using OrdinaryDiffEq
import OrdinaryDiffEq: solve

@testset "Generation of ODE formulas" begin
    sir = Petri.Model([:S,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>2)),
                                  (Dict(:I=>1),       Dict(:R=>1))])

    sirf = toODE(sir)
    @test sirf(zeros(Float64, 3), [100.0,1.0,0.0], [0.35,0.05],0.0) == [-35.0,34.95,0.05]
end

@testset "Generation of ODE solutions" begin
    @testset "SIR Solving" begin
        sir = Petri.Model([:S,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>2)),
                                      (Dict(:I=>1),       Dict(:R=>1))])
        u0 = [100.0, 1, 0]
        p = [0.35, 0.05]
        f = toODE(sir)
        prob = ODEProblem(f,u0,(0.0,365.0),p)
        sol = solve(prob,Tsit5())
        @test sol[end][1] < 1
        @test sol[end][2] < 1
        @test sol[end][3] > 99
    end

    @testset "SEIR Solving" begin
        seir = Petri.Model([:S,:E,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>1,:E=>1)),
                                          (Dict(:E=>1),       Dict(:I=>1)),
                                          (Dict(:I=>1),       Dict(:R=>1))])
        u0 = [100.0, 1, 0, 0]
        p = [0.35, 0.05, 0.05]
        f = toODE(seir)
        prob = ODEProblem(f,u0,(0.0,365.0),p)
        sol = solve(prob,Tsit5())
        @test sol[end][1] < 1
        @test sol[end][2] < 1
        @test sol[end][3] < 1
        @test sol[end][4] > 99
    end

    @testset "SEIRS Solving" begin
        seirs = Petri.Model([:S,:E,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>1,:E=>1)),
                                           (Dict(:E=>1),       Dict(:I=>1)),
                                           (Dict(:I=>1),       Dict(:R=>1)),
                                           (Dict(:R=>1),       Dict(:S=>1))])
        u0 = [100.0, 1, 0, 0]
        p = [0.3, 0.4, 0.01, 0.01]
        f = toODE(seirs)
        prob = ODEProblem(f,u0,(0.0,60.0),p)
        sol = solve(prob,Tsit5())
        @test sol[end][1] < 1
        @test sol[end][2] < 1
        @test sol[end][3] > 60
        @test sol[end][4] > 30
    end
end
