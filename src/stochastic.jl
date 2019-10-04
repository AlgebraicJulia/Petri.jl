function Δ(m::Petri.Model, ctx=:state)
    function updateblock(exp, sym)
        return postwalk(exp) do x
            if typeof(x) == Expr && x.head == :call
                if length(x.args) == 1
                    var = x.args[1]
                    # push!(args, var)
                    e = Expr(sym, :($ctx.$var), 1)
                    # @show "adding guard"
                    if sym == :-=
                        return quote
                            ($ctx.$var > 0 || return nothing ) && $e
                        end
                    end
                    return e
                end
                if length(x.args) >= 1 && x.args[1] == :(*)
                    op = x
                    try
                        # @info "trying"
                        # @show x
                        branch = x.args[3].args[2]
                        # @show branch
                        # @show branch.head
                        # @show branch.args[1]
                        if branch.head == :&&
                            # @info "&& found"
                            op = branch.args[2]
                            # @show op
                            op.args[end] = x.args[2]
                            # @show x
                            return x.args[3]
                        end
                    catch
                        # @info "catching: there was no branch"
                        changevalue = x.args[2]
                        statename = x.args[3].args[1]
                        # e = Expr(sym, statename, changevalue)
                        # return e
                        x.args[3].args[2] = changevalue
                        return x.args[3]
                    end
                end
                if length(x.args) >= 1 && x.args[1] == :(+)
                    # @show x
                    return quote
                        $(x.args[2:end]...)
                    end
                end
            end
            return x
        end
    end

    head(x) = try
        x.head
    catch
        nothing
    end

    function poolconditions(decrements)
        if decrements.head == :block
            steps = postwalk(MacroTools.striplines, decrements).args
            checks = Expr[]
            events = Expr[]
            map(steps) do s
                postwalk(s) do x
                    if head(x) == :&&
                        push!(checks, x.args[1])
                        push!(events, x.args[2])
                    end
                    return x
                end
            end
            decrements = quote $(checks...); $(events...)  end
        end
        return decrements
    end
    δf = map(m.Δ) do δ
        q = quote end
        # input states get decremented
        parents = δ[1]
        children = δ[2]

        exp1 = convert(Expr, parents)
        decrements = updateblock(exp1, :-=) |> poolconditions

        exp2 = convert(Expr, children)
        increments = updateblock(exp2, :+=)

        push!(q.args, decrements)
        push!(q.args, increments)

        sym = gensym("δ")
        @show MacroTools.striplines(q)
        :($sym(state) = $(q) )
    end
end

function Λ(m::Petri.Model{G, S, D, L, B}) where {G, S, D, L, B}
    head(x) = try
        x.head
    catch
        nothing
    end
    function ratecomp(exp, ctx)

        args = Dict{Symbol, Int}()
        postwalk(convert(Expr, exp)) do x
            if typeof(x) == Expr && x.head == :call
                if length(x.args) == 1
                    var = x.args[1]
                    args[var] = 1
                    return :($ctx.$var)
                end
                if x.args[1] == :(*)
                    args[var] = x.args[2]
                end
            end
            return x
        end
        return args
    end

    δf = map(enumerate(m.Δ)) do (i, δ)
        # input states are used to calc the rates
        parents = δ[1]

        # exp1 = convert(Expr, parents)
        ctx = :state
        rates = ratecomp(parents, ctx)
        q = :(*())
        map(collect(keys(rates))) do s
            r = rates[s]
            push!(q.args, :($ctx.$s / $r))
        end
        term = :(params[$i])
        push!(q.args, term)

        sym = gensym("λ")
        @show MacroTools.striplines(q)
        :($sym(state, params) = $(q) )
    end
end

function funckit(m::Petri.Model)
    return Petri.Model(m.g, m.S, Δ(m), Λ(m), missing)
end

function Petri.evaluate(m::Petri.Model{G, Z, D, L, Missing}) where {G, Z, D, L}
    Petri.Model(m.g, m.S, eval.(m.Δ), eval.(m.Λ), missing)
end
