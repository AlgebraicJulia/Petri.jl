using Test
using Petri

@testset "Equality" begin
    sir = Petri.Model([:S,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>2)),
                                  (Dict(:I=>1),       Dict(:R=>1))])
    @test sir == sir
    seir = Petri.Model([:S,:E,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>1,:E=>1)),
                                  (Dict(:E=>1),       Dict(:I=>1)),
                                  (Dict(:I=>1),       Dict(:R=>1))])
    x = Petri.Model([:S,:E,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>2)),
                                   (Dict(:I=>1),       Dict(:R=>1))])
    y = Petri.Model([:S,:E,:I,:R],[(Dict(:S=>1,:I=>1), Dict(:I=>1,:E=>1)),
                                   (Dict(:E=>1),       Dict(:I=>1)),
                                   (Dict(:I=>1),       Dict(:R=>1)),
                                   (Dict(:R=>1),       Dict(:S=>1))])
    @test sir != seir
    @test seir != x
    @test seir != y
end

include("stochastic.jl")

include("ode.jl")
