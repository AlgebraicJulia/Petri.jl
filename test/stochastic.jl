using Petri
using Test


@testset "Stochastic Simulation" begin
    @testset "SIR" begin
        S  = [:S,:I,:R]
        Δ  = [
              (Dict(:S=>1, :I=>1), Dict(:I=>2)),
              (Dict(:I=>1),        Dict(:R=>1)),
             ]
        sir  = Petri.Model(S, Δ)
        p = Petri.Problem(sir, Dict(:S=>100, :I=>1,:R=>0), 150)
        soln = Petri.solve(p)
        @test sum(values(soln)) == 101
    end
end
