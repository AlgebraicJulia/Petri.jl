using Test
using Petri
using LabelledArrays

@testset "Equality" begin
    sir_1 = Petri.Model([1,2,3],[([1,1], [2]),
                                 ([1],   [1])])
    sir_2 = Petri.Model(1:3,[([1,1], [2]),
                             ([1],   [1])])
    sir_3 = Petri.Model(3,[([1,1], [2]),
                           ([1],   [1])])
    @test typeof(Graph(sir_1)) == Graph
    @test sir_1 == sir_2
    @test sir_1 == sir_3

    @test EmptyPetri(5) == Petri.Model(1:5, [])

    @test EmptyPetri(5) == EmptyPetri(collect(1:5))

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
