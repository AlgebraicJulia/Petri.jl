

N(x) = sum(x)

function fluxes(model)
    terms = map(enumerate(model.Δ)) do (i, δ)
        inn, out = δ
        term = inn
        if term.op == +
            term = prod(inn.args)
        end
        body, args = Petri.funcbody(term)
        t = :(param[$i]*$body)
        deg = length(t.args[3].args)-2
        t = :($t / N(state)^$(deg))
        t = simplify(t)
        outterms = out.op == ( + ) ? out.args : [out]
        changes = map(outterms) do o
            p = o.op == ( * ) ? (o.args[2].op,o.args[1]) : (o.op, 1)
            var, coeff = p[1], coeffvalue(p[2])
            var=>:($coeff * $t)
        end
        innterms = inn.op == ( + ) ? inn.args : [inn]
        decreases = map(innterms) do o
            p = o.op == ( * ) ? (o.args[2].op,o.args[1]) : (o.op, 1)
            var, coeff = p[1], coeffvalue(p[2])
            var=>:((-1/$coeff) * $t)
        end
        return union(changes, decreases)
    end |> flatten |> s->collect(Dict(), s)
    [:(du.$(Symbol(k)) = +($(v...))) for (k,v) in terms]
end

odefunc(m, prefix::Symbol) = funckit(gensym(prefix),
                                     (:du, :state, :param, :t),
                                     quotesplat(fluxes(m)))

function mk_function(m::Model)
    fex = odefunc(m, :f)
    arglist = fex.args[2].args[1].args[2:end]
    body = fex.args[2].args[2].args[2]
    f = mk_function(@__MODULE__, arglist, [], body)
    g = (du, u, p, t) -> f(du,  u, p, t)
    return g
end
