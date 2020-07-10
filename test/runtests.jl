using Test
using Petri
using LabelledArrays

@testset "Equality" begin
    sir = Petri.Model([:S,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                  (LVector(I=1),     LVector(R=1))])
    @test sir == sir
    seir = Petri.Model([:S,:E,:I,:R],[(LVector(S=1,I=1), LVector(I=1,E=1)),
                                      (LVector(E=1),     LVector(I=1)),
                                      (LVector(I=1),     LVector(R=1))])
    x = Petri.Model([:S,:E,:I,:R],[(LVector(S=1,I=1), LVector(I=2)),
                                   (LVector(I=1),     LVector(R=1))])
    y = Petri.Model([:S,:E,:I,:R],[(LVector(S=1,I=1), LVector(I=1,E=1)),
                                   (LVector(E=1),     LVector(I=1)),
                                   (LVector(I=1),     LVector(R=1)),
                                   (LVector(R=1),     LVector(S=1))])
    @test sir != seir
    @test seir != x
    @test seir != y
end

include("solvers.jl")
