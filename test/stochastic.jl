using Petri
import Petri: evaluate
using LabelledArrays
using ModelingToolkit
using MacroTools
import MacroTools: postwalk, striplines
using Test
import GeneralizedGenerated: mk_function


@testset "Stochastic Simulation" begin
    @variables S,E,I,R, β,γ,μ
    @testset "SIR" begin
        u0 = @LArray [100, 1, 0] (:S, :I, :R)
        params = @LArray [0.15, 0.55/101] (:β, :μ)
        sir = Petri.Model([S,I,R], [(S+I, 2*I), (I,R)])
        sir′ = funckit(sir)
        m′ = evaluate(sir′)
        p = Petri.ParamProblem(m′, u0, params, 250)
        soln = Petri.solve(p)
        @test soln.S <= 10
        @test sum(soln) == 101
    end
    @testset "SEIRS" begin
        seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])

        # Δ1 = @show Δ(seirs)
        # Λ1 = @show Λ(seirs)
        m′ = funckit(seirs)

        @show m′
        # @test all(Δ1 .== m′.Δ)
        # @test all(Λ1 .== m′.Λ)

        m′′ = Petri.evaluate(m′)
        u0 = @LArray [100, 1, 0, 0] (:S, :E, :I, :R)
        params = @LArray [0.55/101, 0.15, 0.15, 0.15] (:β, :γ, :μ, :η)
        p = Petri.ParamProblem(m′′, u0, params, 250)
        seirs_soln = Petri.solve(p)
        @test seirs_soln.S >= 10
        @test sum(seirs_soln) == 101
    end
end

function stepfunc(m::Model)
    transitionnames = map(m.Δ) do f
        f.args[1].args[1]
    end
    n = length(m.Λ)
    ratecalc = map(enumerate(m.Λ)) do (i,f)
        body = f.args[2] |> striplines
        if length(body.args) == 1
            body = body.args[1]
        end

        quote λ[$i] = $body end
    end
    actionchain = map(enumerate(m.Δ)) do (i, f)
        body = f.args[2] |> striplines
        if length(body.args) == 1
            body = body.args[1]
        end
        # push!(body.args, :(return state))
        quote if nexti == $i
            $body
        end
        end
    end
    fdef = quote
        (p, state) -> begin
            params = p.param
            λ = zeros(Float64, $n)
            $(ratecalc...)
            nexti = Petri.sample(λ)
            if nexti == nothing
                return state
            end
            $(actionchain...)
            return state
        end
    end
    fdef
end

@testset "Unrolled Stochastic Solve" begin
    @variables S,E,I,R, β,γ,μ
    seirs = Petri.Model([S,E,I,R],[(S+I, E+I), (E,I), (I,R), (R,S)])
    m′ = funckit(seirs)
    u0 = @LArray [100, 1, 0, 0] (:S, :E, :I, :R)
    params = @LArray [0.55/101, 0.15, 0.15, 0.15] (:β, :γ, :μ, :η)
    p = Petri.ParamProblem(m′, u0, params, 250)
    fexp = stepfunc(p.m)
    arglist = [:p,:state]
    body = fexp.args[2]
    # f1 = mk_function(@__MODULE__, arglist, [], body)
    # f = (p, state) -> f1(p, state)
    f = eval(body)
    @show state′ = f(p, p.initial)
    sol = Petri.solve(p, f)
    @show sol
end
