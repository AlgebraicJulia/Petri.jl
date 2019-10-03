using Petri
import Petri: evaluate
using LabelledArrays
using ModelingToolkit
using MacroTools
import MacroTools: postwalk
using Test




@testset "Stochastic Simulation" begin
    @variables S,E,I,R, β,γ,μ
    seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])

    Δ1 = @show Δ(seirs)
    Λ1 = @show Λ(seirs)
    m′ = funckit(seirs)

    @show m′
    # @test all(Δ1 .== m′.Δ)
    # @test all(Λ1 .== m′.Λ)

    @show m′′ = Petri.evaluate(m′)
    u0 = @LArray [100, 1, 0, 0] (:S, :E, :I, :R)
    params = @LArray [0.55/101, 0.15, 0.15, 0.15] (:β, :γ, :μ, :η)
    p = Petri.ParamProblem(m′′, u0, params, 250)
    seirs_soln = Petri.solve(p)
    @test seirs_soln.S >= 10
    @test sum(seirs_soln) == 101
    @show seirs_soln
end
