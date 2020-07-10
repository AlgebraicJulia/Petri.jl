using Test
using Petri
using LabelledArrays
using OrdinaryDiffEq
using StochasticDiffEq

@testset "Generation of ODE formulas" begin
    sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                  (LVector(I=1),     LVector(R=1))])

    sirf = vectorfields(sir)
    @test sirf(LVector(S=0.0, I=0.0, R=0.0), LVector(S=100.0,I=1.0,R=0.0), [0.35,0.05],0.0) == LVector(S=-35.0,I=34.95,R=0.05)
end

@testset "Generation of ODE solutions" begin
    @testset "SIR Solving" begin
        sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                      (LVector(I=1),     LVector(R=1))])
        u0 = LVector(S=100.0,I=1.0,R=0.0)
        p = [0.35, 0.05]
        prob = ODEProblem(sir,u0,(0.0,365.0),p)
        sol = OrdinaryDiffEq.solve(prob,Tsit5())
        @test sol[end].S < 1
        @test sol[end].I < 1
        @test sol[end].R > 99
    end

    @testset "SEIR Solving" begin
        seir = Petri.Model([:S,:E,:I,:R],LVector(exp=(LVector(S=1,I=1), LVector(I=1,E=1)),
                                                 inf=(LVector(E=1),       LVector(I=1)),
                                                 rec=(LVector(I=1),       LVector(R=1))))
        u0 = LVector(S=100.0, E=1.0, I=0.0, R=0.0)
        p = LVector(exp=0.35, inf=0.05, rec=0.05)
        prob = ODEProblem(seir,u0,(0.0,365.0),p)
        sol = OrdinaryDiffEq.solve(prob,Tsit5())
        @test sol[end].S < 1
        @test sol[end].E < 1
        @test sol[end].I < 1
        @test sol[end].R > 99
    end

    @testset "SEIRS Solving" begin
        seirs = Petri.Model([:S,:E,:I,:R],LVector(exp=(LVector(S=1,I=1), LVector(I=1,E=1)),
                                                  inf=(LVector(E=1),     LVector(I=1)),
                                                  rec=(LVector(I=1),     LVector(R=1)),
                                                  deg=(LVector(R=1),     LVector(S=1))))
        u0 = LVector(S=100.0, E=1.0, I=0.0, R=0.0)
        p = LVector(exp=0.3, inf=0.4, rec=0.01, deg=0.01)
        prob = ODEProblem(seirs,u0,(0.0,60.0),p)
        sol = OrdinaryDiffEq.solve(prob,Tsit5())
        @test sol[end].S < 1
        @test sol[end].E < 1
        @test sol[end].I > 60
        @test sol[end].R > 30
    end
end

@testset "Generation of SDE solutions" begin
    @testset "SIR Solving" begin
        sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                      (LVector(I=1),     LVector(R=1))])
        u0 = LVector(S=100.0,I=1.0,R=0.0)
        p = [0.35, 0.05]
        prob,cb = SDEProblem(sir,u0,(0.0,365.0),p)
        sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)
        @test sol[end].S < 1.1
        @test sol[end].I < 1.1
        @test sol[end].R > 98.9
    end

    @testset "SEIR Solving" begin
        seir = Petri.Model([:S,:E,:I,:R],LVector(exp=(LVector(S=1,I=1), LVector(I=1,E=1)),
                                                 inf=(LVector(E=1),       LVector(I=1)),
                                                 rec=(LVector(I=1),       LVector(R=1))))
        u0 = LVector(S=100.0, E=1.0, I=0.0, R=0.0)
        p = LVector(exp=0.35, inf=0.05, rec=0.05)
        prob,cb = SDEProblem(seir,u0,(0.0,365.0),p)
        sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)
        @test sol[end].S < 1.1
        @test sol[end].E < 1.1
        @test sol[end].I < 1.1
        @test sol[end].R > 98.9
    end

    @testset "SEIRS Solving" begin
        seirs = Petri.Model([:S,:E,:I,:R],LVector(exp=(LVector(S=1,I=1), LVector(I=1,E=1)),
                                                  inf=(LVector(E=1),     LVector(I=1)),
                                                  rec=(LVector(I=1),     LVector(R=1)),
                                                  deg=(LVector(R=1),     LVector(S=1))))
        u0 = LVector(S=100.0, E=1.0, I=0.0, R=0.0)
        p = LVector(exp=0.3, inf=0.4, rec=0.01, deg=0.01)
        prob,cb = SDEProblem(seirs,u0,(0.0,60.0),p)
        sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)
        @test sol[end].S < 1.1
        @test sol[end].E < 1.1
        @test sol[end].I > 59.9
        @test sol[end].R > 29.9
    end
end
