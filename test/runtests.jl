using Test
using Petri
import Petri: toODE

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

#include("stochastic.jl")

#= function test1() =#
#=     S = [:S,:I,:R] =#

#=     Δ = [(Dict(:S=>1,:I=>1), Dict(:I=>2)), =#
#=          (Dict(:I=>1),       Dict(:R=>1)), =#
#=          (Dict(:R=>1),       Dict(:S=>1))] =#

#=     m = Model(S, Δ) =#
#=     p = Problem(m, [100, 1, 0], 150) =#
#= end =#

#= p1 = test1() =#

#= m = p1.m =#
#= map(m.Λ) do λ =#
#=     body, args = @show Petri.funcbody(λ) =#
#= end =#

#= S, I, R = m.S =#

#= Δin  = [S+I, I, R] =#
#= Δout = [2I, R, S] =#

#= Δinm = [1 1 0; =#
#=         0 1 0; =#
#=         0 0 1] =#

#= Δoutm = [0 2 0; =#
#=          0 0 1; =#
#=          1 0 0] =#

#= du = (Δoutm - Δinm)'m.Λ =#


#= answer = map(enumerate(du)) do (i, ex) =#
#=     body, args = Petri.funcbody(ex) =#
#=     body′ = stripnullterms(body) =#
#=     state = m.S[i].op.name =#
#=     :(du.$(state) = $body′) =#
#= end =#
#= f = Petri.funckit(:f, (:du, :state, :p, :t), quote $(answer...)end ) =#

include("ode.jl")
