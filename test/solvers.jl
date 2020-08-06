using Test
using Petri
using LabelledArrays
using OrdinaryDiffEq
using StochasticDiffEq
using DiffEqJump
using Random

Random.seed!(1234);

@testset "Generation of ODE formulas" begin
    sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                  (LVector(I=1),     LVector(R=1))])

    sirf = vectorfield(sir)
    rates = sirf(LVector(S=0.0, I=0.0, R=0.0), LVector(S=100.0,I=1.0,R=0.0), [0.5/101,0.25],0.0)
    @test rates.S ≈ -.495 atol=1e-2
    @test rates.I ≈ .24505 atol=1e-2
    @test rates.R ≈ .25 atol=1e-2
end

@testset "Generation of ODE solutions" begin
    @testset "SIR Solving" begin
        sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                      (LVector(I=1),     LVector(R=1))])
        u0 = LVector(S=990.0,I=10.0,R=0.0)
        p = [0.5/sum(u0), 0.25]
        prob = ODEProblem(sir,u0,(0.0,40.0),p)
        sol = OrdinaryDiffEq.solve(prob,Tsit5())
        @test sum(sol[end]) ≈ 1000 atol=1
        @test sol[end].S ≈ 210 atol=1
        @test sol[end].I ≈ 14.5 atol=1
        @test sol[end].R ≈ 775.5 atol=1
    end
end

@testset "Generation of SDE solutions" begin
    @testset "SIR Solving" begin
        sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                      (LVector(I=1),     LVector(R=1))])
        u0 = LVector(S=990.0,I=10.0,R=0.0)
        p = [0.5/sum(u0), 0.25]
        prob,cb = SDEProblem(sir,u0,(0.0,40.0),p)
        sol = StochasticDiffEq.solve(prob,SRA1(),callback=cb)
        @test sum(sol[end]) ≈ 1000 atol=1
        @test sol[end].S ≈ 201 atol=1
        @test sol[end].I ≈ 13 atol=1
        @test sol[end].R ≈ 786 atol=1
    end
end

@testset "Generation of Jump solutions" begin
    @testset "SIR Solving" begin
        sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                      (LVector(I=1),     LVector(R=1))])
        u0 = LVector(S=990.0,I=10.0,R=0.0)
        p = [0.5/sum(u0), 0.25]
        prob = JumpProblem(sir,u0,(0.0,40.0),p)
        sol = DiffEqJump.solve(prob,SSAStepper())
        @test sum(sol[end]) == 1000
        @test sol[end].S == 263
        @test sol[end].I == 10
        @test sol[end].R == 727
    end
end
